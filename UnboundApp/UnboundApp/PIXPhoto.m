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
#import "PIXAppDelegate+CoreDataUtils.h"
#import "MakeThumbnailOperation.h"
#import "PIXDefines.h"

const CGFloat kThumbnailSize = 200.0f;

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
@dynamic dateLastUpdated;
@dynamic name;
@dynamic path;
@dynamic album;
@dynamic thumbnail;
@dynamic coverPhotoAlbum;

@synthesize cancelThumbnailLoadOperation;


//TODO: make this a real attribute?
-(NSString *)title
{
    return self.name;
}

//TODO: get rid of this
-(NSURL *)filePath;
{
    return [NSURL fileURLWithPath:self.path isDirectory:NO];
}

+ (NSImage *)makeThumbnailImageFromImageSource:(CGImageSourceRef)imageSource {
    NSImage *result;
    // This code needs to be threadsafe, as it will be called from the background thread.
    // The easiest way to ensure you only use stack variables is to make it a class method.
    NSNumber *maxPixelSize = [NSNumber numberWithInteger:kThumbnailSize];
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


- (void)mainThreadComputePreviewThumbnailFinished:(NSData *)data {
    if (self.cancelThumbnailLoadOperation==YES) {
        DLog(@"5)thumbnail operation was canceled - return?");
//        _thumbnailImageIsLoading = NO;
//        self.cancelThumbnailLoadOperation = NO;
//        return;
    }
    if (self.thumbnail == nil ) {
        PIXThumbnail *aThumb = [NSEntityDescription insertNewObjectForEntityForName:@"PIXThumbnail" inManagedObjectContext:self.managedObjectContext];
        aThumb.imageData = data;
        [self setThumbnail:aThumb];
    } else {
        self.thumbnail.imageData = data;
    }
    _thumbnailImageIsLoading = NO;
    

    NSNotification *aNotification = [NSNotification notificationWithName:kCreateThumbDidFinish object:self];
    [[NSNotificationQueue defaultQueue] enqueueNotification:aNotification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
    
    //If this is the coverPhoto of an album send a notification to the album to update it's thumb as well
    if (self.album.coverPhoto == self) {
        //NSNotification *albumNotification = [NSNotification notificationWithName:AlbumDidChangeNotification object:self.album];
        //[[NSNotificationQueue defaultQueue] enqueueNotification:albumNotification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnSender forModes:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self.album];
    }

    
}

-(void)cancelThumbnailLoading;
{
    self.cancelThumbnailLoadOperation = YES;
}

-(NSImage *)thumbnailImage
{
    if (_thumbnailImage ==nil)
    {
        NSData *imgData = self.thumbnail.imageData;
        if (imgData != nil) {
            _thumbnailImage = [[NSImage alloc] initWithData:imgData];
        } else {
            self.cancelThumbnailLoadOperation = NO;
            [self loadThumbnailImage];
            return [NSImage imageNamed:@"nophoto"];
        }
    }
    return _thumbnailImage;
}

-(void)loadThumbnailImage
{
    if (_thumbnailImageIsLoading == YES) {
        return;
    }

    if (self.thumbnail == nil) {
        
        if (self.cancelThumbnailLoadOperation ==YES) {
            DLog(@"0)thumbnail operation was canceled - return");
            self.cancelThumbnailLoadOperation = NO;
            return;
        }
        _thumbnailImageIsLoading = YES;
        
        
        PIXAppDelegate *appDelegate = (PIXAppDelegate *)[[NSApplication sharedApplication] delegate];
        NSOperationQueue *globalQueue = [appDelegate globalBackgroundSaveQueue];
        
        NSString *aPath = self.path;
        __weak PIXPhoto *weakSelf = self;
        [globalQueue addOperationWithBlock:^{
            
            if (weakSelf == nil || aPath==nil) {
                DLog(@"thumbnail operation completed after object was dealloced - return");
                _thumbnailImageIsLoading = NO;
                weakSelf.cancelThumbnailLoadOperation = NO;
                return;
            }
            
            if (weakSelf.cancelThumbnailLoadOperation==YES) {
                DLog(@"1)thumbnail operation was canceled - return");
                _thumbnailImageIsLoading = NO;
                weakSelf.cancelThumbnailLoadOperation = NO;
                return;
            }
            
            NSLog(@"Loading thumbnail");
            NSImage *image = nil;
            NSURL *urlForImage = [NSURL fileURLWithPath:aPath];
            CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)urlForImage, nil);
            if (imageSource) {
                
                if (weakSelf.cancelThumbnailLoadOperation==YES) {
                    DLog(@"2)thumbnail operation was canceled - return");
                    CFRelease(imageSource);
                    _thumbnailImageIsLoading = NO;
                    weakSelf.cancelThumbnailLoadOperation = NO;
                    return;
                }
                
                // Now, compute the thumbnail
                image = [[weakSelf class] makeThumbnailImageFromImageSource:imageSource];
                //NSBitmapImageRep *rep = [[image representations] objectAtIndex: 0];
                
                //NSData *data = [rep representationUsingType: NSJPEGFileType properties: nil];
                
                if (weakSelf.cancelThumbnailLoadOperation==YES) {
                    DLog(@"3)thumbnail operation was canceled - return");
                    CFRelease(imageSource);
                    _thumbnailImageIsLoading = NO;
                    weakSelf.cancelThumbnailLoadOperation = NO;
                    return;
                }
                
                NSData *data = [image TIFFRepresentation];
                
                if (weakSelf.cancelThumbnailLoadOperation==YES) {
                    DLog(@"4)thumbnail operation was canceled - return");
                    CFRelease(imageSource);
                    _thumbnailImageIsLoading = NO;
                    weakSelf.cancelThumbnailLoadOperation = NO;
                    return;
                }
                
                [weakSelf performSelectorOnMainThread:@selector(mainThreadComputePreviewThumbnailFinished:) withObject:data waitUntilDone:YES];
                
                CFRelease(imageSource);
            }
        }];
        
    }
    
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
