#import "NSArray+DPAdditions.h"

@implementation NSArray (DPAdditions)

- (NSMutableArray *)droPubConfsByStrippingOptionalData {
	NSMutableArray *confs = [NSMutableArray arrayWithCapacity:[self count]];
	NSUInteger i, count = [self count];
	for (i = 0; i < count; i++) {
		NSMutableDictionary *conf = [self objectAtIndex:i];
		if ([conf respondsToSelector:@selector(droPubConfByStrippingOptionalData)])
			conf = [conf droPubConfByStrippingOptionalData];
		[confs insertObject:conf atIndex:i];
	}
	return confs;
}

@end
