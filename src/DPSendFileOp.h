
@interface DPSendFileOp : NSOperation {
	NSString *path;
	NSString *name;
	NSString *dstHost;
	NSString *dstBasePath;
	id delegate;
}
@property(assign) id delegate;
-(id)initWithPath:(NSString *)path name:(NSString *)name;
@end

@protocol DPSEndFileOPDelegate
- (void)fileTransmissionDidFailForPath:(NSString *)path;
- (void)fileTransmissionDidSucceedForPath:(NSString *)path;
@end
