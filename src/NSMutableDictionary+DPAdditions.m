#import "NSMutableDictionary+DPAdditions.h"

@implementation NSMutableDictionary (DPAdditions)

- (void)updateIconOfDroPubConf {
	NSString *path = [self objectForKey:@"localpath"];
	if (path)
		[self setObject:[[NSWorkspace sharedWorkspace] iconForFile:path] forKey:@"icon"];
	else
		[self removeObjectForKey:@"icon"];
}

@end
