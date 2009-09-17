
@interface DPAppDelegate : NSObject {
	NSStatusItem *statusItem;
}

- (void)startSupervisingDirectory:(NSString *)qdir;

@end
