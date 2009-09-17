#import "DSFileExistenceMonitor.h"

@implementation DSFileExistenceMonitor

-(id)initWithPath:(NSString *)p checkInterval:(NSTimeInterval)iv delegate:(id)d {
	self = [super init];
	path = p;
	ival = iv;
	delegate = d;
	initiallyExisted = [self checkExistence];
	return self;
}

-(BOOL)checkExistence {
	return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (void)main {
	BOOL b, exists = initiallyExisted;
	
	while (!self.isCancelled) {
		b = [self checkExistence];
		if (b && !exists) {
			exists = YES;
			if (delegate && [delegate respondsToSelector:@selector(fileDidAppear:)])
				[delegate fileDidAppear:path];
			break;
		}
		else if (!b && exists) {
			exists = NO;
			if (delegate && [delegate respondsToSelector:@selector(fileDidDisappear:)])
				[delegate fileDidDisappear:path];
			break;
		}
		[NSThread sleepForTimeInterval:ival];
	}
	// exists holds state
}


@end
