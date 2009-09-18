#import "DPSendFileOp.h"

#include <stdlib.h> /* system() */

@implementation DPSendFileOp

@synthesize delegate;


-(id)initWithPath:(NSString *)p name:(NSString *)n conf:(NSDictionary *)c {
	self = [super init];
	path = p;
	name = n;
	conf = c;
	scpIsRunning = NO;
	fexmon = [[DSFileExistenceMonitor alloc] initWithPath:path checkInterval:1.0 delegate:self];
	[g_opq addOperation:fexmon];
	return self;
}


-(void)fileDidDisappear:(NSString *)path {
	NSLog(@"[%@] cancelling because %@ seized to exist", self, name);
	[self cancel];
}

- (void)cancel {
	// todo send interrupt signal to SCP process, if any (but only if scpIsRunning is true)
	if (fexmon && [fexmon respondsToSelector:@selector(cancel)])
		[fexmon cancel];
	[super cancel];
}


- (void)main {
	NSString *cmd, *dstHost, *dstPath;
	int status;
	
	NSLog(@"[%@] starting with conf %@", self, conf);
	
	if (!(dstHost = [conf objectForKey:@"remoteHost"])) {
		NSLog(@"[%@] missing 'remoteHost' in config -- aborting", self);
		goto fail;
	}
	if ([dstHost length] < 1) {
		NSLog(@"[%@] empty 'remoteHost' in config -- aborting", self);
		goto fail;
	}
	
	if (!(dstPath = [conf objectForKey:@"remotePath"]))
		dstPath = name;
	else
		dstPath = [dstPath stringByAppendingPathComponent:name];
	cmd = [NSString stringWithFormat:@"scp -B -o ConnectTimeout=10 -o ServerAliveCountMax=30 -o ServerAliveInterval=30 -pC -q \"%@\" \"%@:'%@'\"", path, dstHost, dstPath];
	
	NSLog(@"[%@] sending %@ --> %@:%@", self, path, dstHost, dstPath);
#if DEBUG
	NSLog(@"[%@] system(\"%@\")", self, cmd);
#endif
	
	// todo use popen or NSTask so we can send cancel signal to our child process
	scpIsRunning = YES;
	status = system([cmd UTF8String]);
	scpIsRunning = NO;
	
	if (status != 0) {
		NSLog(@"[%@] failed", self);
		goto fail;
	}
	else {
		NSLog(@"[%@] done", self);
		if (delegate && [delegate respondsToSelector:@selector(fileTransmission:didSucceedForPath:)])
			[delegate fileTransmission:self didSucceedForPath:path];
	}
	
	[fexmon cancel];
	fexmon = nil;
	// todo
	// aborted (e.g. conf[host] changed and the send operation need to restart)
	// [delegate fileTransmission:self didAbortForPath:path];
	
fail:
	
	// todo split up into "fail" and "error" -- "fail" means "try again soon", "error" 
	// means "permanent error", like for instance the remote path or host did not exist.
	// In other words, "error" when SCP tells us something is wrong and "fail" when
	// connection is lost, corrupt transmission or I/O error.
	
	if (delegate && [delegate respondsToSelector:@selector(fileTransmission:didFailForPath:)])
		[delegate fileTransmission:self didFailForPath:path];
}

@end
