#import "DPAppDelegate.h"
#import "DPSupervisor.h"

/*@interface NSStatusBar (Unofficial)
-(id)_statusItemWithLength:(float)f withPriority:(int)d;
@end*/

@implementation DPAppDelegate

- (id)init {
	self = [super init];
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// todo read qdirs from config
	NSString *qdir = [@"~/Library/Caches/se.notion.dropub/queue" stringByStandardizingPath];
	[self startSupervisingDirectory:qdir];
	
	// For increased priority:
	// _statusItemWithLength:0 withPriority:INT_MAX
	
	if (statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:0]) {
		[statusItem setLength:0];
		// Setup the status item here.
		[statusItem setTitle:@"0"];
		[statusItem setImage:[NSImage imageNamed:@"status-item-standby.png"]];
		[statusItem setAlternateImage:[NSImage imageNamed:@"status-item-selected.png"]];
		[statusItem setHighlightMode:YES];
		// todo [statusItem setMenu:NSMenu]
		[statusItem setLength:NSVariableStatusItemLength];
	}
}

- (void)startSupervisingDirectory:(NSString *)qdir {
	NSError *error = nil;
	if (![[NSFileManager defaultManager] fileExistsAtPath:qdir] && ![[NSFileManager defaultManager] createDirectoryAtPath:qdir withIntermediateDirectories:YES attributes:nil error:&error])
	{
		ALERT_MODAL(@"Failed to create directory", @"Error: %@", error);
		[NSApp terminate:self];
	}
	DPSupervisor *sv = [[DPSupervisor alloc] initWithApp:self directory:qdir];
	sv.delegate = self;
	[g_opq addOperation:sv];
}

- (void)supervisedFilesInTransitDidChange:(DPSupervisor *)supervisor {
	NSUInteger count = [supervisor.filesInTransit count];
	if (count)
		[statusItem setImage:[NSImage imageNamed:@"status-item-sending.png"]];
	else
		[statusItem setImage:[NSImage imageNamed:@"status-item-standby.png"]];
	[statusItem setTitle:[NSString stringWithFormat:@"%u", count]];
}


@end
