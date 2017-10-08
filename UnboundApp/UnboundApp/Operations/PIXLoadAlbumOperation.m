//
//  PIXLoadAlbumOperation.m
//  UnboundApp
//
//  Created by Bob on 1/22/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXLoadAlbumOperation.h"
#import "LoadOperation.h"
#import "PIXAppDelegate.h"
#import "PIXDefines.h"

//// key for obtaining the current scan count
//NSString *kScanCountKey = @"scanCount";
//
//// key for obtaining the path of an image field
//NSString *kPathKey = @"path";
//
//// key for obtaining the directory containing an image field
//NSString *kDirectoryPathKey = @"dirPath";
//
//// key for obtaining the size of an image file
//NSString *kSizeKey = @"size";
//
//// key for obtaining the name of an image file
//NSString *kNameKey = @"name";
//
//// key for obtaining the mod date of an image file
//NSString *kModifiedKey = @"modified";
//
// NSNotification name to tell the Window controller an image file as found
NSString *kLoadAlbumDidFinish = @"LoadAlbumDidFinish";

@interface PIXLoadAlbumOperation()
{
    NSInteger ourScanCount;
    NSURL *loadURL;
    NSOperationQueue *queue;
}

@property (retain) NSURL *loadURL;
@property (retain) NSOperationQueue *queue;

@end

@implementation PIXLoadAlbumOperation

@synthesize loadURL, queue;

// -------------------------------------------------------------------------------
//	initWithRootPath:
// -------------------------------------------------------------------------------
- (id)initWithRootURL:(NSURL *)url queue:(NSOperationQueue *)qq scanCount:(NSInteger)scanCount
{
    self = [super init];
    if (self)
    {
        self.loadURL = url;
        self.queue = qq;
        ourScanCount = scanCount;
    }
    return self;
}

// -------------------------------------------------------------------------------
//	initWithPath:path
// -------------------------------------------------------------------------------
//- (id)initWithURL:(NSURL *)url scanCount:(NSInteger)scanCount
//{
//	self = [super init];
//    if (self)
//    {
//        self.loadURL = url;
//        ourScanCount = scanCount;
//    }
//    return self;
//}

// -------------------------------------------------------------------------------
//	isImageFile:filePath
//
//	Uses LaunchServices and UTIs to detect if a given file path is an image file.
// -------------------------------------------------------------------------------
- (BOOL)isImageFile:(NSURL *)url
{
    BOOL isImageFile = NO;
    
    NSString *utiValue;
    [url getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:nil];
    if (utiValue)
    {
        isImageFile = UTTypeConformsTo((__bridge CFStringRef)utiValue, kUTTypeImage);
    }
    return isImageFile;
}

-(NSDirectoryEnumerator *)children
{
    // Create a local file manager instance
    NSFileManager *localFileManager=[[NSFileManager alloc] init];
    NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants;
    NSDirectoryEnumerator *dirEnumerator = [localFileManager enumeratorAtURL:self.loadURL
                                                  includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey,
                                                                              NSURLIsDirectoryKey,NSURLTypeIdentifierKey,nil]
                                                                     options:options
                                                                errorHandler:^(NSURL *url, NSError *error) {
                                                                    // Handle the error.
                                                                    [PIXAppDelegate presentError:error];
                                                                    // Return YES if the enumeration should continue after the error.
                                                                    return YES;
                                                                }];
    
    NSAssert(dirEnumerator!=nil, @"Failed to get a directoryEnumerator for an album's URL");
    return dirEnumerator;
    
    
    
}


//-(BOOL)isDirectory:(NSURL *)url
//{
//    BOOL isDir = NO;
//    NSString *path = url.path;
//    NSFileManager *localFileManager=[[NSFileManager alloc] init];
//    //[[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
//    [localFileManager fileExistsAtPath:path isDirectory:&isDir];
//    if (isDir==NO)
//    {
//        //return NO;
//        DLog(@"shared file manager says it's not a dir : %@", url.path);
//    }
//    
//    
//    DLog(@"double checking...");
//    NSError *error;
//    NSNumber *isDirectory = nil;
//    if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
//        DLog(@"error on getResourceValue for file %@ : %@", url.path, error);
//        [[NSApplication sharedApplication] presentError:error];
//        DLog(@"AND IT'S NOT");
//    }
//    else if ([isDirectory boolValue] && isDir==NO) {
//        DLog(@"BUT IT IS!!!!!");
//        isDir = YES;
//    }
//    
//    return isDir;
//}

-(BOOL)albumExistsWithPhotos:(NSURL *)url
{

    BOOL hasPhotos = NO;

    NSEnumerator *content = [self children];
    for (NSURL *itemURL in content)
    {
        if ([self isImageFile:itemURL]) {
            hasPhotos = YES;
            break;
        }
    }
    
    if (!hasPhotos) {
        DLog(@"folder at path seems to contain no images : %@", url.path);
    }

    return hasPhotos;
}



// -------------------------------------------------------------------------------
//	main:
//
//	Examine the given file (from the NSURL "loadURL") to see it its an image file.
//	If an image file examine further and report its file attributes.
//
//	We could use NSFileManager, but to be on the safe side we will use the
//	File Manager APIs to get the file attributes.
// -------------------------------------------------------------------------------
- (void)main
{
	if (![self isCancelled])
	{
		// test to see if it's an image file
		if (/*[self isDirectory:loadURL] &&*/ [self albumExistsWithPhotos:loadURL])
		{
            NSDirectoryEnumerator *itr = [self children];
            for (NSURL *url in itr)
            {
                if ([self isCancelled])
                {
                    break;	// user cancelled this operation
                }
                
                // use NSOperation subclass "LoadOperation"
                LoadOperation *op = [[LoadOperation alloc] initWithURL:url scanCount:ourScanCount];
                [op setQueuePriority:NSOperationQueuePriorityHigh];      // second priority
                [self.queue addOperation:op];	// this will start the load operation
                DLog(@"Loading file '%@' in album, operationCount : %ld",url.path, [self.queue operationCount]);
            }
		
        
            NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                  //[self.loadURL lastPathComponent], kNameKey,
                                  //[self.loadURL absoluteString], kPathKey,
                                  [self.loadURL path], kPathKey,
                                  //[[self.loadURL URLByDeletingLastPathComponent] path] , kDirectoryPathKey,
                                  //modDateStr, kModifiedKey,
                                  //fileCreationDate, kModifiedKey,
                                  //[NSString stringWithFormat:@"%ld", [fileSize integerValue]], kSizeKey,
                                  [NSNumber numberWithInteger:ourScanCount], kScanCountKey,  // pass back to check if user cancelled/started a new scan
                                  nil];
            
            if (![self isCancelled])
            {
                // for the purposes of this sample, we're just going to post the information
                // out there and let whoever might be interested receive it (in our case its MyWindowController).
                //
                [[NSNotificationCenter defaultCenter] postNotificationName:kLoadAlbumDidFinish object:nil userInfo:info];
            }
        }
	}
}



@end
