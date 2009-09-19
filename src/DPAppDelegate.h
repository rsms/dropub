#import "DPSupervisor.h"

@interface DPAppDelegate : NSObject {
	NSUserDefaults *defaults;
	NSStatusItem *statusItem;
	IBOutlet NSWindow *mainWindow;
	IBOutlet NSMenu *mainMenu;
	IBOutlet NSMenu *statusItemMenu;
	IBOutlet NSTableView *dirConfTableView;
	IBOutlet NSArrayController *dirConfArrayController;
	IBOutlet NSToolbar *toolbar;
	IBOutlet NSView *foldersSettingsView;
	IBOutlet NSView *advancedSettingsView;
	NSMutableArray *dirs;
	NSMutableArray *_dirsPrevState;
	NSMutableDictionary *_dirConfPrevState;
	NSMutableDictionary *supervisors;
	NSArray *dirFields;
	BOOL showInMenuBar, showQueueCountInMenuBar;
	NSUInteger currentNumberOfFilesInTransit;
}

@property(readonly) NSMutableArray *dirs;
@property(assign) BOOL showInMenuBar, showQueueCountInMenuBar;

- (BOOL)displayBrowseDialogForLocalPath;

- (IBAction)displayViewForFoldersSettings:(id)sender;
- (IBAction)displayViewForAdvancedSettings:(id)sender;
- (IBAction)orderFrontFoldersSettingsWindow:(id)sender;
- (IBAction)orderFrontSettingsWindow:(id)sender;
- (IBAction)displayBrowseDialogForLocalPath:(id)sender;
- (IBAction)addNewAndDisplayBrowseDialogForLocalPath:(id)sender;
- (IBAction)enableMenuItem:(id)sender;
- (IBAction)disableMenuItem:(id)sender;
- (IBAction)enableOrDisableMenuItem:(id)sender;
- (IBAction)updateMenuItem:(id)sender;
- (IBAction)saveState:(id)sender;

- (DPSupervisor *)supervisorForConf:(NSDictionary *)conf;
- (DPSupervisor *)startSupervising:(NSDictionary *)dirConf;
- (void)stopSupervising:(NSDictionary *)conf;

- (void)dirConfigWasCreated:(NSMutableDictionary *)conf;
- (void)dirConfigWasModified:(NSMutableDictionary *)newConf previous:(NSMutableDictionary *)oldConf;
- (void)dirConfigWasDeleted:(NSMutableDictionary *)conf;

@end
