//
//  PIXPhoto.m
//  UnboundApp
//
//  Created by Bob on 1/8/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "PIXPhoto.h"
#import "PIXAlbum.h"
#import "PIXThumbnail.h"
#import "PIXAppDelegate.h"
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
@dynamic thumbnail;
@dynamic datePhotoAlbum;
@dynamic stackPhotoAlbum;
@dynamic exifData;
@dynamic fileSize;
@dynamic latitude;
@dynamic longitude;

@synthesize cancelThumbnailLoadOperation;
@synthesize thumbnailImage = _thumbnailImage;

@synthesize cancelFullsizeLoadOperation;
@synthesize fullsizeImage = _fullsizeImage;


//TODO: make this a real attribute?
-(NSString *)title
{
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
    if([userCaption isEqualToString:self.caption]) return;
    
    // set the caption in the db
    self.caption = userCaption;
    
    // write the caption to the unbound file
    [self.album setUnboundFileCaptionForPhoto:self];
}

-(void)setCaption:(NSString *)caption
{
    [self willChangeValueForKey:@"caption"];
    [self setPrimitiveValue:caption forKey:@"caption"];
    [self didChangeValueForKey:@"caption"];
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

-(NSImage *)fullsizeImage
{
    //    if (_fullsizeImage == nil && !_fullsizeImageIsLoading)
    //    {
    //        __weak PIXPhoto *weakSelf = self;
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //
    //
    //            weakSelf.cancelFullsizeLoadOperation = NO;
    //            [weakSelf loadFullsizeImage];
    //
    //        });
    //    }
    return _fullsizeImage;
}

-(NSImage *)fullsizeImageForFullscreenDisplay
{
    if (_fullsizeImage == nil)
    {
        //_fullsizeImageIsLoading = YES;
//        if (!_fullsizeImageIsLoading) {
//            __weak PIXPhoto *weakSelf = self;
//            dispatch_async(dispatch_get_main_queue(), ^{
//                
//                
//                weakSelf.cancelFullsizeLoadOperation = NO;
//                [weakSelf loadFullsizeImage];
//                
//            });
//        }
        
        //While full image is loading show the thumbnail stretched
        if (_thumbnailImage!=nil) {
            return _thumbnailImage;
        } else if (self.thumbnail.imageData) {
            NSImage *thumbImage = [[NSImage alloc] initWithData:self.thumbnail.imageData];
            [self setThumbnailImage:thumbImage];
            return _thumbnailImage;
        } else {
            //use placeholder as a last resort
            return [NSImage imageNamed:@"nophoto"]; 
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
        
        //NSLog(@"Loading thumbnail");
        NSImage *image = nil;
//        image = [[NSImage alloc] initWithContentsOfFile:aPath];
//        if (image!=nil) {
//            [weakSelf performSelectorOnMainThread:@selector(mainThreadLoadFullsizeFinished:) withObject:image waitUntilDone:NO];
//            return;
//        }
       
        
        NSURL *urlForImage = [NSURL fileURLWithPath:aPath];
        
        /*
        /// loading the image directly from the data wasn't working for raw images
        //NSData * imageData = [NSData dataWithContentsOfURL:urlForImage];
        
        if (weakSelf.cancelFullsizeLoadOperation==YES) {
            //DLog(@"3)thumbnail operation was canceled - return");
            _fullsizeImageIsLoading = NO;
            weakSelf.cancelFullsizeLoadOperation = NO;
            return;
        }
        
        image = [[NSImage alloc] initWithContentsOfURL:urlForImage];
        
        if (weakSelf.cancelFullsizeLoadOperation==YES) {
                //DLog(@"3)thumbnail operation was canceled - return");
                _fullsizeImageIsLoading = NO;
                weakSelf.cancelFullsizeLoadOperation = NO;
                return;
            }
        
        
        
        [image lockFocus]; // call this to make sure the image loads ?
        [image unlockFocus];
        
        [weakSelf performSelectorOnMainThread:@selector(mainThreadComputeFullsizePreviewFinished:) withObject:image waitUntilDone:YES];
        */
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
            //NSBitmapImageRep *rep = [[image representations] objectAtIndex: 0];
            
//            // aslo get the exif data
//            CFDictionaryRef cfDict = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil);
//            //NSDictionary * exif = (__bridge NSDictionary *)(cfDict);
//            
//            
//            if (weakSelf.cancelFullsizeLoadOperation==YES) {
//                //DLog(@"3)thumbnail operation was canceled - return");
//                if(cfDict) CFRelease(cfDict);
//                CFRelease(imageSource);
//                _fullsizeImageIsLoading = NO;
//                weakSelf.cancelFullsizeLoadOperation = NO;
//                return;
//            }
            
            
//            NSData *data = [image TIFFRepresentation];
//            
//            if (weakSelf.cancelFullsizeLoadOperation==YES) {
//                DLog(@"4)fulllsize operation was canceled - return");
//                //if(cfDict) CFRelease(cfDict);
//                CFRelease(imageSource);
//                _fullsizeImageIsLoading = NO;
//                weakSelf.cancelFullsizeLoadOperation = NO;
//                return;
//            }
//            
//            NSImage *fullScreenImage = [[NSImage alloc] initWithData:data];
//             
        
            if (weakSelf.cancelFullsizeLoadOperation==YES) {
                DLog(@"4)fulllsize operation was canceled - return");
                //if(cfDict) CFRelease(cfDict);
                CFRelease(imageSource);
                _fullsizeImageIsLoading = NO;
                weakSelf.cancelFullsizeLoadOperation = NO;
                return;
            }
            
            //[image setCacheMode:NSImageCacheAlways];
            
            [image lockFocus]; // call this to make sure the image loads ?
            [image unlockFocus];
            
            [weakSelf performSelectorOnMainThread:@selector(mainThreadComputeFullsizePreviewFinished:) withObject:image waitUntilDone:YES];
            
            //if(cfDict) CFRelease(cfDict);
            CFRelease(imageSource);
        }//*/
        
        
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
    NSCParameterAssert(result);
    if (self.fullsizeImage == nil ) {
        [self setFullsizeImage:(NSImage *)result];
    } 
    _fullsizeImageIsLoading = NO;
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PhotoFullsizeDidChangeNotification object:self];
    
//    /*
//     NSNotification *aNotification = [NSNotification notificationWithName:kCreateThumbDidFinish object:self];
//     [[NSNotificationQueue defaultQueue] enqueueNotification:aNotification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
//     */
//    
//    //If this is the datePhoto of an album send a notification to the album to update it's thumb as well
//    if (self.album.datePhoto == self) {
//        //NSNotification *albumNotification = [NSNotification notificationWithName:AlbumDidChangeNotification object:self.album];
//        //[[NSNotificationQueue defaultQueue] enqueueNotification:albumNotification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnSender forModes:nil];
//        
//        if(self.dateTaken)
//        {
//            [self.album setAlbumDate:self.dateTaken];
//        }
//        
//        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self.album];
//    }
//    
//    else if(self.stackPhotoAlbum)
//    {
//        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self.album];
//    }
    
}


//-(void)setFullsizeAndNotify:(NSImage *)fullsize
//{
//    //self.thumbnailImage = thumb;
//    [[NSNotificationCenter defaultCenter] postNotificationName:PhotoThumbDidChangeNotification object:self];
//    
//    if(self.stackPhotoAlbum) {
//        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self.album];
//    }
//}

+ (NSImage *)makeFullsizeImageFromImageSource:(CGImageSourceRef)imageSource {
    
    NSImage *result = nil;
    // i'm putting this in a try/catch block because I kept getting non-fatal exceptions
    //@try {
    
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
//        NSRect visibleScreen = [[NSScreen mainScreen] visibleFrame];
//        float maxDimension = (visibleScreen.size.width > visibleScreen.size.height) ? visibleScreen.size.width : visibleScreen.size.height;
//        
//        NSNumber *maxPixelSize = [NSNumber numberWithInteger:maxDimension];
        //DLog(@"Using maxPixelSize : %@", maxPixelSize);
        imageOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                        (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageAlways,
                          (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform,
                          (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageIfAbsent,
                          //[NSNumber numberWithInt:128], (id)kCGImageSourceThumbnailMaxPixelSize,
                          nil]; 
        
        //imageOptions = @{};
        
        imageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)imageOptions);
    }

    
//    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)imageOptions);
//    
//    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    
    if (imageRef != NULL) {
        
        /*
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
        */
        
        result = [[NSImage alloc] initWithCGImage:imageRef size:CGSizeZero];
        CFRelease(imageRef);
    }
    
    return result;
    /*
     }
     
     
     @catch (NSException * e) {
     NSLog(@"Exception: %@", e);
     
     
     }
     @finally {
     return result;
     }*/
    
}

- (void)mainThreadComputeFullsizePreviewFinished:(id)data {
    if (self.cancelFullsizeLoadOperation==YES) {
        DLog(@"5)fullsize operation was canceled - return?");
                _fullsizeImageIsLoading = NO;
                self.cancelFullsizeLoadOperation = NO;
               return;
    }

    _fullsizeImageIsLoading = NO;
    NSCParameterAssert(data);
    self.fullsizeImage = (NSImage *)data;
    
//    if ([data isKindOfClass:[NSData class]])
//    {
//        aFullScreenImage = [[NSImage alloc] initWithData:data];
//    } else {
//        aFullScreenImage = (NSImage *)data;
//        self.fullsizeImage = aFullScreenImage;
//    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PhotoFullsizeDidChangeNotification object:self];
    

    
    
}

#pragma mark -

+ (NSImage *)makeThumbnailImageFromImageSource:(CGImageSourceRef)imageSource always:(BOOL)alwaysFlag {
    
    NSImage *result = nil;
    // i'm putting this in a try/catch block because I kept getting non-fatal exceptions
    //@try {
        
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
            
            /*
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
             */
            
            result = [[NSImage alloc] initWithCGImage:imageRef size:CGSizeZero];
            CFRelease(imageRef);
        }
    
        return result;
    /*
    }


    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        
        
    }
    @finally {
        return result;
    }*/
    
}


- (void)mainThreadComputePreviewThumbnailFinished:(NSData *)data {
    if (self.cancelThumbnailLoadOperation==YES || self.managedObjectContext == nil) {
        //DLog(@"5)thumbnail operation was canceled - return?");
        _thumbnailImageIsLoading = NO;
        self.cancelThumbnailLoadOperation = NO;
        return;
    }
    if (self.thumbnail == nil ) {
        PIXThumbnail *aThumb = [NSEntityDescription insertNewObjectForEntityForName:@"PIXThumbnail" inManagedObjectContext:self.managedObjectContext];
        aThumb.imageData = data;
        [self setThumbnail:aThumb];
    } else {
        self.thumbnail.imageData = data;
    }
    _thumbnailImageIsLoading = NO;
    
    [self postPhotoUpdatedNote];
    
}

-(void)cancelThumbnailLoading;
{
    self.cancelThumbnailLoadOperation = YES;
}


-(NSImage *)thumbnailImage
{
    //return nil;
    
    if (_thumbnailImage == nil && !_thumbnailImageIsLoading)
    {
        NSData *imgData = self.thumbnail.imageData;
        
        if (imgData != nil) {
            
            
           // _thumbnailImage = [[NSImage alloc] initWithData:imgData];
            
            
            _thumbnailImageIsLoading = YES;
            __weak PIXPhoto *weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                
                NSImage * thumb = [[NSImage alloc] initWithData:imgData];
                self.thumbnailImage = thumb;
                
                if(thumb != nil)
                {
                    // use performSelector instead of dispatch here because it updates the ui much faster
                    [weakSelf performSelectorOnMainThread:@selector(postPhotoUpdatedNote) withObject:nil waitUntilDone:NO];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _thumbnailImageIsLoading = NO;
                    });
                }
                
                // if we still havent found the thumb then laod from original image
                else
                {
                    weakSelf.cancelThumbnailLoadOperation = NO;
                    [weakSelf loadThumbnailImage];
                    
                }
            });
            
            return nil;
            
        }
        
        if (_thumbnailImage == nil)
        {
            self.cancelThumbnailLoadOperation = NO;
            _thumbnailImageIsLoading = YES;
            [self loadThumbnailImage];
            return nil;
        }
    }
    
    // TODO: figure out why this case isn't working -- scott
    // the load seems to have been cancelled before the thumb was saved to disk
    if(!_thumbnailImageIsLoading && self.thumbnail == nil)
    {
        // try relaoding here, the load may have been cancelled before the image was saved
        self.cancelThumbnailLoadOperation = NO;
        _thumbnailImageIsLoading = YES;
        [self loadThumbnailImage];
    }
    
    

    return _thumbnailImage;
}

-(void)setThumbAndNotify:(NSImage *)thumb
{
    //self.thumbnailImage = thumb;
    [[NSNotificationCenter defaultCenter] postNotificationName:PhotoThumbDidChangeNotification object:self];
    
    if(self.stackPhotoAlbum) {
        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self.album];
    }
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

-(NSDate *)findDisplayDate
{
    // if we don't have exif data already then load it right now
    if(self.exifData == nil)
    {
        NSURL * imageURL = [NSURL fileURLWithPath:self.path];
        CGImageSourceRef imageSrc = CGImageSourceCreateWithURL((__bridge CFURLRef)imageURL, nil);
        
        if (imageSrc!=nil)
        {
            // get the exif data
            CFDictionaryRef cfDict = CGImageSourceCopyPropertiesAtIndex(imageSrc, 0, nil);
            NSDictionary * exif = (__bridge NSDictionary *)(cfDict);
            
            
            [self forceSetExifData:exif]; // this will automatically populate dateTaken and other fields
            
            CFRelease(imageSrc);
            if(cfDict) CFRelease(cfDict);
        }
    }
    
    // check if we have a dateTaken
    if(self.dateTaken)
    {
        return self.dateTaken;
    }
    

    return self.dateCreated;
}

-(void)findExifDataUsingDispatchQueue:(dispatch_queue_t)aQueue
{
    if(self.exifData != nil) return;
    
    NSURL * imageURL = [NSURL fileURLWithPath:self.path];
    
    dispatch_async(aQueue, ^{
        
        CGImageSourceRef imageSrc = CGImageSourceCreateWithURL((__bridge CFURLRef)imageURL, nil);
        
        if (imageSrc!=nil)
        {
            // get the exif data
            CFDictionaryRef cfDict = CGImageSourceCopyPropertiesAtIndex(imageSrc, 0, nil);
            NSDictionary * exif = (__bridge NSDictionary *)(cfDict);
            
            // now set it on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self forceSetExifData:exif]; // this will automatically populate dateTaken and other fields
                
            });
            
            
            CFRelease(imageSrc);
            if(cfDict) CFRelease(cfDict);
        }
    });
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
        
        // now also set attributes that are derived from the exif data
        NSString * dateTakenString = [[newExifData objectForKey:@"{Exif}"] objectForKey:@"DateTimeOriginal"];
        
        if(dateTakenString)
        {
            NSDateFormatter* exifFormat = [[NSDateFormatter alloc] init];
            [exifFormat setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
            self.dateTaken = [exifFormat dateFromString:dateTakenString];
        }
        
        else
        {
            self.dateTaken = nil;
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
            [self setLatitude: [NSNumber numberWithDouble: latitude]];
            [self setLongitude: [NSNumber numberWithDouble: longitude]];
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

/*
-(NSOperationQueue *)sharedThumbnailFastLoadQueue;
{
    static NSOperationQueue * _sharedThumbnailFastLoadQueue = NULL;
    
    if (_sharedThumbnailFastLoadQueue == NULL)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _sharedThumbnailFastLoadQueue = [[NSOperationQueue alloc] init];
            [_sharedThumbnailFastLoadQueue setName:@"com.pixite.ub.unboundThumbnailFastLoadQueue"];
            //[_backgroundSaveQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
            [_sharedThumbnailFastLoadQueue setMaxConcurrentOperationCount:3];
        });
        
    }
    return _sharedThumbnailFastLoadQueue;
}*/


- (NSOperationQueue *)sharedThumbnailFastLoadQueue
{
    
    static NSOperationQueue * _sharedThumbnailFastLoadQueue = nil;
    
    if (_sharedThumbnailFastLoadQueue == NULL)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _sharedThumbnailFastLoadQueue = [[NSOperationQueue alloc] init];
            [_sharedThumbnailFastLoadQueue setName:@"com.pixite.thumbnailfast.generator"];
            //[_backgroundSaveQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
            [_sharedThumbnailFastLoadQueue setMaxConcurrentOperationCount:6];
        });
        
    }
    return _sharedThumbnailFastLoadQueue;
}

- (NSOperationQueue *)sharedThumbnailFullLoadQueue
{
    
    static NSOperationQueue * _sharedThumbnailFullLoadQueue = nil;
    
    if (_sharedThumbnailFullLoadQueue == NULL)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _sharedThumbnailFullLoadQueue = [[NSOperationQueue alloc] init];
            [_sharedThumbnailFullLoadQueue setName:@"com.pixite.thumbnailfull.generator"];
            //[_backgroundSaveQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
            [_sharedThumbnailFullLoadQueue setMaxConcurrentOperationCount:3];
        });
        
    }
    return _sharedThumbnailFullLoadQueue;
}


-(void)loadThumbnailImage
{
//    if (_thumbnailImageIsLoading == YES) {
//        return;
//    }

    [[PIXFileParser sharedFileParser] incrementWorking];
    
    _thumbnailImageIsLoading = YES;
    
    NSString *aPath = self.path;
    __weak PIXPhoto *weakSelf = self;
    
    [[self sharedThumbnailFastLoadQueue] addOperationWithBlock:^{
    
    
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
            
            // Now, compute the thumbnail
            image = [[weakSelf class] makeThumbnailImageFromImageSource:imageSource always:NO];
            //NSBitmapImageRep *rep = [[image representations] objectAtIndex: 0];
            
            // save the thubm to memory
            [weakSelf setThumbnailImage:image];
            
            // tell the ui to update
            [self performSelectorOnMainThread:@selector(postPhotoUpdatedNote) withObject:nil waitUntilDone:NO];
            
            // we've finished updating the ui with the image, do everythinge else at a lower priority
            [[self sharedThumbnailFullLoadQueue] addOperationWithBlock:^{
                
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
                    
                    // save the thubm to memory
                    [weakSelf setThumbnailImage:image];
                    
                    // tell the main thread we're done
                    [self performSelectorOnMainThread:@selector(postPhotoUpdatedNote) withObject:nil waitUntilDone:NO];
                }

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
                
                // get the bitmap data
                NSData *data = [image TIFFRepresentation];
                
                
                // now create a jpeg representation:
                NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:data];

                NSDictionary *imageProperties = @{NSImageCompressionFactor : [NSNumber numberWithFloat:0.6],
                                                  //NSImageProgressive : [NSNumber numberWithBool:YES]
                                                  };
                
                data = [imageRep representationUsingType:NSJPEGFileType properties:imageProperties];
                
                
                // if the load was cancelled then bail
                if (weakSelf.cancelThumbnailLoadOperation==YES) {
                    //DLog(@"4)thumbnail operation was canceled - return");
                    if(cfDict) CFRelease(cfDict);
                    CFRelease(imageSource);
                    _thumbnailImageIsLoading = NO;
                    weakSelf.cancelThumbnailLoadOperation = NO;
                    
                    [[PIXFileParser sharedFileParser] decrementWorking];
                    return;
                }
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self forceSetExifData:exif]; // this will automatically populate dateTaken and other fields
                    
                    // set the thumbnail data (this will save the data into core data, the ui has already been updated)
                    [weakSelf mainThreadComputePreviewThumbnailFinished:data];
                    
                    [[PIXFileParser sharedFileParser] decrementWorking];
                    
                });
                
                // clean up
                if(cfDict) CFRelease(cfDict);
                CFRelease(imageSource);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    _thumbnailImageIsLoading = NO;
                });
                
                
            }];
        }
        
        else
        {
            [[PIXFileParser sharedFileParser] decrementWorking];
        }
    }];
}

-(void)postPhotoUpdatedNote
{
    [[NSNotificationCenter defaultCenter] postNotificationName:PhotoThumbDidChangeNotification object:self];
    
    /*
    //If this is the datePhoto of an album send a notification to the album to update it's thumb as well
    if (self.album.datePhoto == self) {
        
        if(self.dateTaken)
        {
            [self.album setAlbumDate:self.dateTaken];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self.album];
    }*/
    
    if(self.stackPhotoAlbum)
    {
        //[[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self.album];
        NSNotification * note = [NSNotification notificationWithName:AlbumDidChangeNotification object:self.album];
        
        // enqueue these notes on the sender so if a few album stack images load right after each other it doesn't have to redraw multiple times
         [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnSender forModes:nil];
        
    }
}

- (BOOL) isReallyDeleted {
    return [self isDeleted] || [self managedObjectContext] == nil;
}


//- (NSImage *)thumbnailImage
//{
//    if (self->_thumbnailImage == nil) {
//        if ( (self.thumbnail != nil) && (self.thumbnail.imageData != nil) ) {
//            
//            // If we have a thumbnail from the database, return that.
//            
//            self.thumbnailImageIsPlaceholder = NO;
//            self->_thumbnailImage = [[NSImage alloc] initWithData:self.thumbnail.imageData];
//            assert(self->_thumbnailImage != nil);
//        } else {
//            assert(self.thumbnailResizeOperation == nil);   // a get also ensure there's a thumbnail in place (either a
//            // placeholder or the old thumbnail).
//            
//            // Otherwise, return the placeholder and kick off a get (unless we're
//            // already getting).
//            
//            self.thumbnailImageIsPlaceholder = YES;
//            self->_thumbnailImage = [NSImage imageNamed:@"nophoto"];
//            assert(self->_thumbnailImage != nil);
//            
//            [self startThumbnailLoading];
//        }
//    }
//    return self->_thumbnailImage;
//}
//
//- (void)startThumbnailLoading
//{
//    assert([NSThread isMainThread]);
//    
//    assert(self.thumbnailResizeOperation == nil);
//    
//    DLog(@"photo %@ thumbnail creation starting", self.path);
//    
//    //Let's start the resize operation.
//    NSError *anError = nil;
//    NSData *thumbData = [NSData dataWithContentsOfFile:self.path options:NSDataReadingMappedIfSafe error:&anError];
//    assert(thumbData!=nil);
//
//    self.thumbnailResizeOperation = [[MakeThumbnailOperation alloc] initWithImageData:thumbData MIMEType:@"image/jpeg"];
//    assert(self.thumbnailResizeOperation != nil);
//    
//    self.thumbnailResizeOperation.thumbnailSize = kThumbnailSize;
//    
//    // We want thumbnails resizes to soak up unused CPU time, but the main thread should
//    // always run if it can.  The operation priority is a relative value (courtesy of the
//    // underlying Mach THREAD_PRECEDENCE_POLICY), that is, it sets the priority relative
//    // to other threads in the same process.  A value of 0.5 is the default, so we set a
//    // value significantly lower than that.
//    
//    if ( [self.thumbnailResizeOperation respondsToSelector:@selector(setThreadPriority:)] ) {
//        [self.thumbnailResizeOperation setThreadPriority:0.2];
//    }
//    [self.thumbnailResizeOperation setQueuePriority:NSOperationQueuePriorityLow];
//    
//    [[[PIXAppDelegate sharedAppDelegate] globalBackgroundSaveQueue] addOperation:self.thumbnailResizeOperation];
//}
//
//- (void)thumbnailResizeDone:(MakeThumbnailOperation *)operation
//// Called when the operation to resize the thumbnail completes.
//// If all is well, we commit the thumbnail to our database.
//{
//    UIImage *   image;
//    
//    assert([NSThread isMainThread]);
//    assert([operation isKindOfClass:[MakeThumbnailOperation class]]);
//    assert(operation == self.thumbnailResizeOperation);
//    assert([self.thumbnailResizeOperation isFinished]);
//    
//    [[QLog log] logWithFormat:@"photo %@ thumbnail resize done", self.photoID];
//    
//    if (operation.thumbnail == NULL) {
//        [[QLog log] logWithFormat:@"photo %@ thumbnail resize failed", self.photoID];
//        image = nil;
//    } else {
//        image = [UIImage imageWithCGImage:operation.thumbnail];
//        assert(image != nil);
//    }
//    
//    [self thumbnailCommitImage:image isPlaceholder:NO];
//    [self stopThumbnail];
//}
//
//- (void)thumbnailCommitImage:(UIImage *)image isPlaceholder:(BOOL)isPlaceholder
//// Commits the thumbnail image to the object itself and to the Core Data database.
//{
//    // If we were given no image, that's a shortcut for the bad image placeholder.  In
//    // that case we ignore the incoming value of placeholder and force it to YES.
//    
//    if (image == nil) {
//        isPlaceholder = YES;
//        image = [UIImage imageNamed:@"Placeholder-Bad.png"];
//        assert(image != nil);
//    }
//    
//    // If it was a placeholder, someone else has logged about the failure, so
//    // we only log for real thumbnails.
//    
//    if ( ! isPlaceholder ) {
//        [[QLog log] logWithFormat:@"photo %@ thumbnail commit", self.photoID];
//    }
//    
//    // If we got a non-placeholder image, commit its PNG representation into our thumbnail
//    // database.  To avoid the scroll view stuttering, we only want to do this if the run loop
//    // is running in the default mode.  Thus, we check the mode and either do it directly or
//    // defer the work until the next time the default run loop mode runs.
//    //
//    // If we were running on iOS 4 or later we could get the PNG representation using
//    // ImageIO, but I want to maintain iOS 3 compatibility for the moment and on that
//    // system we have to use UIImagePNGRepresentation.
//    
//    if ( ! isPlaceholder ) {
//        if ( [[[NSRunLoop currentRunLoop] currentMode] isEqual:NSDefaultRunLoopMode] ) {
//            [self thumbnailCommitImageData:image];
//        } else {
//            [self performSelector:@selector(thumbnailCommitImageData:) withObject:image afterDelay:0.0 inModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
//        }
//    }
//    
//    // Commit the change to our thumbnailImage property.
//    
//    [self willChangeValueForKey:@"thumbnailImage"];
//    [self->_thumbnailImage release];
//    self->_thumbnailImage = [image retain];
//    [self  didChangeValueForKey:@"thumbnailImage"];
//}
//
//- (void)thumbnailCommitImageData:(UIImage *)image
//// Commits the thumbnail data to the Core Data database.
//{
//    [[QLog log] logWithFormat:@"photo %@ thumbnail commit image data", self.photoID];
//    
//    // If we have no thumbnail object, create it.
//    
//    if (self.thumbnail == nil) {
//        self.thumbnail = [NSEntityDescription insertNewObjectForEntityForName:@"Thumbnail" inManagedObjectContext:self.managedObjectContext];
//        assert(self.thumbnail != nil);
//    }
//    
//    // Stash the data in the thumbnail object's imageData property.
//    
//    if (self.thumbnail.imageData == nil) {
//        self.thumbnail.imageData = UIImagePNGRepresentation(image);
//        assert(self.thumbnail.imageData != nil);
//    }
//}
//
//- (BOOL)stopThumbnail
//{
//    BOOL    didSomething;
//    
//    didSomething = NO;
//    
//    if (self.thumbnailResizeOperation != nil) {
//        [self.thumbnailResizeOperation cancel];
//        self.thumbnailResizeOperation = nil;
//        didSomething = YES;
//    }
//    return didSomething;
//}


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
    return IKImageBrowserPathRepresentationType;
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
