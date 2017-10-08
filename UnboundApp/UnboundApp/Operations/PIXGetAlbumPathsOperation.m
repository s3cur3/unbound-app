//
//  PIXGetAlbumPathsOperation.m
//  UnboundApp
//
//  Created by Bob on 1/22/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//


#import "PIXGetAlbumPathsOperation.h"
#import "PIXLoadAlbumOperation.h"
#import "PIXAppDelegate.h"

NSString *kGetPathsOperationDidFinish = @"GetPathsOperationDidFinish";

@interface PIXGetAlbumPathsOperation ()
{
    NSURL *rootURL;
    NSOperationQueue *queue;
    NSUInteger ourScanCount;
}

@property (retain) NSURL *rootURL;
@property (retain) NSOperationQueue *queue;

@end

@implementation PIXGetAlbumPathsOperation

@synthesize rootURL, queue;

// -------------------------------------------------------------------------------
//	initWithRootPath:
// -------------------------------------------------------------------------------
- (id)initWithRootURL:(NSURL *)url queue:(NSOperationQueue *)qq scanCount:(NSInteger)scanCount
{
    self = [super init];
    if (self)
    {
        self.rootURL = url;
        self.queue = qq;
        ourScanCount = scanCount;
    }
    return self;
}

// -------------------------------------------------------------------------------
//	main:
// -------------------------------------------------------------------------------
- (void)main
{
    NSFileManager *localFileManager=[[NSFileManager alloc] init];
	NSDirectoryEnumerator *itr =
    [/*[NSFileManager defaultManager]*/localFileManager enumeratorAtURL:self.rootURL
                         includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey,
                                                     NSURLIsDirectoryKey,nil]
                                            options:(NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants)
                                       errorHandler:^(NSURL *url, NSError *error) {
                                           // Handle the error.
                                           [PIXAppDelegate presentError:error];
                                           // Return YES if the enumeration should continue after the error.
                                           return YES;
                                       }];
    for (NSURL *url in itr)
    {
        if ([self isCancelled])
		{
			break;	// user cancelled this operation
		}
        NSError *error;
        NSNumber *isDirectory = nil;
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            DLog(@"error on getResourceValue for file %@ : %@", url.path, error);
            [[NSApplication sharedApplication] presentError:error];
            //DLog(@"AND IT'S NOT");
        }
        if ([isDirectory boolValue] == NO) {
            DLog(@"skipping non directory at : %@", url.path);
            continue;
        }
        
        // use NSOperation subclass "LoadOperation"
//        PIXLoadAlbumOperation *op = [[PIXLoadAlbumOperation alloc] initWithURL:url queue:queue:self.queue scanCount:ourScanCount];
        PIXLoadAlbumOperation *op = [[PIXLoadAlbumOperation alloc] initWithRootURL:url queue:self.queue scanCount:ourScanCount];
        [op setQueuePriority:NSOperationQueuePriorityNormal];      // second priority
        [self.queue addOperation:op];	// this will start the load operation
        DLog(@"Loading directory '%@' in path, operationCount : %ld",url.path, [self.queue operationCount]);
    }
    
    if (![self isCancelled])
    {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kGetPathsOperationDidFinish object:nil userInfo:@{@"path" : self.rootURL.path}];
    }
}

@end
