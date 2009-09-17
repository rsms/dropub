#import "DPSupervisor.h"
#import "DPAppDelegate.h"
#import "DPSendFileOp.h"

@implementation DPSupervisor

@synthesize app, filesInTransit, delegate;

- (id)initWithApp:(DPAppDelegate *)x directory:(NSString *)d {
	self = [super init];
	app = x;
	qdir = d;
	fm = [NSFileManager defaultManager];
	return self;
}


- (BOOL)trashOrRemoveFileAtPath:(NSString *)path {
	if (FSPathMoveObjectToTrashSync([path UTF8String], NULL, kFSFileOperationSkipPreflight) != 0) {
		NSLog(@"failed to move %@ to trash -- removing it directly", path);
		if (![fm removeItemAtPath:path error:NULL]) {
			return NO;
		}
	}
	return YES;
}


- (void)sendFile:(NSString *)path name:(NSString *)name {
	DPSendFileOp *op;
	int fd;
	
	if ((fd = open([path UTF8String], O_RDWR | O_EXLOCK | O_NONBLOCK)) == -1) {
		//NSLog(@"%@ locked", name);
		// try again
		return;
	}
	else {
		// NSLog(@"%@ free", name);
		close(fd);
	}
	
	[self setPath:path inTransit:YES];
	op = [[DPSendFileOp alloc] initWithPath:path name:name];
	op.delegate = self;
	[g_opq addOperation:op];
}


- (void)fileTransmissionDidFailForPath:(NSString *)path {
	[self setPath:path inTransit:NO];
	// leave it and let's try again
}


- (void)fileTransmissionDidSucceedForPath:(NSString *)path {
	// we're safe to rm the file
	if (![self trashOrRemoveFileAtPath:path]) {
		NSLog(@"failed to remove %@! -- terminating since somethings seriously fucked up", path);
		[NSApp terminate:self];
	}
	[self setPath:path inTransit:NO];
}


- (void)setPath:(NSString *)path inTransit:(BOOL)inTransit {
	BOOL changed = NO, c = [filesInTransit containsObject:path];
	if (inTransit && !c) {
		[filesInTransit addObject:path];
		changed = YES;
	}
	else if (!inTransit && c) {
		[filesInTransit removeObject:path];
		changed = YES;
	}
	if (changed && delegate && [delegate respondsToSelector:@selector(supervisedFilesInTransitDidChange:)])
		[delegate supervisedFilesInTransitDidChange:self];
}


- (void)main {
	NSLog(@"%@ starting", self);
	NSString *filename, *path;
	NSDirectoryEnumerator *dirEnum;
	filesInTransit = [NSMutableSet set];
	
	while (!self.isCancelled) {
#if DEBUG
		NSLog(@"checking %@ (%u files in transit)", qdir, [filesInTransit count]);
#endif
		dirEnum = [fm enumeratorAtPath:qdir];
		while (filename = [dirEnum nextObject]) {
			if (![filename hasPrefix:@"."]) {
				path = [[qdir stringByAppendingPathComponent:filename] stringByStandardizingPath];
				if (![filesInTransit containsObject:path])
					[self sendFile:path name:filename];
			}
		}
		sleep(1);
	}
	NSLog(@"%@ cancelled", self);
}


@end

