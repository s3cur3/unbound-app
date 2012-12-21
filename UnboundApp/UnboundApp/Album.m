//
//  Album.m
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXAppDelegate.h"
#import "Album.h"
#import "Photo.h"
#import "PIXFileSystemDataSource.h"
#import "PIXDefines.h"


enum {
    AlbumStateThumbnailLoading = 1 << 1,
    AlbumStateThumbnailLoaded = 1 << 2,
    AlbumStateImageLoading = 1 << 3,
    AlbumStateImageLoaded = 1 << 3,
};

@interface Album()
{
    NSInteger _state;
    //NSSize _imageSize;
}

@property (nonatomic, strong) NSSortDescriptor *dateLastModifiedSortDescriptor;
@property (nonatomic,strong) NSDateFormatter *dateFormatter;

@end

@implementation Album

@synthesize photos = _photos;

- (id)initWithFilePathURL:(NSURL *) aURL;
{
#ifdef DEBUG
    ///PIXFileSystemDataSource *dataSource = [PIXFileSystemDataSource sharedInstance];
    //Album *existingAlbum = [dataSource.albumLookupTable valueForKey:aURL.path];
    //NSAssert(existingAlbum==nil, @"Album called with path that already exists..");
#endif
    self = [super init];
    if (self) {
        self.filePathURL = aURL;
        self.filePath = aURL.path;
        self.title = [_filePath lastPathComponent];
        self.photos = [NSMutableArray array];
    }
    return self;
}

- (id)initWithFilePath:(NSString *) aPath;
{
#ifdef DEBUG
    //PIXFileSystemDataSource *dataSource = [PIXFileSystemDataSource sharedInstance];
    //Album *existingAlbum = [dataSource.albumLookupTable valueForKey:aPath];
    //NSAssert(existingAlbum==nil, @"Album called with path that already exists..");
#endif
    self = [super init];
    if (self) {
        self.filePath = [aPath copy];
        self.title = [aPath lastPathComponent];
        self.photos = [NSMutableArray array];
    }
    return self;
}

-(NSString *)title
{
    if (self.filePath == nil)
    {
        return @"Title Not Available";
    } else if (_title == nil){
        NSAssert(self.filePath.length, @"Album has empty string value for filePath");
        _title = [self.filePath lastPathComponent];
    }
    return _title;
}


-(NSSortDescriptor *)dateLastModifiedSortDescriptor
{
    if (_dateLastModifiedSortDescriptor==nil) {
        _dateLastModifiedSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateLastModified" ascending:NO];
    }
    return _dateLastModifiedSortDescriptor;
}

-(NSDateFormatter *)dateFormatter
{
    if (_dateFormatter==nil) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    }
    return _dateFormatter;
}

-(void)setPhotos:(NSArray *)newPhotos{
    if (newPhotos == nil) {
        _photos = nil;
        return;
    }
    //NSMutableSet *sortedPhotos = [newPhotos mutableOrderedSetValueForKey:@"dateLastModified"];
    NSMutableArray *sortedPhotos = [newPhotos mutableCopy];
    [sortedPhotos sortUsingDescriptors:[NSArray arrayWithObject:[self dateLastModifiedSortDescriptor]]];
    
    _photos = [NSArray arrayWithArray:sortedPhotos];
}

-(NSArray *)photos{
    //[_photos sortUsingDescriptors:[NSArray arrayWithObject:[self dateLastModifiedSortDescriptor]]];
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

- (NSImage *)thumbnailImage {

    if (!self.photos.count)
    {
        return [NSImage imageNamed:@"nophoto"];
    }
    
    if (!(_state & AlbumStateThumbnailLoaded)) {
        if (_thumbnailImage == nil && (_state & AlbumStateThumbnailLoading) == 0) {
            _state |= AlbumStateThumbnailLoading;
            [self computeThumbnailImageInBackgroundThread];
        }
    }
    return _thumbnailImage;
}

- (NSString *) imageSubtitle;
{
    if (self.photos.count > 0 && self.dateLastScanned && self.dateMostRecentPhoto)
    {
        NSDate *aDate = self.dateMostRecentPhoto;//[[self coverImage] dateLastModified];
        
        NSString *formattedDateString = [self.dateFormatter stringFromDate:aDate];
        return [NSString stringWithFormat:@"%ld items from %@", self.photos.count, formattedDateString];
    } else if (self.photos.count == 0 && self.dateLastScanned && self.dateMostRecentPhoto)
    {
        NSDate *aDate = self.dateMostRecentPhoto;//[[self coverImage] dateLastModified];
        NSString *formattedDateString = [self.dateFormatter stringFromDate:aDate];
        return [NSString stringWithFormat:@"%ld items from %@", self.photos.count, formattedDateString];
    } else if (self.photos.count == 0 && self.dateLastScanned) {
        return @"No items";
    } else {
        return @"Loading...";
    }
    
}


//
/*-(NSArray *)children_old
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
}*/

-(NSEnumerator *)children
{
    // Create a local file manager instance
    NSFileManager *localFileManager=[[NSFileManager alloc] init];
    NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants;
    NSDirectoryEnumerator *dirEnumerator = [localFileManager enumeratorAtURL:self.filePathURL
                                                  includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey,
                                                                              NSURLIsDirectoryKey,nil]
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

-(void)updatePhotosFromFileSystem
{
    
    //dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW,0),^(void){
        NSEnumerator *content = [self children];
        NSMutableArray *somePhotos = [NSMutableArray array];
        NSDate *aDateMostRecentPhoto = nil;
        NSError *error;
        
        NSURL *itemURL = nil;
        while (itemURL = (NSURL*)[content nextObject])
        {
            NSString *utiValue;
            
            if (![itemURL getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:&error]) {
                [PIXAppDelegate presentError:error];
            }
            if (UTTypeConformsTo((__bridge CFStringRef)(utiValue), kUTTypeImage)) {
                Photo *aPhoto = [[Photo alloc] initWithURL:itemURL];
                NSDate *modDate = nil;
                NSError *error;
                if (![itemURL getResourceValue:&modDate forKey:NSURLContentModificationDateKey error:&error]) {
                    [[NSApplication sharedApplication] performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
                    //Unable to get the dateLastModified - for now just set the modDate to the distantPast as a temporary placeholder for sorting
                    //TODO: find the best way to handle this
                    modDate = [NSDate distantPast];
                }
                aPhoto.dateLastModified = modDate;
                if (!aDateMostRecentPhoto || [modDate isGreaterThanOrEqualTo:aDateMostRecentPhoto])
                {
                    aDateMostRecentPhoto = modDate;
                }
                [somePhotos addObject:aPhoto];
            }
        }

        dispatch_async(dispatch_get_main_queue(),^(void){

            self.photos = somePhotos;
            if (aDateMostRecentPhoto) {
                self.dateMostRecentPhoto = aDateMostRecentPhoto;
            } else {
                NSDate *folderDate = nil;
                NSError *error;
                NSURL *albumURL = [NSURL fileURLWithPath:self.filePath isDirectory:YES];
                if (![albumURL getResourceValue:&folderDate forKey:NSURLContentModificationDateKey error:&error]) {
                    [[NSApplication sharedApplication] presentError:error];
                } else {
                    self.dateMostRecentPhoto = folderDate;
                }
            }
            
            self.dateLastScanned = [NSDate date];
            
            [self createOrUpdateUnboundMetadataFile];
            
            [self resetThumbImage];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self];
            
            [self.photos makeObjectsPerformSelector:@selector(setAlbum:) withObject:self];
        });
        
    //});
    

    
    
}

-(void)deleteMetadataFile
{
    NSString *unboundFilePath = [NSString stringWithFormat:@"%@/.unbound", self.filePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:unboundFilePath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:unboundFilePath error:nil];
    }
}

-(void)createOrUpdateUnboundMetadataFile
{
    NSString *unboundFilePath = [NSString stringWithFormat:@"%@/.unbound", self.filePath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:unboundFilePath])
    {
        NSString *dateLastScannedString = [NSDateFormatter localizedStringFromDate:self.dateLastScanned dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterFullStyle];
        NSString *dateMostRecentPhotoString = [NSDateFormatter localizedStringFromDate:self.dateMostRecentPhoto dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterFullStyle];
        NSDictionary *unboundDict = @{ @"version" : @"0.1", @"dateLastScanned" : dateLastScannedString,  @"dateMostRecentPhoto" : dateMostRecentPhotoString};
        //Plist version
        //[unboundDict writeToFile:unboundFilePath atomically:YES];
        
#ifdef DEBUG
        NSAssert([NSJSONSerialization isValidJSONObject:unboundDict], @"Unable to write metdata file - invalid JSON format.");
#endif
        NSOutputStream *os = [[NSOutputStream alloc] initToFileAtPath:unboundFilePath append:NO];
        NSError *error;
        [os open];
        if (![NSJSONSerialization writeJSONObject:unboundDict toStream:os options:NSJSONWritingPrettyPrinted error:&error]) {
            [PIXAppDelegate presentError:error];
        }
        [os close];
    }
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
        NSEnumerator *content = [self children];
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

-(void)resetThumbImage
{
    self.thumbnailImage = nil;
    _state = 0;
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
    NSNumber *maxPixelSize = [NSNumber numberWithInteger:200];
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
                    /*NSSize imageSize = [[self class] getImageSizeFromImageSource:imageSource];
                    // Signal the main thread
                    [item performSelectorOnMainThread:@selector(mainThreadComputeImageSizeFinished:)
                                           withObject:[NSValue valueWithSize:imageSize]
                                        waitUntilDone:NO];*/
                    
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

- (void)mainThreadComputePreviewThumbnailFinished:(NSImage *)thumbnail {
    _state &= ~AlbumStateThumbnailLoading;
    _state |= AlbumStateThumbnailLoaded;
    if (_thumbnailImage != thumbnail) {
        //[_thumbnailImage release];
        self.thumbnailImage = thumbnail;
        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self];
    }
}

/*- (void)mainThreadComputeImageSizeFinished:(NSValue *)imageSizeValue {
    _imageSize = [imageSizeValue sizeValue];
    [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self];
}

- (NSSize)imageSize {
    return _imageSize;
}*/


@end
