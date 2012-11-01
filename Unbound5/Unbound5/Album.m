//
//  Album.m
//  Unbound5
//
//  Created by Bob on 10/10/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "Album.h"
#import "SearchItem.h"
#import "Photo.h"

NSString *AlbumDidChangeNotification = @"AlbumDidChangeNotification";

@implementation Album
/*- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"Untitled";
    }
    return self;
}*/

- (id)initWithFilePath:(NSString *) aPath
{
    self = [super init];
    if (self) {
        self.filePath = [aPath copy];
        self.title = [aPath lastPathComponent];
        self.photos = [NSMutableArray array];
    }
    return self;
}

-(void)addPhotosObject:(id)object
{
    [self.photos addObject:object];
}


-(NSArray *)children
{
    NSError *error = nil;
    NSURL *myDir = [NSURL fileURLWithPath:self.filePath isDirectory:YES];
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:myDir
                                                     includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLLocalizedNameKey, NSURLIsDirectoryKey, NSURLTypeIdentifierKey, nil]
                                                                        options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                          error:&error];
    
    if (error!=nil) {
        DLog(@"%@", error);
        return [NSArray array];
    }
    return content;
}

-(void)updatePhotosFromFileSystem
{
    
    /*NSError *error = nil;
    NSURL *myDir = [NSURL fileURLWithPath:self.filePath isDirectory:YES];
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:myDir
                                                        includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLLocalizedNameKey, NSURLIsDirectoryKey, NSURLTypeIdentifierKey, nil]
                                                                           options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                        error:&error];
    
    if (error!=nil) {
        DLog(@"%@", error);
    }*/
    NSArray *content = [self children];
    NSMutableArray *somePhotos = [NSMutableArray arrayWithCapacity:content.count];
    for (NSURL *itemURL in content)
    {
        NSString *utiValue;
        [itemURL getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:nil];
        if (UTTypeConformsTo((__bridge CFStringRef)(utiValue), kUTTypeImage)) {
            Photo *aPhoto = [[Photo alloc] initWithURL:itemURL];
            NSDate *modDate;
            [itemURL getResourceValue:&modDate forKey:NSURLContentModificationDateKey error:nil];
            aPhoto.dateLastModified = modDate;
            //[self addPhotosObject:aPhoto];
            [somePhotos addObject:aPhoto];
        }
    }
    if ([somePhotos count]==0)
    {
        self.photos = nil;
    } else {
        self.photos = somePhotos;
    }
    self.dateLastScanned = [NSDate date];
    [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self];
    
}

-(BOOL)albumExists
{
    BOOL isDir;
    if (self.filePath && [[NSFileManager defaultManager] fileExistsAtPath:self.filePath isDirectory:&isDir] && isDir)
    {
        return YES;
    }
    return NO;
}



-(BOOL)albumExistsWithPhotos
{
    BOOL existsWithPhotos = NO;
    if ([self albumExists])
    {
        NSArray *content = [self children];
        for (NSURL *itemURL in content)
        {
            NSString *utiValue;
            [itemURL getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:nil];
            
            if (UTTypeConformsTo((__bridge CFStringRef)(utiValue), kUTTypeImage)) {
                existsWithPhotos = YES;
                break;
            }
        }
    }
    return existsWithPhotos;
}

-(NSSortDescriptor *)dateLastModifiedSortDescriptor
{
    if (_dateLastModifiedSortDescriptor==nil) {
        _dateLastModifiedSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateLastModified" ascending:NO];
    }
    return _dateLastModifiedSortDescriptor;
}

-(NSMutableArray *)photos{
    [_photos sortUsingDescriptors:[NSArray arrayWithObject:[self dateLastModifiedSortDescriptor]]];
    return _photos;
}

-(Photo *)coverImage
{
    if (self.photos.count>0)
    {
        return [self.photos objectAtIndex:0];
    }
    return nil;
}

- (NSString *) imageSubtitle;
{
    /*if (_imageSize.height > 0.0)
    {
        return [NSString stringWithFormat:@"%.0f x %.0f", _imageSize.height, _imageSize.width];
    } else {
        return @"";
    }*/
    if (self.photos.count > 0 && self.dateLastScanned)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd 'at' HH:mm"];
        NSDate *aDate = [[self coverImage] dateLastModified];
        
        NSString *formattedDateString = [dateFormatter stringFromDate:aDate];
        //DLog(@"formattedDateString: %@", formattedDateString);
        return [NSString stringWithFormat:@"%ld photos - updated %@", self.photos.count, formattedDateString];
    } else {
        return @"Loading...";
    }
    
}

+ (NSSize)getImageSizeFromImageSource:(CGImageSourceRef)imageSource {
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    NSSize result;
    if (imageRef != NULL) {
        result.width = CGImageGetWidth(imageRef);
        result.height = CGImageGetHeight(imageRef);
        CGImageRelease(imageRef);
    } else {
        result = NSZeroSize;
    }
    return result;
}

+ (NSImage *)makeThumbnailImageFromImageSource:(CGImageSourceRef)imageSource {
    NSImage *result;
    // This code needs to be threadsafe, as it will be called from the background thread.
    // The easiest way to ensure you only use stack variables is to make it a class method.
    NSNumber *maxPixelSize = [NSNumber numberWithInteger:55];
    NSDictionary *imageOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                  (id)kCFBooleanTrue,(id)kCGImageSourceCreateThumbnailFromImageIfAbsent,
                                  //(id)kCFBooleanFalse,(id)kCGImageSourceCreateThumbnailFromImageIfAbsent,
                                  maxPixelSize, (id)kCGImageSourceThumbnailMaxPixelSize,
                                  kCFBooleanFalse, (id)kCGImageSourceCreateThumbnailWithTransform,
                                  //kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform,
                                  nil];
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)imageOptions);
    if (imageRef != NULL) {
        CGRect rect;
        rect.origin.x = 0;
        rect.origin.y = 0;
        rect.size.width = CGImageGetWidth(imageRef);
        rect.size.height = CGImageGetHeight(imageRef);
        result = [[NSImage alloc] init];
        //[result setFlipped:YES];
        [result setSize:NSMakeSize(rect.size.width, rect.size.height)];
        [result lockFocus];
        CGContextDrawImage((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort], rect, imageRef);
        
        [result unlockFocus];
        CFRelease(imageRef);
    } else {
        result = nil;
    }
    return result;
}

/* Use a background thread for computing the image thumbnails. This logic is rather complex,
 but should be easy to follow. The general procedure is to use a shared queue to place
 the SearchItems onto for thumbnail computation.
 */

#define HAS_DATA 1
#define NO_DATA  0

// The computeThumbnailClientQueue protectes the computeThumbnailClientQueue
static NSConditionLock *computeThumbnailConditionLock = nil;
static NSMutableArray *computeThumbnailClientQueue = nil;

+ (void)subthreadComputePreviewThumbnailImages {
    
    BOOL shouldExit = NO;
    while (!shouldExit) {
        //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        @autoreleasepool
        {
        
            NSImage *image = nil;
            BOOL aquiredLock = [computeThumbnailConditionLock lockWhenCondition:HAS_DATA beforeDate:[NSDate dateWithTimeIntervalSinceNow:5.0]];
            if (aquiredLock && ([computeThumbnailClientQueue count] > 0)) {
                // Remove the item from the queue. Retain it to ensure it stays alive while we use it in the thread.
                Album *item = [computeThumbnailClientQueue objectAtIndex:0];
                // Grab the URL while holding the lock, since the _url is cached and shared
                NSURL *urlForImage = (NSURL *)[[item coverImage] imageRepresentation];
                [computeThumbnailClientQueue removeObjectAtIndex:0];
                // Unlock the lock so the main thread can put more things on the stack
                BOOL hasMoreData = [computeThumbnailClientQueue count] > 0;
                [computeThumbnailConditionLock unlockWithCondition:hasMoreData ? HAS_DATA : NO_DATA];
                
                // Now, we can do our slow operations, like loading the image
                CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)urlForImage, nil);
                if (imageSource) {
                    // Grab the width/height
                    NSSize imageSize = [[self class] getImageSizeFromImageSource:imageSource];
                    // Signal the main thread
                    [item performSelectorOnMainThread:@selector(mainThreadComputeImageSizeFinished:)
                                           withObject:[NSValue valueWithSize:imageSize]
                                        waitUntilDone:NO];
                    
                    // Now, compute the thumbnail
                    image = [[self class] makeThumbnailImageFromImageSource:imageSource];
                    [item performSelectorOnMainThread:@selector(mainThreadComputePreviewThumbnailFinished:) withObject:image waitUntilDone:NO];
                    
                    CFRelease(imageSource);
                }
                
                // Now, we are done with the item.
                //[item release];
            } else {
                // It is possible that something was placed on the queue; check if we are done while holding the lock.
                [computeThumbnailConditionLock lock];
                shouldExit = [computeThumbnailClientQueue count] == 0;
                if (shouldExit) {
                    //[computeThumbnailClientQueue release];
                    computeThumbnailClientQueue = nil;
                }
                [computeThumbnailConditionLock unlock];
            }
        }
    }
}

- (void)computeThumbnailImageInBackgroundThread {
    if (computeThumbnailConditionLock == nil) {
        computeThumbnailConditionLock = [[NSConditionLock alloc] initWithCondition:NO_DATA];
    }
    
    // See if we need to startup the thread. The computeThumbnailClientQueue being nil is the signal to start the thread..
    // Acquire the lock first.
    [computeThumbnailConditionLock lock];
    if (computeThumbnailClientQueue == nil) {
        computeThumbnailClientQueue = [[NSMutableArray alloc] init];
        [NSThread detachNewThreadSelector:@selector(subthreadComputePreviewThumbnailImages) toTarget:[self class] withObject:nil];
    }
    
    if ([computeThumbnailClientQueue indexOfObjectIdenticalTo:self] == NSNotFound) {
        [computeThumbnailClientQueue addObject:self];
    }
    BOOL hasMoreData = [computeThumbnailClientQueue count] > 0;
    
    // Now, unlock, which will signal the background thread to start working
    [computeThumbnailConditionLock unlockWithCondition:hasMoreData ? HAS_DATA : NO_DATA];
}

- (NSImage *)thumbnailImage {
    if (!(_state & ItemStateThumbnailLoaded)) {
        if (_thumbnailImage == nil && (_state & ItemStateThumbnailLoading) == 0) {
            _state |= ItemStateThumbnailLoading;
            [self computeThumbnailImageInBackgroundThread];
        }
    }
    return _thumbnailImage;
}

- (void)mainThreadComputePreviewThumbnailFinished:(NSImage *)thumbnail {
    _state &= ~ItemStateThumbnailLoading;
    _state |= ItemStateThumbnailLoaded;
    if (_thumbnailImage != thumbnail) {
        //[_thumbnailImage release];
        self.thumbnailImage = thumbnail;
        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self];
    }
}

- (void)mainThreadComputeImageSizeFinished:(NSValue *)imageSizeValue {
    _imageSize = [imageSizeValue sizeValue];
    [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self];
}

- (NSSize)imageSize {
    return _imageSize;
}


-(void)dealloc
{
    _dateLastModifiedSortDescriptor = nil;
}
@end
