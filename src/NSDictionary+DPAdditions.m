#import "NSDictionary+DPAdditions.h"

@implementation NSDictionary (DPAdditions)

- (BOOL)droPubConfIsEnabled {
	NSNumber *n = [self objectForKey:@"disabled"];
	return (!n || ([n respondsToSelector:@selector(boolValue)] && ![n boolValue]));
}

- (BOOL)droPubConfIsComplete {
	NSString *localpath = [self objectForKey:@"localpath"];
	NSString *remoteHost = [self objectForKey:@"remoteHost"];
	return (localpath
			&& [localpath respondsToSelector:@selector(stringByAppendingString:)]
			&& [localpath length] && [[NSFileManager defaultManager] fileExistsAtPath:localpath]
			&& remoteHost
			&& [remoteHost respondsToSelector:@selector(stringByAppendingString:)]
			&& [remoteHost length]);
}

- (NSMutableDictionary *)droPubConfByStrippingOptionalData {
	NSMutableDictionary *conf = [self mutableCopy];
	[conf removeObjectForKey:@"icon"];
	return conf;
}

@end
