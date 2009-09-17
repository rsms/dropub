#import "DPSendFileOp.h"
#import "DSFileExistenceMonitor.h"

#include <stdlib.h> /* system() */

@implementation DPSendFileOp

@synthesize delegate;


-(id)initWithPath:(NSString *)p name:(NSString *)n {
	self = [super init];
	path = p;
	name = n;
	dstHost = @"hunch.se";
	dstBasePath = @"/var/www/hunch.se/www/public/tmp/dropub";
	DSFileExistenceMonitor *fexmon = [[DSFileExistenceMonitor alloc] initWithPath:path checkInterval:1.0 delegate:self];
	[g_opq addOperation:fexmon];
	return self;
}


-(void)fileDidDisappear:(NSString *)path {
	NSLog(@"[%@] cancelling because %@ seized to exist", self, name);
	[self cancel];
	// todo send signal to child process
}


- (void)main {
	NSString *cmd, *dstPath;
	
	dstPath = [dstBasePath stringByAppendingPathComponent:name];
	cmd = [NSString stringWithFormat:@"scp -B -o ConnectTimeout=10 -o ServerAliveCountMax=30 -o ServerAliveInterval=30 -pC -q '%@' '%@:%@'", path, dstHost, dstPath];
	
	NSLog(@"[%@] sending %@ --> %@:%@", self, path, dstHost, dstPath);
#if DEBUG
	NSLog(@"[%@] system(\"%@\")", self, cmd);
#endif
	
	// todo use popen or NSTask so we can send cancel signal to our child process
	if (system([cmd UTF8String]) != 0) {
		NSLog(@"[%@] failed", self);
		if (delegate && [delegate respondsToSelector:@selector(fileTransmissionDidFailForPath:)])
			[delegate fileTransmissionDidFailForPath:path];
	}
	else {
		NSLog(@"[%@] done", self);
		if (delegate && [delegate respondsToSelector:@selector(fileTransmissionDidSucceedForPath:)])
			[delegate fileTransmissionDidSucceedForPath:path];
	}
	
}

@end
