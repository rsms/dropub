@class DPAppDelegate;

@interface DPSupervisor : NSOperation {
	DPAppDelegate *app;
	NSString *qdir;
	NSMutableSet *filesInTransit;
	NSFileManager *fm;
	id delegate;
}

@property(readonly) DPAppDelegate *app;
@property(readonly) NSMutableSet *filesInTransit;
@property(assign) id delegate;

- (id)initWithApp:(DPAppDelegate *)app directory:(NSString *)qdir;
- (BOOL)trashOrRemoveFileAtPath:(NSString *)path;
- (void)setPath:(NSString *)path inTransit:(BOOL)inTransit;
- (void)sendFile:(NSString *)path name:(NSString *)name;

@end

@protocol DPSupervisorDelegate
- (void)supervisedFilesInTransitDidChange:(DPSupervisor *)supervisor;
@end
