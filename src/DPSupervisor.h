@class DPAppDelegate;

@interface DPSupervisor : NSOperation {
	DPAppDelegate *app;
	NSString *qdir;
	NSDictionary *conf;
	NSMutableSet *filesInTransit;
	NSFileManager *fm;
	NSMutableArray *currentSendOperations;
	id delegate;
}

@property(readonly) DPAppDelegate *app;
@property(readonly) NSMutableSet *filesInTransit;
@property(assign) id delegate;
@property(assign) NSDictionary *conf;

- (id)initWithApp:(DPAppDelegate *)app conf:(NSDictionary *)dirConf;
- (BOOL)trashOrRemoveFileAtPath:(NSString *)path;
- (void)setPath:(NSString *)path inTransit:(BOOL)inTransit;
- (void)sendFile:(NSString *)path name:(NSString *)name;

@end

@protocol DPSupervisorDelegate
- (void)supervisedFilesInTransitDidChange:(DPSupervisor *)supervisor;
- (void)supervisorDidExit:(DPSupervisor *)supervisor;
@end
