#import "DSFileExistenceMonitor.h"

@interface DPSendFileOp : NSOperation {
	NSTask *task;
	NSString *path;
	NSString *name;
	NSDictionary *conf;
	DSFileExistenceMonitor *fexmon;
	id delegate;
	BOOL didInterruptTaskOnPurpose;
}
@property(assign) id delegate;
-(id)initWithPath:(NSString *)path name:(NSString *)name conf:(NSDictionary *)conf;
- (int)executeRemoteShellCommand:(NSString *)cmd;
@end

@protocol DPSEndFileOPDelegate
- (void)fileTransmission:(DPSendFileOp *)op didSucceedForPath:(NSString *)path remoteURI:(NSString *)hostpath;
- (void)fileTransmission:(DPSendFileOp *)op didAbortForPath:(NSString *)path;
- (void)fileTransmission:(DPSendFileOp *)op didFailForPath:(NSString *)path reason:(NSError *)error;
@end
