#import "DPAppDelegate.h"
#import "DPSupervisor.h"

/*@interface NSStatusBar (Unofficial)
-(id)_statusItemWithLength:(float)f withPriority:(int)d;
@end*/

@implementation DPAppDelegate

@synthesize dirs;

#pragma mark -
#pragma mark Initialization & setup

- (id)init {
	NSNumber *n;
	
	self = [super init];
	
	// init members
	defaults = [NSUserDefaults standardUserDefaults];
	currentNumberOfFilesInTransit = 0;
	
	// read general settings from defaults
	n = [defaults objectForKey:@"showInMenuBar"];
	showInMenuBar = (!n || [n boolValue]); // default YES
	n = [defaults objectForKey:@"showQueueCountInMenuBar"];
	showQueueCountInMenuBar = (n && [n boolValue]); // default NO
	n = [defaults objectForKey:@"paused"];
	paused = (n && [n boolValue]); // default NO
	
	// read showInDock
	showInDock = YES;
	NSMutableDictionary *infoPlist = [NSMutableDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Info.plist"]];
	n = [infoPlist objectForKey:@"LSUIElement"];
	if (n) showInDock = ![n boolValue];
	
	// prevent lock-out state
	if (!showInDock && !showInMenuBar)
		self.showInMenuBar = YES;
	
	// read dirs from defaults
	dirs = [defaults objectForKey:@"directories"];
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
	
	// Enable KVO for dirs
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
	[self enableOrDisableMenuItem:self];
	
	// set default selected toolbar item and view
	[toolbar setSelectedItemIdentifier:DPToolbarFoldersItemIdentifier];
}

#pragma mark -
#pragma mark Properties

- (BOOL)showInDock {
	return showInDock;
}

- (void)setShowInDock:(BOOL)y {
	#if DEBUG
	NSLog(@"showInDock = %d", y);
	#endif
	showInDock = y;
	NSString *infoPlistPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Info.plist"];
	NSMutableDictionary *infoPlist = [NSMutableDictionary dictionaryWithContentsOfFile:infoPlistPath];
	[infoPlist setObject:[NSNumber numberWithBool:!showInDock] forKey:@"LSUIElement"];
	[infoPlist writeToFile:infoPlistPath atomically:YES];
}

- (BOOL)showInMenuBar {
	return showInMenuBar;
}

- (void)setShowInMenuBar:(BOOL)y {
	#if DEBUG
	NSLog(@"showInMenuBar = %d", y);
	#endif
	showInMenuBar = y;
	[statusItem setEnabled:showInMenuBar];
	[defaults setBool:showInMenuBar forKey:@"showInMenuBar"];
	[self enableOrDisableMenuItem:self];
}

- (BOOL)showQueueCountInMenuBar {
	return showQueueCountInMenuBar;
}

- (void)setShowQueueCountInMenuBar:(BOOL)y {
	#if DEBUG
	NSLog(@"showQueueCountInMenuBar = %d", y);
	#endif
	showQueueCountInMenuBar = y;
	[defaults setBool:showQueueCountInMenuBar forKey:@"showQueueCountInMenuBar"];
	[self updateMenuItem:self];
}

- (BOOL)paused {
	return paused;
}

- (void)setPaused:(BOOL)y {
	#if DEBUG
		NSLog(@"paused = %d", y);
	#endif
	paused = y;
	[defaults setBool:paused forKey:@"paused"];
}


#pragma mark -
#pragma mark Actions

- (IBAction)enableOrDisableMenuItem:(id)sender {
	if (showInMenuBar)
		[self enableMenuItem:self];
	else
		[self disableMenuItem:self];
}

- (IBAction)enableMenuItem:(id)sender {
	// For increased priority:
	// _statusItemWithLength:0 withPriority:INT_MAX
	if (!statusItem && (statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:0])) {
		[statusItem setLength:0];
		[statusItem setAlternateImage:[NSImage imageNamed:@"status-item-selected.png"]];
		[statusItem setHighlightMode:YES];
		[statusItem setMenu:statusItemMenu];
		[statusItem setLength:NSVariableStatusItemLength];
		[self updateMenuItem:sender];
	}
}

- (IBAction)disableMenuItem:(id)sender {
	if (statusItem) {
		[[statusItem statusBar] removeStatusItem:statusItem];
		statusItem = nil;
	}
}

- (IBAction)updateMenuItem:(id)sender {
	if (statusItem) {
		if (currentNumberOfFilesInTransit)
			[statusItem setImage:[NSImage imageNamed:@"status-item-sending.png"]];
		else
			[statusItem setImage:[NSImage imageNamed:@"status-item-standby.png"]];
		
		if (showQueueCountInMenuBar) {
			[statusItem setLength:NSVariableStatusItemLength];
			[statusItem setTitle:[NSString stringWithFormat:@"%u", currentNumberOfFilesInTransit]];
		}
		else {
			if ([statusItem title])
				[statusItem setTitle:nil];
			[statusItem setLength:25.0];
		}
	}
}

- (IBAction)displayViewForFoldersSettings:(id)sender {
	if ([mainWindow contentView] != foldersSettingsView)
		[mainWindow setContentView:foldersSettingsView];// display:YES animate:YES];
}

- (IBAction)displayViewForAdvancedSettings:(id)sender {
	if ([mainWindow contentView] != advancedSettingsView)
		[mainWindow setContentView:advancedSettingsView];// display:YES animate:YES];
}

- (IBAction)saveState:(id)sender {
	if (dirs) {
		NSMutableArray *conf = [dirs droPubConfsByStrippingOptionalData];
		[defaults setObject:conf forKey:@"directories"];
	}
	else {
		[defaults removeObjectForKey:@"directories"];
	}
}

- (IBAction)orderFrontFoldersSettingsWindow:(id)sender {
	[self displayViewForFoldersSettings:sender];
	[toolbar setSelectedItemIdentifier:DPToolbarFoldersItemIdentifier];
	[self orderFrontSettingsWindow:sender];
}

- (IBAction)orderFrontSettingsWindow:(id)sender {
	if (![NSApp isActive])
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
	[panel setTitle:@"Select folder"];
	[panel setPrompt:@"Use folder"];
	[panel setMessage:@"Select a folder which to transfer files from."];
	initialDir = [defaults objectForKey:@"localpathBrowseDialogDir"];
	
	if ([panel runModalForDirectory:initialDir file:nil] == NSOKButton) {
		if ((lookingAtDir = [panel directory]))
			[defaults setObject:lookingAtDir forKey:@"localpathBrowseDialogDir"];
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


#pragma mark -
#pragma mark NSApplication delegate methods

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// setup supervisors for saved dirconfs
	for (NSMutableDictionary *conf in dirs) {
		if ([conf droPubConfIsEnabled] && [conf droPubConfIsComplete])
			[self startSupervising:conf];
	}
	
	// first launch or no dirconfs? -- show config window
	if ([dirs count] == 0)
		[self orderFrontFoldersSettingsWindow:self];
#if DEBUG
	NSLog(@"dirs = %@", dirs);
#endif
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[self saveState:self];
}


#pragma mark -
#pragma mark NSToolbar delegate methods

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)_toolbar {
	return [NSArray arrayWithObjects:
		DPToolbarFoldersItemIdentifier,
		DPToolbarSettingsItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarSeparatorItemIdentifier, nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)_toolbar {
	return [NSArray arrayWithObjects:DPToolbarFoldersItemIdentifier, DPToolbarSettingsItemIdentifier, nil];	
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)_toolbar {
	return [self toolbarDefaultItemIdentifiers:_toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)_toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *item = nil;
	if (itemIdentifier == DPToolbarFoldersItemIdentifier) {
		item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
		[item setImage:[[NSWorkspace sharedWorkspace] iconForFile:@"/System/Library/Caches"]];
		[item setLabel:@"Folders"];
		[item setToolTip:@"Manage watched folders"];
		[item setTarget:self];
		[item setAction:@selector(displayViewForFoldersSettings:)];
	}
	else if (itemIdentifier == DPToolbarSettingsItemIdentifier) {
		item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
		[item setImage:[NSImage imageNamed:@"NSPreferencesGeneral"]];
		[item setLabel:@"General"];
		[item setToolTip:@"Optional settings"];
		[item setTarget:self];
		[item setAction:@selector(displayViewForAdvancedSettings:)];
	}
	return item;
}


#pragma mark -
#pragma mark Key-Value Observation

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


#pragma mark -
#pragma mark DPSupervisor delegate methods

- (DPSupervisor *)supervisorForConf:(NSDictionary *)conf {
	return [supervisors objectForKey:[conf objectForKey:@"localpath"]];
}

- (void)supervisedFilesInTransitDidChange:(DPSupervisor *)supervisor {
	// update currentNumberOfFilesInTransit
	currentNumberOfFilesInTransit = 0;
	for (DPSupervisor *sv in supervisors)
		currentNumberOfFilesInTransit += [sv.filesInTransit count];
	[self updateMenuItem:self];
}

- (void)supervisorDidExit:(DPSupervisor *)sv {
	NSString *pk = [sv.conf objectForKey:@"localpath"];
	if ([supervisors objectForKey:pk])
		[supervisors removeObjectForKey:pk];
}


#pragma mark -
#pragma mark Supervision

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

@end
