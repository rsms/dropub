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
	_dirsPrevState = [dirs copy];
	_dirConfPrevState = [NSMutableDictionary dictionary];
	supervisors = [NSMutableDictionary dictionary];
	dirFields = [NSArray arrayWithObjects:
				 @"icon", @"localpath", @"remoteHost", @"remotePath", @"disabled", nil];
	
	// KVO
	[self addObserver:self forKeyPath:@"dirs" options:0 context:nil];
	for (NSMutableDictionary *conf in dirs) {
		for (NSString *fieldName in dirFields) {
			[conf addObserver:self forKeyPath:fieldName options:0 context:nil];
		}
		[conf updateIconOfDroPubConf];
	}
	
	return self;
}

- (void)awakeFromNib {
	// For increased priority:
	// _statusItemWithLength:0 withPriority:INT_MAX
	if (statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:0]) {
		[statusItem setLength:0];
		// Setup the status item here.
		//[statusItem setTitle:@"0"];
		[statusItem setImage:[NSImage imageNamed:@"status-item-standby.png"]];
		[statusItem setAlternateImage:[NSImage imageNamed:@"status-item-selected.png"]];
		[statusItem setHighlightMode:YES];
		[statusItem setMenu:statusItemMenu];
		// todo [statusItem setMenu:NSMenu]
		[statusItem setLength:NSVariableStatusItemLength];
	}
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[self saveState:self];
}

- (IBAction)saveState:(id)sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (dirs) {
		NSMutableArray *conf = [dirs droPubConfsByStrippingOptionalData];
		[defaults setObject:conf forKey:@"directories"];
	}
	else {
		[defaults removeObjectForKey:@"directories"];
	}
}

- (IBAction)orderFrontDirConfigWindow:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
	[mainWindow makeKeyAndOrderFront:sender];
}

- (IBAction)displayBrowseDialogForLocalPath:(id)sender {
	[self displayBrowseDialogForLocalPath];
}

- (BOOL)displayBrowseDialogForLocalPath {
	NSOpenPanel *panel;
	NSString *path = nil, *initialDir = nil, *lookingAtDir;
	NSArray *files, *selectedObjects;
	NSMutableDictionary *conf;
	
	panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:NO];
	[panel setCanCreateDirectories:YES];
	[panel setAllowsMultipleSelection:NO];
	[panel setTitle:@"Select local directory"];
	[panel setPrompt:@"Use directory"];
	[panel setMessage:@"Select a directory which to upload new files from."];
	initialDir = [[NSUserDefaults standardUserDefaults] objectForKey:@"localpathBrowseDialogDir"];
	
	if ([panel runModalForDirectory:initialDir file:nil] == NSOKButton) {
		if ((lookingAtDir = [panel directory]))
			[[NSUserDefaults standardUserDefaults] setObject:lookingAtDir forKey:@"localpathBrowseDialogDir"];
		files = [panel filenames];
		if ([files count] && (path = [files objectAtIndex:0])) {
			selectedObjects = [dirConfArrayController selectedObjects];
			if ([selectedObjects count] && (conf = [selectedObjects objectAtIndex:0])) {
				[conf setObject:path forKey:@"localpath"];
			}
			else {
				NSLog(@"no selection %@", selectedObjects);
				return NO;
			}
			return YES;
		}
	}
	return NO;
}

- (IBAction)addNewAndDisplayBrowseDialogForLocalPath:(id)sender {
	[dirConfArrayController add:sender];
	if (![self displayBrowseDialogForLocalPath])
		[dirConfArrayController remove:sender];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSUInteger i, index;
	NSMutableDictionary *dirConf, *oldDirConf;
	NSString *pk;
	#if DEBUG
		NSLog(@"observed%@[%@]: %@", object, keyPath, change);
	#endif
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
					dirConf = [NSMutableDictionary dictionary];
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
		//  NSKeyValueChangeRemoval = 3, NSKeyValueChangeReplacement = 4
	}
	else if ([object respondsToSelector:@selector(objectForKey:)] && [keyPath compare:@"icon"] != 0) {
		pk = [object objectForKey:@"localpath"];
		if (pk) {
			oldDirConf = [_dirConfPrevState objectForKey:pk];
			[_dirConfPrevState setObject:[object copy] forKey:pk];
		}
		else {
			// todo find a way to do this nicely
			oldDirConf = [NSMutableDictionary dictionary];
		}
		[self dirConfigWasModified:object previous:oldDirConf];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// setup supervisors for saved dirconfs
	for (NSMutableDictionary *conf in dirs) {
		if ([conf droPubConfIsEnabled] && [conf droPubConfIsComplete])
			[self startSupervising:conf];
	}
	
	// first launch or no dirconfs? -- show config window
	if ([dirs count] == 0)
		[self orderFrontDirConfigWindow:self];
	#if DEBUG
		NSLog(@"dirs = %@", dirs);
	#endif
}

- (void)dirConfigWasCreated:(NSMutableDictionary *)conf {
	#if DEBUG
		NSLog(@"dirConfigWasCreated %@", conf);
	#endif
	if ([conf droPubConfIsEnabled] && [conf droPubConfIsComplete])
		[self startSupervising:conf];
	[conf updateIconOfDroPubConf];
}

- (void)dirConfigWasModified:(NSMutableDictionary *)newConf previous:(NSMutableDictionary *)oldConf {
	// Note: oldDirConf MIGHT BE NULL if no "localpath" is set (it's the primary key)
	#if DEBUG
		NSLog(@"dirConfigWasModified %@ previous: %@", newConf, oldConf);
	#endif
	if (newConf && oldConf && [[newConf objectForKey:@"localpath"] compare:[oldConf objectForKey:@"localpath"]] != 0) {
		[self stopSupervising:oldConf];
		if ([newConf droPubConfIsEnabled] && [newConf droPubConfIsComplete])
			[self startSupervising:newConf];
	}
	else if (newConf && !oldConf) {
		if ([newConf droPubConfIsEnabled] && [newConf droPubConfIsComplete])
			[self startSupervising:newConf];
	}
	else if (newConf && [newConf droPubConfIsEnabled]) {
		if (![self supervisorForConf:oldConf] && [newConf droPubConfIsComplete])
			[self startSupervising:newConf];
		// If oldConf is already supervised, and conf becomes available, the 
		// supervisior will resume automatically, thus the negative check.
	}
	[newConf updateIconOfDroPubConf];
}

- (void)dirConfigWasDeleted:(NSMutableDictionary *)conf {
	#if DEBUG
		NSLog(@"dirConfigWasDeleted %@", conf);
	#endif
	[self stopSupervising:conf];
}

- (DPSupervisor *)supervisorForConf:(NSDictionary *)conf {
	return [supervisors objectForKey:[conf objectForKey:@"localpath"]];
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

- (void)stopSupervising:(NSDictionary *)conf {
	DPSupervisor *sv = [self supervisorForConf:conf];
	if (sv)
		[sv cancel];
	else
		NSLog(@"warn: stopSupervising: no supervisor found for conf %@", conf);
}

- (void)supervisedFilesInTransitDidChange:(DPSupervisor *)supervisor {
	NSUInteger count = [supervisor.filesInTransit count];
	if (count)
		[statusItem setImage:[NSImage imageNamed:@"status-item-sending.png"]];
	else
		[statusItem setImage:[NSImage imageNamed:@"status-item-standby.png"]];
	if (count)
		[statusItem setTitle:[NSString stringWithFormat:@"%u", count]];
	else
		[statusItem setTitle:nil];
}

- (void)supervisorDidExit:(DPSupervisor *)sv {
	NSString *pk = [sv.conf objectForKey:@"localpath"];
	if ([supervisors objectForKey:pk])
		[supervisors removeObjectForKey:pk];
}

@end
