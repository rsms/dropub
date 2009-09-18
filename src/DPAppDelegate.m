#import "DPAppDelegate.h"
#import "DPSupervisor.h"

/*@interface NSStatusBar (Unofficial)
-(id)_statusItemWithLength:(float)f withPriority:(int)d;
@end*/

@implementation DPAppDelegate

@synthesize dirs;

- (id)init {
	self = [super init];
	
	dirs = [[NSUserDefaults standardUserDefaults] objectForKey:@"directories"];
	if (!dirs || ![dirs respondsToSelector:@selector(objectAtIndex:)]) {
		dirs = [NSMutableArray array];
	}
	else {
		dirs = [dirs mutableCopy];
		[dirConfArrayController setSelectsInsertedObjects:YES];
	}
	_dirsPrevState = dirs;
	_dirConfPrevState = [NSMutableDictionary dictionary];
	supervisors = [NSMutableDictionary dictionary];
	dirFields = [NSArray arrayWithObjects:
				 @"icon", @"localpath", @"remoteHost", @"remotePath", @"state", nil];
	
	[self addObserver:self forKeyPath:@"dirs" options:0 context:nil];
	
	return self;
}

- (void)awakeFromNib {
	// For increased priority:
	// _statusItemWithLength:0 withPriority:INT_MAX
	if (statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:0]) {
		[statusItem setLength:0];
		// Setup the status item here.
		[statusItem setTitle:@"0"];
		[statusItem setImage:[NSImage imageNamed:@"status-item-standby.png"]];
		[statusItem setAlternateImage:[NSImage imageNamed:@"status-item-selected.png"]];
		[statusItem setHighlightMode:YES];
		[statusItem setMenu:statusItemMenu]; 
		// todo [statusItem setMenu:NSMenu]
		[statusItem setLength:NSVariableStatusItemLength];
	}
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[[NSUserDefaults standardUserDefaults] setObject:dirs forKey:@"directories"];
}

- (IBAction)orderFrontDirConfigWindow:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
	[mainWindow makeKeyAndOrderFront:sender];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSUInteger i, index;
	NSDictionary *dirConf, *oldDirConf;
	NSString *pk;
	
	NSLog(@"observed%@[%@]: %@", object, keyPath, change);
	int kind = [[change objectForKey:NSKeyValueChangeKindKey] intValue];
	
	if (object == self && [keyPath compare:@"dirs"] == 0) {
		NSIndexSet *indices = [change objectForKey:NSKeyValueChangeIndexesKey];
		if (kind == NSKeyValueChangeInsertion || kind == NSKeyValueChangeReplacement) {
			//NSLog(@"dir(s) was added at indices %@", indices);
			for (NSString *fieldName in dirFields) {
				[dirs addObserver:self toObjectsAtIndexes:indices forKeyPath:fieldName options:0 context:nil];
			}
		}
		
		i = 0;
		
		if (kind == NSKeyValueChangeInsertion) {
			do {
				if ((index = [indices indexGreaterThanOrEqualToIndex:i]) == NSNotFound)
					break;
				[self dirConfigWasCreated:[dirs objectAtIndex:index]];
			} while(i++);
		}
		else if (kind == NSKeyValueChangeReplacement) {
			do {
				if ((index = [indices indexGreaterThanOrEqualToIndex:i]) == NSNotFound)
					break;
				dirConf = [dirs objectAtIndex:index];
				oldDirConf = [_dirsPrevState objectAtIndex:index];
				pk = [dirConf objectForKey:@"localpath"];
				[_dirConfPrevState setObject:dirConf forKey:pk];
				[self dirConfigWasModified:dirConf previous:oldDirConf];
			} while(i++);
		}
		else if (kind == NSKeyValueChangeRemoval) {
			do {
				if ((index = [indices indexGreaterThanOrEqualToIndex:i]) == NSNotFound)
					break;
				if ([_dirsPrevState count] > index) {
					dirConf = [_dirsPrevState objectAtIndex:index];
					pk = [dirConf objectForKey:@"localpath"];
					if ([_dirConfPrevState objectForKey:pk])
						[_dirConfPrevState removeObjectForKey:pk];
				}
				else {
					// todo find a way to do this nicely
					dirConf = [NSDictionary dictionary];
				}
				[self dirConfigWasDeleted:dirConf];
				[dirConfTableView reloadData];
				[dirConfTableView setNeedsDisplay:YES];
			} while(i++);
		}
		else {
			NSLog(@"unhandled observation event kind: %u", kind);
		}
		_dirsPrevState = [dirs copy];
		[[NSUserDefaults standardUserDefaults] setObject:dirs forKey:@"directories"];
		//  NSKeyValueChangeRemoval = 3, NSKeyValueChangeReplacement = 4
	}
	else if ([object respondsToSelector:@selector(objectForKey:)]) {
		pk = [object objectForKey:@"localpath"];
		if (pk) {
			oldDirConf = [_dirConfPrevState objectForKey:pk];
			[_dirConfPrevState setObject:[object copy] forKey:pk];
		}
		else {
			// todo find a way to do this nicely
			oldDirConf = [NSDictionary dictionary];
		}
		[self dirConfigWasModified:object previous:oldDirConf];
	}
}

- (void)dirConfigWasCreated:(NSDictionary *)conf {
	NSLog(@"dirConfigWasCreated %@", conf);
	[self startSupervising:conf];
}

- (void)dirConfigWasModified:(NSDictionary *)newConf previous:(NSDictionary *)oldConf {
	// Note: oldDirConf MIGHT BE NULL if no "localpath" is set (it's the primary key)
	NSLog(@"dirConfigWasModified %@ previous: %@", newConf, oldConf);
	if (newConf && oldConf && [[newConf objectForKey:@"localpath"] compare:[oldConf objectForKey:@"localpath"]] != 0) {
		[self stopSupervising:oldConf];
		[self startSupervising:newConf];
	}
	else if (newConf && !oldConf) {
		[self startSupervising:newConf];
	}
}

- (void)dirConfigWasDeleted:(NSDictionary *)conf {
	NSLog(@"dirConfigWasDeleted %@", conf);
	[self stopSupervising:conf];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// setup supervisors for saved dirconfs
	for (NSDictionary *dirConf in dirs) {
		[self startSupervising:dirConf];
	}
	
	// first launch or no dirconfs? -- show config window
	if ([dirs count] == 0) {
		[self orderFrontDirConfigWindow:self];
	}
	
	NSLog(@"dirs = %@", dirs);
}

- (void)stopSupervising:(NSDictionary *)conf {
	DPSupervisor *sv;
	sv = [supervisors objectForKey:[conf objectForKey:@"localpath"]];
	if (sv)
		[sv cancel];
	else
		NSLog(@"warn: stopSupervising: no supervisor found for conf %@", conf);
}

- (DPSupervisor *)startSupervising:(NSDictionary *)dirConf {
	NSError *error = nil;
	NSString *qdir;
	if (!(qdir = [dirConf objectForKey:@"localpath"]))
		return nil;
	qdir = [qdir stringByStandardizingPath];
	if (![[NSFileManager defaultManager] fileExistsAtPath:qdir] && ![[NSFileManager defaultManager] createDirectoryAtPath:qdir withIntermediateDirectories:YES attributes:nil error:&error])
	{
		ALERT_MODAL(@"Failed to create directory", @"Error: %@", error);
		[NSApp terminate:self];
	}
	DPSupervisor *sv = [[DPSupervisor alloc] initWithApp:self conf:dirConf];
	sv.delegate = self;
	[supervisors setObject:sv forKey:[dirConf objectForKey:@"localpath"]];
	[g_opq addOperation:sv];
	return sv;
}

- (void)supervisedFilesInTransitDidChange:(DPSupervisor *)supervisor {
	NSUInteger count = [supervisor.filesInTransit count];
	if (count)
		[statusItem setImage:[NSImage imageNamed:@"status-item-sending.png"]];
	else
		[statusItem setImage:[NSImage imageNamed:@"status-item-standby.png"]];
	[statusItem setTitle:[NSString stringWithFormat:@"%u", count]];
}

- (void)supervisorDidExit:(DPSupervisor *)sv {
	NSString *pk = [sv.conf objectForKey:@"localpath"];
	if ([supervisors objectForKey:pk])
		[supervisors removeObjectForKey:pk];
}


@end
