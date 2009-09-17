#import "DPAppDelegate.h"

NSOperationQueue *g_opq;

int main(int argc, char *argv[]) {
	NSApplication *app = [NSApplication sharedApplication];
	g_opq = [[NSOperationQueue alloc] init];
	DPAppDelegate *appDelegate = [[DPAppDelegate alloc] init];
	[app setDelegate:appDelegate];
	[app run];
	
	[g_opq cancelAllOperations];
	NSArray *ops = g_opq.operations;
	if ([ops count]) {
		NSLog(@"waiting for %u operations to complete...", [ops count]);
		[g_opq waitUntilAllOperationsAreFinished];
	}
	
	return 0;
}
