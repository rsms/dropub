#import "DPSupervisor.h"

@interface DPAppDelegate : NSObject {
	NSStatusItem *statusItem;
	IBOutlet NSWindow *mainWindow;
	IBOutlet NSMenu *statusItemMenu;
	IBOutlet NSTableView *dirConfTableView;
	IBOutlet NSArrayController *dirConfArrayController;
	NSMutableArray *dirs;
	NSMutableArray *_dirsPrevState;
	NSMutableDictionary *_dirConfPrevState;
	NSMutableDictionary *supervisors;
	NSArray *dirFields;
}

@property(readonly) NSMutableArray *dirs;

- (BOOL)displayBrowseDialogForLocalPath;

- (IBAction)orderFrontDirConfigWindow:(id)sender;
- (IBAction)displayBrowseDialogForLocalPath:(id)sender;
- (IBAction)addNewAndDisplayBrowseDialogForLocalPath:(id)sender;
- (IBAction)saveState:(id)sender;

- (DPSupervisor *)supervisorForConf:(NSDictionary *)conf;
- (DPSupervisor *)startSupervising:(NSDictionary *)dirConf;
- (void)stopSupervising:(NSDictionary *)conf;

- (void)dirConfigWasCreated:(NSMutableDictionary *)conf;
- (void)dirConfigWasModified:(NSMutableDictionary *)newConf previous:(NSMutableDictionary *)oldConf;
- (void)dirConfigWasDeleted:(NSMutableDictionary *)conf;

@end
