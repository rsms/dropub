@interface DSFileExistenceMonitor : NSOperation {
	NSString *path;
	NSTimeInterval ival;
	id delegate;
	BOOL initiallyExisted;
}
-(id)initWithPath:(NSString *)path checkInterval:(NSTimeInterval)ival delegate:(id)delegate;
-(BOOL)checkExistence;
@end

@protocol DSFileExistenceMonitorDelegate
-(void)fileDidDisappear:(NSString *)path;
-(void)fileDidAppear:(NSString *)path;
@end
