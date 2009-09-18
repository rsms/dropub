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

- (IBAction)orderFrontDirConfigWindow:(id)sender;

- (DPSupervisor *)startSupervising:(NSDictionary *)dirConf;
- (void)stopSupervising:(NSDictionary *)conf;

- (void)dirConfigWasCreated:(NSDictionary *)conf;
- (void)dirConfigWasModified:(NSDictionary *)newConf previous:(NSDictionary *)oldConf;
- (void)dirConfigWasDeleted:(NSDictionary *)conf;

@end
