#import "DSFileExistenceMonitor.h"

@interface DPSendFileOp : NSOperation {
	NSString *path;
	NSString *name;
	NSDictionary *conf;
	DSFileExistenceMonitor *fexmon;
	id delegate;
	BOOL scpIsRunning;
}
@property(assign) id delegate;
-(id)initWithPath:(NSString *)path name:(NSString *)name conf:(NSDictionary *)conf;
@end

@protocol DPSEndFileOPDelegate
- (void)fileTransmission:(DPSendFileOp *)op didFailForPath:(NSString *)path;
- (void)fileTransmission:(DPSendFileOp *)op didSucceedForPath:(NSString *)path;
- (void)fileTransmission:(DPSendFileOp *)op didAbortForPath:(NSString *)path;
@end
