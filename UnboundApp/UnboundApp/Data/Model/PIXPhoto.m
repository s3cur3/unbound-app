//
//  PIXPhoto.m
//  UnboundApp
//
//  Created by Bob on 1/8/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <AVFoundation/AVFoundation.h>
#import "PIXPhoto.h"
#import "PIXAlbum.h"
#import "PIXAppDelegate.h"
#import "Unbound-Swift.h"
//#import "PIXAppDelegate+CoreDataUtils.h"
#import "MakeThumbnailOperation.h"
#import "PIXDefines.h"
#import "PIXFileParser.h"

const CGFloat kThumbnailSize = 370.0f;

@interface PIXPhoto()

//@property (nonatomic, retain, readwrite) MakeThumbnailOperation *   thumbnailResizeOperation;
//
//- (void)updateThumbnail;
//
//- (void)thumbnailCommitImage:(NSImage *)image isPlaceholder:(BOOL)isPlaceholder;
//- (void)thumbnailCommitImageData:(NSImage *)image;

@property (nonatomic, retain) QTMovie * videoFile;

@property (nonatomic, assign, readwrite) BOOL cancelThumbnailLoadOperationDelayFlag;

@property (retain) NSBlockOperation * slowThumbLoad;
@property (retain) NSBlockOperation * fastThumbLoad;
@property BOOL fasterThumbLoad;

@end

@implementation PIXPhoto

@dynamic dateLastModified;
@dynamic dateCreated;
@dynamic dateLastUpdated;
@dynamic dateTaken;
@dynamic sortDate;
@dynamic name;
@dynamic path;
@dynamic caption;
@dynamic album;
@dynamic thumbnailFilePath;
@dynamic datePhotoAlbum;
@dynamic stackPhotoAlbum;
@dynamic exifData;
@dynamic fileSize;
@dynamic latitude;
@dynamic longitude;
@dynamic width;
@dynamic height;

@synthesize cancelThumbnailLoadOperation;
@synthesize cancelThumbnailLoadOperationDelayFlag;
@synthesize thumbnailImage = _thumbnailImage;

@synthesize cancelFullsizeLoadOperation;
@synthesize fullsizeImage = _fullsizeImage;

@synthesize slowThumbLoad, fastThumbLoad;

@synthesize fasterThumbLoad;

@synthesize videoFile = _videoFile;

@synthesize isReallyDeleted;

//__strong static NSDateFormatter * _exifDateFormatter = nil;

// exif date formatter singleton for performance
+(NSDateFormatter *)exifDateFormatter
{
    
    __strong static NSDateFormatter * _exifDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _exifDateFormatter = [[NSDateFormatter alloc] init];
        [_exifDateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
    });
    
    return _exifDateFormatter;
}


//TODO: make this a real attribute?
-(NSString *)title
{
    if([self isReallyDeleted]) return nil;
    
    return self.name;
}

-(void)userSetCaption:(NSString *)userCaption
{
    // empty strings should be nil
    if([userCaption isEqualToString:@""])
    {
        userCaption = nil;
        
        if(self.caption == nil) return;
    }
    
    // do nothing if we're not changing the value
    if([userCaption isEqualToString:self.caption])
    {
        return;
    }
    
    // set the caption in the db
    self.caption = [userCaption copy];
    
    // write the caption to the unbound file
    [self.album setUnboundFileCaptionForPhoto:self];
}

//TODO: get rid of this
-(NSURL *)filePath;
{
    return [NSURL fileURLWithPath:self.path isDirectory:NO];
}

//
#pragma mark photo loading

-(void)cancelFullsizeLoading;
{
    self.cancelFullsizeLoadOperation = YES;
}


-(NSImage *)fullsizeImageForFullscreenDisplay
{
    if (_fullsizeImage == nil)
    {
        [self fullsizeImageStartLoadingIfNeeded:YES];
        
        
        //While full image is loading show the thumbnail stretched
        if (_thumbnailImage!=nil) {
            return _thumbnailImage;
        } else if (self.thumbnailFilePath) {
            
            NSData * thumbData = [NSData dataWithContentsOfFile:self.thumbnailFilePath];
            NSImage *thumbImage = [[NSImage alloc] initWithData:thumbData];
            [self setThumbnailImage:thumbImage];
            return _thumbnailImage;
        } else {
            //use placeholder as a last resort
            return nil;
        }
    }
    
    return _fullsizeImage;
}


-(NSImage *)fullsizeImageStartLoadingIfNeeded:(BOOL)shouldLoad
{
    if (_fullsizeImage == nil && !_fullsizeImageIsLoading && shouldLoad)
    {
        //_fullsizeImageIsLoading = YES;
        __weak PIXPhoto *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            weakSelf.cancelFullsizeLoadOperation = NO;
            [weakSelf loadFullsizeImage];
            
        });
    }
    return _fullsizeImage;
}


-(void)loadFullsizeImage
{
    if (_fullsizeImageIsLoading == YES) {
        return;
    }
    
    _fullsizeImageIsLoading = YES;
    
    NSString *aPath = self.path;
    __weak PIXPhoto *weakSelf = self;
    
    
    
    PIXAppDelegate *appDelegate = (PIXAppDelegate *)[[NSApplication sharedApplication] delegate];
    NSOperationQueue *globalQueue = [appDelegate globalBackgroundSaveQueue];
    [globalQueue addOperationWithBlock:^{
        
        if (weakSelf == nil || aPath==nil) {
            DLog(@"fullsize operation completed after object was dealloced - return");
            _fullsizeImageIsLoading = NO;
            weakSelf.cancelFullsizeLoadOperation = NO;
            return;
        }
        
        if (weakSelf.cancelFullsizeLoadOperation==YES) {
            DLog(@"1)fullsize operation was canceled - return");
            _fullsizeImageIsLoading = NO;
            weakSelf.cancelFullsizeLoadOperation = NO;
            return;
        }
        
        NSImage *image = nil;
        
        NSURL *urlForImage = [NSURL fileURLWithPath:aPath];
        

        CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)urlForImage, nil);
        if (imageSource) {
            
            if (weakSelf.cancelFullsizeLoadOperation==YES) {
                DLog(@"2)fullsize operation was canceled - return");
                CFRelease(imageSource);
                _fullsizeImageIsLoading = NO;
                weakSelf.cancelFullsizeLoadOperation = NO;
                return;
            }
            
            // Now, compute the screensized image
            image = [[weakSelf class] makeFullsizeImageFromImageSource:imageSource];
            
            if (weakSelf.cancelFullsizeLoadOperation==YES) {
                DLog(@"4)fulllsize operation was canceled - return");
                CFRelease(imageSource);
                _fullsizeImageIsLoading = NO;
                weakSelf.cancelFullsizeLoadOperation = NO;
                return;
            }
            
            [image setCacheMode:NSImageCacheAlways];
            
            // use this to 'warm up' the image and get it loaded in the bg and ready for display
            NSWindow * window = [[[PIXAppDelegate sharedAppDelegate] mainWindowController] window];
            NSRect windowFrame = [window frame];
            [image CGImageForProposedRect:&windowFrame context:nil hints:[window deviceDescription]];
            
            // TODO: specify color space, nsimagehintctm in hints directory
            // also try nsdevicedescription directly as hints dir
            
            // take cgimage and draw to bitmap should work with 1x1 bitmap
            
            
            [weakSelf performSelectorOnMainThread:@selector(mainThreadComputeFullsizePreviewFinished:) withObject:image waitUntilDone:YES];
            
            CFRelease(imageSource);
        }
        
        
    }];
}

-(void)mainThreadLoadFullsizeFinished:(id)result
{
    if (self.cancelFullsizeLoadOperation==YES) {
        DLog(@"5)fullsize operation was canceled - return?");
                _fullsizeImageIsLoading = NO;
                self.cancelFullsizeLoadOperation = NO;
               return;
    }
    
    //NSCParameterAssert(result);
    if (result == nil) {
        DLog(@"Load full size Photo was not successfull for photo : '%@'", self.path);
        result = [NSImage imageNamed:@"nophoto"];
    }
    if (self.fullsizeImage == nil) {
        [self setFullsizeImage:(NSImage *)result];
    } 
    _fullsizeImageIsLoading = NO;
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PhotoFullsizeDidChangeNotification object:self];
}



+ (NSImage *)makeFullsizeImageFromImageSource:(CGImageSourceRef)imageSource {
    
    
    NSImage *result = nil;

    
    // This code needs to be threadsafe, as it will be called from the background thread.
    // The easiest way to ensure you only use stack variables is to make it a class method.
    
    //NSNumber *maxPixelSize = [NSNumber numberWithInteger:2048.0f];
    //NSDictionary *desktopOptions = [[NSWorkspace sharedWorkspace] desktopImageOptionsForScreen:[NSScreen mainScreen]];
    
    //DLog(@"desktopOptions: %@", desktopOptions);
    //DLog(@"screen origin : %.0f , %.0f", visibleScreen.origin.x, visibleScreen.origin.y);
    //DLog(@"screen dimensions : %.0f x %.0f", visibleScreen.size.width, visibleScreen.size.height);
    CGImageRef imageRef = nil;
    
    BOOL resizeImage = NO;
    NSDictionary *imageOptions = nil;
    if (resizeImage)
    {
        NSRect visibleScreen = [[NSScreen mainScreen] visibleFrame];
        float maxDimension = (visibleScreen.size.width > visibleScreen.size.height) ? visibleScreen.size.width : visibleScreen.size.height;
        
        NSNumber *maxPixelSize = [NSNumber numberWithInteger:maxDimension];
        //DLog(@"Using maxPixelSize : %@", maxPixelSize);
        imageOptions = @{(id)kCGImageSourceCreateThumbnailFromImageIfAbsent: (id)kCFBooleanTrue,
                                       (id)kCGImageSourceCreateThumbnailFromImageAlways: (id)kCFBooleanTrue,
                                       (id)kCGImageSourceThumbnailMaxPixelSize: (id)maxPixelSize,
                                       (id)kCGImageSourceCreateThumbnailWithTransform: (id)kCFBooleanTrue};
        
        imageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)imageOptions);
        
    } else {

        imageOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                        (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageAlways,
                          (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform,
                          (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageIfAbsent,
                          //[NSNumber numberWithInt:128], (id)kCGImageSourceThumbnailMaxPixelSize,
                          nil]; 
        
        //imageOptions = @{};
        
        imageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)imageOptions);
    }

    

    
    if (imageRef != NULL) {
        
        result = [[NSImage alloc] initWithCGImage:imageRef size:CGSizeZero];
        CFRelease(imageRef);
    }
    
    return result;

    
}

- (void)mainThreadComputeFullsizePreviewFinished:(id)data {
    if (self.cancelFullsizeLoadOperation==YES) {
        DLog(@"5)fullsize operation was canceled - return?");
                _fullsizeImageIsLoading = NO;
                self.cancelFullsizeLoadOperation = NO;
               return;
    }

    _fullsizeImageIsLoading = NO;
    //NSCParameterAssert(data);
    if (data == nil) {
        DLog(@"Load full size Photo was not successfull for photo : '%@'", self.path);
        data = [NSImage imageNamed:@"nophoto"];
    }
    self.fullsizeImage = (NSImage *)data;
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PhotoFullsizeDidChangeNotification object:self];
    

    
    
}

#pragma mark -

+ (NSImage *)makeThumbnailImageFromImageSource:(CGImageSourceRef)imageSource always:(BOOL)alwaysFlag {
    
    NSImage *result = nil;

        
    // This code needs to be threadsafe, as it will be called from the background thread.
    // The easiest way to ensure you only use stack variables is to make it a class method.
    NSNumber *maxPixelSize = [NSNumber numberWithInteger:kThumbnailSize];

    NSDictionary *imageOptions = nil;


    if(alwaysFlag)
    {
        imageOptions = @{(id)kCGImageSourceCreateThumbnailFromImageIfAbsent: (id)kCFBooleanTrue,
                         (id)kCGImageSourceCreateThumbnailFromImageAlways: (id)kCFBooleanTrue,
                         (id)kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                         (id)kCGImageSourceCreateThumbnailWithTransform: (id)kCFBooleanTrue};
    }

    else
    {
        imageOptions = @{(id)kCGImageSourceCreateThumbnailFromImageIfAbsent: (id)kCFBooleanTrue,
                         (id)kCGImageSourceCreateThumbnailFromImageAlways: (id)kCFBooleanFalse, // this is set to false (faster, smaller thumbs)
                         (id)kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                         (id)kCGImageSourceCreateThumbnailWithTransform: (id)kCFBooleanTrue};
    }

    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)imageOptions);

    if (imageRef != NULL) {
        

        result = [[NSImage alloc] initWithCGImage:imageRef size:CGSizeZero];
        CFRelease(imageRef);
    }

    return result;

    
}


-(void)cancelThumbnailLoading;
{
    
    // do nothing if we're not loading
    if(_thumbnailImageIsLoading == NO) return;
    
    // delay this sliglty in case we start loading again
    if(self.cancelThumbnailLoadOperationDelayFlag == NO)
    {
        self.cancelThumbnailLoadOperationDelayFlag = YES;
        [self performSelector:@selector(delayedCancelThumbnailLoading) withObject:nil afterDelay:0.2];
    }
    
}

-(void)delayedCancelThumbnailLoading
{
    if(self.cancelThumbnailLoadOperationDelayFlag == YES)
    {
        self.cancelThumbnailLoadOperation = YES;
        
        if(self.fastThumbLoad && ![self.fastThumbLoad isExecuting])
        {
            [self.fastThumbLoad cancel];
            
            
            // make sure it's actually been removed from the queue (sometimes it starts executing before we cancel)
            if([[self sharedThumbnailLoadQueue].operations indexOfObject:self.fastThumbLoad] == NSNotFound)
            {
                self.fastThumbLoad = nil;
                
            }
            
            [[PIXFileParser sharedFileParser] decrementWorking];
            
        }
        
        if(self.slowThumbLoad && ![self.slowThumbLoad isExecuting])
        {
            [self.slowThumbLoad cancel];
            
            
            // make sure it's actually been removed from the queue (sometimes it starts executing before we cancel)
            if([[self sharedThumbnailLoadQueue].operations indexOfObject:self.slowThumbLoad] == NSNotFound)
            {
                self.slowThumbLoad = nil;
                
            }
            
            [[PIXFileParser sharedFileParser] decrementWorking];
              
        }
        
        // only mark this as not loading if we were actually able to cancel both operations
        if(self.slowThumbLoad == nil && self.fastThumbLoad == nil)
        {
            _thumbnailImageIsLoading = NO;
        }
    }

    // unset this flag so it will re-start the timer if it's cancelled again
    self.cancelThumbnailLoadOperationDelayFlag = NO;
}

-(NSImage *)thumbnailImageFast
{
    self.fasterThumbLoad = YES;
    return [self thumbnailImage];
}


-(NSImage *)thumbnailImage
{
    // uncancel the loads
    self.cancelThumbnailLoadOperation = NO;
    self.cancelThumbnailLoadOperationDelayFlag = NO;
    
    if (_thumbnailImage == nil && !_thumbnailImageIsLoading)
    {
        // if we've pregenerated a thumb load the file
        NSString * imagePath = self.thumbnailFilePath;
        if (imagePath != nil) {
            
            
            _thumbnailImageIsLoading = YES;
            __weak PIXPhoto *weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
                // this seems to perform a little faster than [NSImage initWithContentsOfFile:] 
                NSData * imgData = [NSData dataWithContentsOfFile:imagePath];
                NSImage * thumb = [[NSImage alloc] initWithData:imgData];

                if(thumb != nil)
                {
                    
                    // warm up the thumb nsimage so it draws faster
                    [thumb CGImageForProposedRect:nil context:[NSGraphicsContext currentContext] hints:nil];
                    
                    // set the thumbnail in memory
                    weakSelf.thumbnailImage = thumb;
                    
                    // use performSelector instead of dispatch here because it updates the ui much faster                    
                    //[weakSelf performSelectorOnMainThread:@selector(postPhotoUpdatedNote) withObject:nil waitUntilDone:NO];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf postPhotoUpdatedNote];
                    });
                    
                    _thumbnailImageIsLoading = NO;
                }
                
                // if we still haven't found the thumb then laod from original image
                else
                {
                    [weakSelf clearFiles];
                    
                    weakSelf.cancelThumbnailLoadOperation = NO;
                    [weakSelf loadThumbnailImage];
                    
                }
            });
            
            return _thumbnailImage;
            
        }
        
        // if there is no pregenerated thumb then load it from the original file
        else
        {
            self.cancelThumbnailLoadOperation = NO;
            _thumbnailImageIsLoading = YES;
            [self loadThumbnailImage];
            return _thumbnailImage;
        }
    }
    
    
    // the load seems to have been cancelled before the thumb was saved to disk
    if(!_thumbnailImageIsLoading && self.thumbnailFilePath == nil)
    {
        // try relaoding here, the load may have been cancelled before the image was saved
        self.cancelThumbnailLoadOperation = NO;
        _thumbnailImageIsLoading = YES;
        [self loadThumbnailImage];
    }
  

    return _thumbnailImage;
}

- (NSOperationQueue *)sharedThumbnailLoadQueue
{
    
    static NSOperationQueue * _sharedThumbnailFastLoadQueue = nil;
    
    if (_sharedThumbnailFastLoadQueue == NULL)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _sharedThumbnailFastLoadQueue = [[NSOperationQueue alloc] init];
            [_sharedThumbnailFastLoadQueue setName:@"com.pixite.thumbnailfast.generator"];
            [_sharedThumbnailFastLoadQueue setMaxConcurrentOperationCount:12];//NSOperationQueueDefaultMaxConcurrentOperationCount];
        });
        
    }
    return _sharedThumbnailFastLoadQueue;
}


+(NSString *)randomThumbPath
{
    static NSString * mainThumbDir = nil;
    static NSLock * mainThumbDirLock = nil;
    
    if(mainThumbDir == nil)
    {
        mainThumbDir = [[[PIXAppDelegate sharedAppDelegate] thumbSorageDirectory] path];
        mainThumbDirLock = [[NSLock alloc] init];
    }
    
    NSString * random = [NSString stringWithFormat:@"%d/%d/",(rand() % 1000 + 1), (rand() % 1000 + 1), nil];
    
    
    NSString * path = [mainThumbDir stringByAppendingPathComponent:random];
    
    
    NSFileManager * fm = [NSFileManager new];
    
    NSError * error = nil;
    [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    
    if(error)
    {
        DLog(@"Error creating directory: %@", [error description]);
        return nil;
    }
    
    NSString * newThumbPath = nil;
    
    [mainThumbDirLock lock];
    
    // make sure there isn't already a file there:
    do {
        newThumbPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg", (rand() % 100000 + 1), nil]];
    } while ([fm fileExistsAtPath:newThumbPath]);
    
    // create a file within this lock so another thumb doesn't overwrite the file before the thumb is generated
    [fm createFileAtPath:newThumbPath contents:nil attributes:nil];
    
    [mainThumbDirLock unlock];
    
    return newThumbPath;
}


-(void)loadThumbnailImageFromVideo
{
    // increment once for each bg operation (each will decrement itself
    [[PIXFileParser sharedFileParser] incrementWorking];
    
    NSManagedObjectID * photoID = [self objectID];
    
    _thumbnailImageIsLoading = YES;
    
    NSString *aPath = self.path;
    __weak PIXPhoto *weakSelf = self;
    
    self.fastThumbLoad = [NSBlockOperation blockOperationWithBlock:^{
        
        
        if (weakSelf == nil || aPath==nil || weakSelf.cancelThumbnailLoadOperation==YES) {
            DLog(@"thumbnail operation completed after object was dealloced or canceled - return");
            _thumbnailImageIsLoading = NO;
            weakSelf.cancelThumbnailLoadOperation = NO;
            
            [[PIXFileParser sharedFileParser] decrementWorking];
            return;
        }
        
        
        //NSLog(@"Loading thumbnail");
        __block NSImage *image = nil;
        NSURL *urlForImage = [NSURL fileURLWithPath:aPath];
        
        if (![[weakSelf class] isVideoPath:aPath]) {
            DLog(@"Not a vidoe file - returning");
            return;
        }
        NSError *anError;

        AVAsset *asset = [AVAsset assetWithURL:urlForImage];
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        CMTime time = [asset duration];
        time.value = 0;

        NSError *err;
        CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&err];
        if (err != nil) {
            DLog(@"Failed to generate movie thumbnail: %@\n%@", err, err.userInfo);
            _thumbnailImageIsLoading = NO;
            weakSelf.cancelThumbnailLoadOperation = NO;

            [[PIXFileParser sharedFileParser] decrementWorking];
            return;
        }

        if (weakSelf.cancelThumbnailLoadOperation==YES) {
            //DLog(@"2)thumbnail operation was canceled - return");
            CFRelease(cgImage);
            _thumbnailImageIsLoading = NO;
            weakSelf.cancelThumbnailLoadOperation = NO;

            [[PIXFileParser sharedFileParser] decrementWorking];
            return;
        }

        // keep the aspect ratio
        NSSize size;
        float aspect = (float) CGImageGetWidth(cgImage) / CGImageGetHeight(cgImage);
        if (aspect > 1.0f) {
            size = NSMakeSize(kThumbnailSize, kThumbnailSize * (1.0f / aspect));
        } else {
            size = NSMakeSize(kThumbnailSize * aspect, kThumbnailSize);
        }

        image = [[NSImage alloc] initWithCGImage:cgImage size:size];

        // tell the ui to update
        if(image) {
            // warm up the image file so it draws faster
            [image CGImageForProposedRect:nil context:[NSGraphicsContext currentContext] hints:nil];

            // save the thumb to memory
            [weakSelf setThumbnailImage:image];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self postPhotoUpdatedNote];
            });

            // we've finished updating the ui with the image, do everythinge else at a lower priority
            self.slowThumbLoad = [NSBlockOperation blockOperationWithBlock:^{
                
                // if the load was cancelled then bail
                if (weakSelf.cancelThumbnailLoadOperation) {
                    //DLog(@"3)thumbnail operation was canceled - return");
                    _thumbnailImageIsLoading = NO;
                    weakSelf.cancelThumbnailLoadOperation = NO;
                    
                    [[PIXFileParser sharedFileParser] decrementWorking];
                    return;
                }

                // get the exif data
                NSDictionary *exif;
                for (NSImageRep *rep in image.representations) {
                    if ([rep isKindOfClass:[NSBitmapImageRep class]]) {
                        NSBitmapImageRep *bRep = (NSBitmapImageRep *) rep;
                        exif = [bRep valueForProperty:NSImageEXIFData];
                        break;
                    }
                }

                // if the load was cancelled then bail
                if (weakSelf.cancelThumbnailLoadOperation==YES) {
                    //DLog(@"3)thumbnail operation was canceled - return");
                    _thumbnailImageIsLoading = NO;
                    weakSelf.cancelThumbnailLoadOperation = NO;

                    [[PIXFileParser sharedFileParser] decrementWorking];
                    return;
                }
                
                // get the bitmap data
                NSData *data = [image TIFFRepresentation];
                
                // now create a jpeg representation:
                NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:data];
                NSDictionary *imageProperties = @{
                        NSImageCompressionFactor : @0.6F,
                        //NSImageProgressive : [NSNumber numberWithBool:YES]
                };
                
                data = [imageRep representationUsingType:NSJPEGFileType properties:imageProperties];
                
                // create a new thumb path
                NSString * newThumbPath = [PIXPhoto randomThumbPath];
                [data writeToFile:newThumbPath atomically:YES];
                
                
                //////////////// option 1 save in bg
                
                NSManagedObjectContext * threadSafeContext = [[PIXAppDelegate sharedAppDelegate] threadSafePassThroughMOC];
                
                PIXPhoto * threadPhoto = (PIXPhoto *)[threadSafeContext objectWithID:photoID];
                
                if([threadPhoto isReallyDeleted])
                {
                    threadPhoto = nil;
                }


                [threadPhoto forceSetExifData:exif]; // this will automatically populate dateTaken and other fields
                [threadPhoto setThumbnailFilePath:newThumbPath];
                
                NSError * error = nil;
                [threadSafeContext save:&error];
                
                // we've finished the fast load. decrement working
                [[PIXFileParser sharedFileParser] decrementWorking];
                
                
                
                //////////////// option 2 save by dispatching to main
                //                dispatch_async(dispatch_get_main_queue(), ^{
                //
                //                    [self forceSetExifData:exif]; // this will automatically populate dateTaken and other fields
                //
                //                    [self setThumbnailFilePath:newThumbPath];
                //
                //                    //[self.managedObjectContext save:nil];
                //
                //                    // set the thumbnail data (this will save the data into core data, the ui has already been updated)
                //                    //[weakSelf mainThreadComputePreviewThumbnailFinished:data];
                //
                //                    [[PIXFileParser sharedFileParser] decrementWorking];
                //
                //                });
                //
                //////////////// end options
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    _thumbnailImageIsLoading = NO;
                    self.slowThumbLoad = nil;
                });
                
            }];
            
            [[PIXFileParser sharedFileParser] incrementWorking];
            [self.slowThumbLoad setQueuePriority:NSOperationQueuePriorityLow];
            [[self sharedThumbnailLoadQueue] addOperation:self.slowThumbLoad];
            
            [[PIXFileParser sharedFileParser] decrementWorking];
        }
        
        else
        {
            [[PIXFileParser sharedFileParser] decrementWorking];
        }
        
        self.fastThumbLoad = nil;
    }];
    

    // if this is a faster thumb load image (for the top images in album stacks)
    if(self.fasterThumbLoad)
    {
        [self.fastThumbLoad setQueuePriority:NSOperationQueuePriorityHigh];
    }
    
    else
    {
        [self.fastThumbLoad setQueuePriority:NSOperationQueuePriorityNormal];
    }
    
    [[self sharedThumbnailLoadQueue] addOperation:self.fastThumbLoad];

}

-(void)loadThumbnailImage
{    
    if ([[self class] isVideoPath:self.path]) {
        //DLog(@"Found a vidoe file - get it's thumb from movie object");
        [self loadThumbnailImageFromVideo];
        return;
    }

    
    // increment once for each bg operation (each will decrement itself
    [[PIXFileParser sharedFileParser] incrementWorking];
    
    NSManagedObjectID * photoID = [self objectID];
    
    _thumbnailImageIsLoading = YES;
    
    NSString *aPath = self.path;
    __weak PIXPhoto *weakSelf = self;
    
    self.fastThumbLoad = [NSBlockOperation blockOperationWithBlock:^{
        DLog(@"Fast loading thumb.")
        
        if (weakSelf == nil || aPath==nil || weakSelf.cancelThumbnailLoadOperation==YES) {
            DLog(@"thumbnail operation completed after object was dealloced or canceled - return");
            _thumbnailImageIsLoading = NO;
            weakSelf.cancelThumbnailLoadOperation = NO;
            
            [[PIXFileParser sharedFileParser] decrementWorking];
            return;
        }
        
        
        //NSLog(@"Loading thumbnail");
        __block NSImage *image = nil;
        NSURL *urlForImage = [NSURL fileURLWithPath:aPath];
        
        if ([[weakSelf class] isVideoPath:aPath]) {

            AVAsset *asset = [AVAsset assetWithURL:urlForImage];
            AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
            CMTime time = [asset duration];
            time.value = 0;

            NSError *err;
            CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&err];
            if (err != nil) {
                DLog(@"Failed to generate movie thumbnail: %@\n%@", err, err.userInfo);
                _thumbnailImageIsLoading = NO;
                weakSelf.cancelThumbnailLoadOperation = NO;

                [[PIXFileParser sharedFileParser] decrementWorking];
                return;
            }

            if (weakSelf.cancelThumbnailLoadOperation==YES) {
                //DLog(@"2)thumbnail operation was canceled - return");
                CFRelease(cgImage);
                _thumbnailImageIsLoading = NO;
                weakSelf.cancelThumbnailLoadOperation = NO;

                [[PIXFileParser sharedFileParser] decrementWorking];
                return;
            }

            // keep the aspect ratio
            size_t nativeWidth = CGImageGetWidth(cgImage);
            size_t nativeHeight = CGImageGetHeight(cgImage);

            // save the width/height in threadsafe context
            NSManagedObjectContext * threadSafeContext = [[PIXAppDelegate sharedAppDelegate] threadSafePassThroughMOC];
            PIXPhoto * threadPhoto = [threadSafeContext objectWithID:photoID];
            threadPhoto.width = @(nativeWidth);
            threadPhoto.height = @(nativeHeight);

            NSError * error = nil;
            [threadSafeContext save:&error];
            if (error) {
                DLog("Failed to save context: %@", err.localizedDescription);
            }

            NSSize size;
            float aspect = (float) nativeWidth / nativeHeight;
            if (aspect > 1.0f) {
                size = NSMakeSize(kThumbnailSize, kThumbnailSize * (1.0f / aspect));
            } else {
                size = NSMakeSize(kThumbnailSize * aspect, kThumbnailSize);
            }

            image = [[NSImage alloc] initWithCGImage:cgImage size:size];
            NSData *rep = [image TIFFRepresentation];
            
            CGImageSourceRef movieImageSource = nil;
            
            if(rep != nil)
            {
                movieImageSource = CGImageSourceCreateWithData((__bridge CFDataRef)rep, nil);
            }
            
            if (movieImageSource) {
                
                if (weakSelf.cancelThumbnailLoadOperation==YES) {
                    //DLog(@"2)thumbnail operation was canceled - return");
                    CFRelease(movieImageSource);
                    _thumbnailImageIsLoading = NO;
                    weakSelf.cancelThumbnailLoadOperation = NO;
                    
                    [[PIXFileParser sharedFileParser] decrementWorking];
                    return;
                }
                
                // Now, compute the thumbnail
                image = [[weakSelf class] makeThumbnailImageFromImageSource:movieImageSource always:NO];
                
                // tell the ui to update
                
                if(image)
                {
                    // warm up the image file so it draws faster
                    [image CGImageForProposedRect:nil context:[NSGraphicsContext currentContext] hints:nil];
                    
                    // save the thubm to memory
                    [weakSelf setThumbnailImage:image];
                    
                    //[self performSelectorOnMainThread:@selector(postPhotoUpdatedNote) withObject:nil waitUntilDone:NO];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self postPhotoUpdatedNote];
                    });
                }
            }
            [[PIXFileParser sharedFileParser] decrementWorking];
            self.fastThumbLoad = nil;


        }
        
        
        CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)urlForImage, nil);
        if (imageSource) {
            
            if (weakSelf.cancelThumbnailLoadOperation==YES) {
                //DLog(@"2)thumbnail operation was canceled - return");
                CFRelease(imageSource);
                _thumbnailImageIsLoading = NO;
                weakSelf.cancelThumbnailLoadOperation = NO;
                
                [[PIXFileParser sharedFileParser] decrementWorking];
                return;
            }

            // get the size
            NSDictionary *options = @{(NSString *) kCGImageSourceShouldCache: @(NO)};
            NSDictionary *properties = (__bridge NSDictionary *) CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
            if (properties) {
                NSNumber *width = properties[(NSString *)kCGImagePropertyPixelWidth];
                NSNumber *height = properties[(NSString *)kCGImagePropertyPixelHeight];
                if (width != nil && height != nil) {
                    NSManagedObjectContext * threadSafeContext = [[PIXAppDelegate sharedAppDelegate] threadSafePassThroughMOC];

                    PIXPhoto * threadPhoto = [threadSafeContext objectWithID:photoID];
                    threadPhoto.width = width;
                    threadPhoto.height = height;

                    NSError * error = nil;
                    [threadSafeContext save:&error];

                    if (error) {
                        DLog("Failed to save context: %@", error.localizedDescription);
                    }
                }
            }
            
            // Now, compute the thumbnail
            image = [[weakSelf class] makeThumbnailImageFromImageSource:imageSource always:NO];
            
            // tell the ui to update
            
            if(image)
            {
                // warm up the image file so it draws faster
                [image CGImageForProposedRect:nil context:[NSGraphicsContext currentContext] hints:nil];
                
                // save the thubm to memory
                [weakSelf setThumbnailImage:image];

                //[self performSelectorOnMainThread:@selector(postPhotoUpdatedNote) withObject:nil waitUntilDone:NO];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self postPhotoUpdatedNote];
                });
            }
            
            // we've finished updating the ui with the image, do everythinge else at a lower priority
            self.slowThumbLoad = [NSBlockOperation blockOperationWithBlock:^{
                NSLog(@"slow loading thumbnail");
                
                // if the load was cancelled then bail
                if (weakSelf.cancelThumbnailLoadOperation==YES) {
                    //DLog(@"3)thumbnail operation was canceled - return");
                    CFRelease(imageSource);
                    _thumbnailImageIsLoading = NO;
                    weakSelf.cancelThumbnailLoadOperation = NO;
                    
                    [[PIXFileParser sharedFileParser] decrementWorking];
                    return;
                }
                
                // get the exif data
                CFDictionaryRef cfDict = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil);
                NSDictionary * exif = (__bridge NSDictionary *)(cfDict);
                
                // if the load was cancelled then bail
                if (weakSelf.cancelThumbnailLoadOperation==YES) {
                    //DLog(@"3)thumbnail operation was canceled - return");
                    if(cfDict) CFRelease(cfDict);
                    CFRelease(imageSource);
                    _thumbnailImageIsLoading = NO;
                    weakSelf.cancelThumbnailLoadOperation = NO;
                    
                    [[PIXFileParser sharedFileParser] decrementWorking];
                    return;
                }
                
                // if we need to make an even higher res thumb (using always flag) then create it now
                if(image.size.height < kThumbnailSize && image.size.width < kThumbnailSize)
                {
                    image = [[weakSelf class] makeThumbnailImageFromImageSource:imageSource always:YES];
                    //NSBitmapImageRep *rep = [[image representations] objectAtIndex: 0];

                    NSLog(@"Resized image");

                    // tell the main thread we're done
                    if(image)
                    {
                        
                        // warm up the image file so it draws faster
                        [image CGImageForProposedRect:nil context:[NSGraphicsContext currentContext] hints:nil];

                        // save the thumb to memory
                        [weakSelf setThumbnailImage:image];
                        
                        //[self performSelectorOnMainThread:@selector(postPhotoUpdatedNote) withObject:nil waitUntilDone:NO];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self postPhotoUpdatedNote];
                        });
                    }
                }
                
                // get the bitmap data
                NSData *data = [image TIFFRepresentation];
                
                
                // now create a jpeg representation:
                NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:data];
                
                NSDictionary *imageProperties = @{NSImageCompressionFactor : @0.6F};
                
                data = [imageRep representationUsingType:NSJPEGFileType properties:imageProperties];
                
                
                // create a new thumb path
                NSString * newThumbPath = [PIXPhoto randomThumbPath];
                [data writeToFile:newThumbPath atomically:YES];
                
                
                //////////////// option 1 save in bg
                
                NSManagedObjectContext * threadSafeContext = [[PIXAppDelegate sharedAppDelegate] threadSafePassThroughMOC];
                
                PIXPhoto * threadPhoto = (PIXPhoto *)[threadSafeContext objectWithID:photoID];
                
                if([threadPhoto isReallyDeleted])
                {
                    threadPhoto = nil;
                }
                
                [threadPhoto forceSetExifData:exif]; // this will automatically populate dateTaken and other fields
                [threadPhoto setThumbnailFilePath:newThumbPath];
                
                NSError * error = nil;
                [threadSafeContext save:&error];
                
                // we've finished the fast load. decrement working
                [[PIXFileParser sharedFileParser] decrementWorking];

                
                // clean up
                if(cfDict) CFRelease(cfDict);
                CFRelease(imageSource);
                
                dispatch_async(dispatch_get_main_queue(), ^{

                    _thumbnailImageIsLoading = NO;
                    self.slowThumbLoad = nil;
                });
                
            }];
            
            [[PIXFileParser sharedFileParser] incrementWorking];
            [self.slowThumbLoad setQueuePriority:NSOperationQueuePriorityLow];
            [[self sharedThumbnailLoadQueue] addOperation:self.slowThumbLoad];
            
            [[PIXFileParser sharedFileParser] decrementWorking];
        }
        
        else
        {
            [[PIXFileParser sharedFileParser] decrementWorking];
        }
        
        self.fastThumbLoad = nil;
    }];
    
    // if this is a faster thumb load image (for the top images in album stacks)
    if(self.fasterThumbLoad)
    {
        [self.fastThumbLoad setQueuePriority:NSOperationQueuePriorityHigh];
    }
    
    else
    {
        [self.fastThumbLoad setQueuePriority:NSOperationQueuePriorityNormal];
    }

    DLog(@"Submitting thumb load.")
    [[self sharedThumbnailLoadQueue] addOperation:self.fastThumbLoad];
}

-(void)setDateCreated:(NSDate *)dateCreated
{
    // if the sort date isn't set yet
    if(self.sortDate == nil)
    {
        self.sortDate = dateCreated;
    }
    
    [self willChangeValueForKey:@"dateCreated"];
    [self setPrimitiveValue:dateCreated forKey:@"dateCreated"];
    [self didChangeValueForKey:@"dateCreated"];
    
}

-(void)setDateTaken:(NSDate *)dateTaken
{
    if(dateTaken != nil)
    {
        // always sort by date taken if we have it
        self.sortDate = dateTaken;
    }

    [self willChangeValueForKey:@"dateTaken"];
    [self setPrimitiveValue:dateTaken forKey:@"dateTaken"];
    [self didChangeValueForKey:@"dateTaken"];
    
}

- (NSSize) dimensions {
    if (self.width == nil || [self.width isEqualToNumber:@0] || self.height == nil || [self.height isEqualToNumber:@0]) {
        [self findExifData:YES];
    }
    return NSMakeSize(self.width.floatValue, self.height.floatValue);
}

-(NSDate *)findDisplayDate
{
    // load exif data if we need to
    [self findExifData:NO];
    
    // check if we have a dateTaken
    if(self.dateTaken)
    {
        return self.dateTaken;
    }
    

    return self.dateCreated;
}

-(void)findExifData
{
    [self findExifData:NO];
}

-(void)findExifData:(BOOL)force
{
    if(!force && self.exifData != nil) return;
    
    NSURL * imageURL = nil;
    CGImageSourceRef imageSrc = nil;
    
    if(self.path)
    {
        imageURL = [NSURL fileURLWithPath:self.path];
        imageSrc = CGImageSourceCreateWithURL((__bridge CFURLRef)imageURL, nil);
    }
    
    if (imageSrc!=nil)
    {
        // get the exif data
        NSDictionary *options = @{(NSString *) kCGImageSourceShouldCache: @(NO)};
        CFDictionaryRef cfDict = CGImageSourceCopyPropertiesAtIndex(imageSrc, 0, (__bridge CFDictionaryRef)options);
        NSDictionary *exif = (__bridge NSDictionary *) cfDict;
        
        // now set it
        [self forceSetExifData:exif]; // this will automatically populate dateTaken and other fields
 
        CFRelease(imageSrc);
        if (cfDict) CFRelease(cfDict);
    }

 }

-(void)forceSetExifData:(NSDictionary *)newExifData
{
    if(self.managedObjectContext == nil) return;
    
    if(newExifData == nil) // if we're setting this to nil, set the exif to a special dictionary
    {
        // set this to non-nil so we don't try and load it again
        [self setExifData:@{@"noExif":@"noExif"}];
        self.dateTaken = nil;
        
    }
    
    else
    {
        // set the exif data the normal way
        [self setExifData:newExifData];
        
        //self.dateTaken = nil;
        
        
        // now also set attributes that are derived from the exif data
        NSString * dateTakenString = [[newExifData objectForKey:@"{Exif}"] objectForKey:@"DateTimeOriginal"];
        
        if(!dateTakenString)
        {
            dateTakenString = [[newExifData objectForKey:@"{Exif}"] objectForKey:@"DateTimeDigitized"];
        }
        
        if(dateTakenString)
        {
            self.dateTaken = [[PIXPhoto exifDateFormatter] dateFromString:dateTakenString];
        }
        
       
        
        // set the lat and lon in the db (so we can fetch based on location)
        
        NSNumber * latitudeNumber = [newExifData valueForKeyPath: @"{GPS}.Latitude"];
        NSNumber * longitudeNumber = [newExifData valueForKeyPath: @"{GPS}.Longitude"];
        
        NSString * latRef = [newExifData valueForKeyPath: @"{GPS}.LatitudeRef"];
        NSString * longRef = [newExifData valueForKeyPath: @"{GPS}.LongitudeRef"];
        
        if (latitudeNumber && longitudeNumber) {
            double latitude = [latitudeNumber doubleValue];
            double longitude = [longitudeNumber doubleValue];
            if ([latRef isEqualToString: @"S"]) {
                latitude = -latitude;
            }
            if ([longRef isEqualToString: @"W"]) {
                longitude = -longitude;
            }
            [self setLatitude:@(latitude)];
            [self setLongitude:@(longitude)];
        }

        // set the dimensions if they haven't been set by the actual image

        if (self.width == nil || [self.width isEqualToNumber:@0]) {
            self.width = newExifData[(NSString *)kCGImagePropertyPixelWidth];
        }
        if (self.height == nil || [self.height isEqualToNumber:@0]) {
            self.height = newExifData[(NSString *)kCGImagePropertyPixelHeight];
        }
    }
}

#pragma mark -
#pragma mark Map Annotation

// Map Annotation stuff
-(CLLocationCoordinate2D)coordinate
{
    
    
	CLLocationCoordinate2D coord;
	
	coord.latitude = [[self latitude] doubleValue];
	coord.longitude = [[self longitude] doubleValue];
	
	return coord;
}

- (NSString *)subtitle
{
	return nil;
}



- (void)prepareForDeletion
{
    
    
    self.thumbnailImage = nil;
    self.fullsizeImage = nil;
    
	[self clearFiles];
	return [super prepareForDeletion];
}

-(void)clearFiles
{
    if([self isReallyDeleted]) return;
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    if([self thumbnailFilePath] && [fileManager fileExistsAtPath:[self thumbnailFilePath]])
    {
        NSError * error = nil;
        [fileManager removeItemAtPath:[self thumbnailFilePath] error:&error];
        
        if(error)
        {
            DLog(@"Error Deleting file: %@", [error description]);
        }
        
        self.thumbnailFilePath = nil;
    }
    
}

-(void)postPhotoUpdatedNote
{
    // enqueue these notes
    NSNotification * note = [NSNotification notificationWithName:PhotoThumbDidChangeNotification object:self];
    [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnSender forModes:nil];
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:PhotoThumbDidChangeNotification object:self];
    

    
    if(self.stackPhotoAlbum)
    {
        //[[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self.album];
        
        PIXAlbum * analbum = self.stackPhotoAlbum;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumStackDidChangeNotification object:analbum];

        
    }
}

- (BOOL) isReallyDeleted {
    return [self isDeleted] || [self managedObjectContext] == nil;
}

//Supported video types
//.3gp, .3gpp, .3gpp2, .asf, .avi, .dv, .dvi, .flv, .m2t, .m4p, .m4v, .mkv, .mov, .mpeg, .mpg, .mts, .ts, .vob, .webm, .wmv
+ (BOOL) isVideoPath:(NSString *)path
{
    NSString * lowercasepath = [path lowercaseString];
    
    if([lowercasepath hasSuffix:@".mp4"] ||
       [lowercasepath hasSuffix:@".m4p"] ||
       [lowercasepath hasSuffix:@".m4v"] ||
       [lowercasepath hasSuffix:@".mkv"] ||
       [lowercasepath hasSuffix:@".mov"] ||
//       [lowercasepath hasSuffix:@".3gp"] ||
//       [lowercasepath hasSuffix:@".3gpp"] ||
//       [lowercasepath hasSuffix:@".3gpp2"] ||
//       [lowercasepath hasSuffix:@".asf"] ||
       [lowercasepath hasSuffix:@".avi"] ||
//       [lowercasepath hasSuffix:@".dv"] ||
//       [lowercasepath hasSuffix:@".dvi"] ||
//       [lowercasepath hasSuffix:@".flv"] ||
//       [lowercasepath hasSuffix:@".m2t"] ||
//       [lowercasepath hasSuffix:@".m4p"] ||
//       [lowercasepath hasSuffix:@".m4v"] ||
//       [lowercasepath hasSuffix:@".mkv"] ||
//       [lowercasepath hasSuffix:@".mov"] ||
       [lowercasepath hasSuffix:@".mpeg"] ||
       [lowercasepath hasSuffix:@".mpg"])
//       [lowercasepath hasSuffix:@".mts"] ||
//       [lowercasepath hasSuffix:@".ts"] ||
//       [lowercasepath hasSuffix:@".vob"] ||
//       [lowercasepath hasSuffix:@".webm"] ||
//       [lowercasepath hasSuffix:@".wmv"])
    {
        return YES;
    }
    
    return NO;
}

-(BOOL)isVideo;
{
    return [[self class] isVideoPath:self.path];
}

-(AVAsset *)videoFile
{
    if (_videoFile == nil) {
        _videoFile = [AVAsset assetWithURL:[NSURL fileURLWithPath:self.path]];
    }
    return _videoFile;
}

-(NSDictionary *)videoAttributes;
{
    if (![self isVideo]) {
        return nil;
    }

    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:4];

    AVAsset *asset = self.videoFile;

    if (asset) {

        // get the duration
        double durationSeconds = CMTimeGetSeconds(asset.duration);
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:durationSeconds];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        dateFormatter.dateFormat = @"HH:mm:ss";
        attrs[@"Duration"] = [dateFormatter stringFromDate:date];

        // get the size
        NSURL *url = [NSURL fileURLWithPath:self.path];
        NSError *err;
        NSDictionary *values = [url resourceValuesForKeys:@[NSURLFileSizeKey, NSURLTotalFileSizeKey] error:&err];
        if (err != nil) {
            DLog(@"Failed to get file attributes. %@", err)
        }

        NSNumber *size = values[NSURLFileSizeKey];
        if (size == nil) {
            size = values[NSURLTotalFileSizeKey];
        }
        attrs[@"Size"] = size;

        for (AVMetadataItem * meta in asset.commonMetadata) {
            if (meta.commonKey == AVMetadataCommonKeyTitle) {
                attrs[@"Name"] = meta.stringValue;
            } else if (meta.commonKey == AVMetadataCommonKeyCreationDate) {
                attrs[@"Created"] = [self.class.exifDateFormatter stringFromDate:meta.dateValue];
            }
        }
    }

    return attrs;
}

@end


@implementation PIXPhoto(IKImageBrowserItem)


/*!
 @method imageUID
 @abstract Returns a unique string that identify this data source item (required).
 @discussion The image browser uses this identifier to keep the correspondance between its cache and the data source item
 */
- (NSString *)  imageUID;  /* required */
{
    return self.path;
}

/*!
 @method imageRepresentationType
 @abstract Returns the representation of the image to display (required).
 @discussion Keys for imageRepresentationType are defined below.
 */
- (NSString *) imageRepresentationType; /* required */
{
    if (![PIXPhoto isVideoPath:self.path]) {
        return IKImageBrowserPathRepresentationType;
    } else {
        return IKImageBrowserQTMoviePathRepresentationType;
    }
}

/*!
 @method imageRepresentation
 @abstract Returns the image to display (required). Can return nil if the item has no image to display.
 */
- (id) imageRepresentation; /* required */
{
    return self.path;
}

#pragma mark -
#pragma mark Optional Methods IKImageBrowserItem Informal Protocol

/*!
 @method imageVersion
 @abstract Returns a version of this item. The receiver can return a new version to let the image browser knows that it shouldn't use its cache for this item
 */
- (NSUInteger) imageVersion;
{
    return 1;
}

/*!
 @method imageTitle
 @abstract Returns the title to display as a NSString. Use setValue:forKey: with IKImageBrowserCellsTitleAttributesKey on the IKImageBrowserView instance to set text attributes.
 */
- (NSString *) imageTitle;
{
    return self.name;
}

/*!
 @method imageSubtitle
 @abstract Returns the subtitle to display as a NSString. Use setValue:forKey: with IKImageBrowserCellsSubtitleAttributesKey on the IKImageBrowserView instance to set text attributes.
 */
- (NSString *) imageSubtitle;
{
    return self.name;
}

/*!
 @method isSelectable
 @abstract Returns whether this item is selectable.
 @discussion The receiver can implement this methods to forbid selection of this item by returning NO.
 */
- (BOOL) isSelectable;
{
    return YES;
}

@end
