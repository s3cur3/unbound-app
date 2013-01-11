//
//  Photo.m
//  UnboundCoreDataUtility
//
//  Created by Bob on 1/5/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "Photo.h"
#import "PIXAppDelegate.h"

NSString *kCreateThumbDidFinish = @"kCreateThumbDidFinish";
NSUInteger kMaxPixelSize = 200;

@interface Photo (ExtraAccessors)

-(NSString *)path;
- (void)setPath:(NSString *)value;
- (void)setName:(NSString *)value;

@end

@implementation Photo

@dynamic dateLastUpdated;
@dynamic dateLastModified;
@dynamic image;
@dynamic name;
//@dynamic path;
@dynamic thumbnail;

- (void)awakeFromFetch {
    
    [super awakeFromFetch];
    //NSData *thumbnailData = [self thumbnail];
    //if (thumbnailData != nil) {
        //TODO: possibly some background low priority thumb loading?
        //NSColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
        //[self setPrimitiveColor:color];
    //}
}

- (BOOL)validateName:(id *)valueRef error:(NSError **)outError
{
    BOOL validationResult = YES;
    //TODO: see if this is a good place to change the title of the actual image file...
    return validationResult;
}

- (NSString *)path
{
    [self willAccessValueForKey:@"path"];
    NSString *tmpValue = [self primitiveValueForKey:@"path"];
    [self didAccessValueForKey:@"path"];
    return tmpValue;
}
            
- (void)setPath:(NSString *)value
{
    [self willChangeValueForKey:@"path"];
    [self setPrimitiveValue:value forKey:@"path"];
    
    [self setName:[value lastPathComponent]];
    
    [self didChangeValueForKey:@"path"];
}

+ (NSImage *)makeThumbnailImageFromImageSource:(CGImageSourceRef)imageSource {
    NSImage *result;
    // This code needs to be threadsafe, as it will be called from the background thread.
    // The easiest way to ensure you only use stack variables is to make it a class method.
    NSNumber *maxPixelSize = [NSNumber numberWithInteger:kMaxPixelSize];
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
    
    
    self.thumbnail = data;
    //self.imageVersionInternal = self.imageVersionInternal++;
    isLoadingThumb = NO;
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:kCreateThumbDidFinish object:nil userInfo:nil];
    NSNotification *aNotification = [NSNotification notificationWithName:kCreateThumbDidFinish object:self];
    [[NSNotificationQueue defaultQueue] enqueueNotification:aNotification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
    //NSNotification *aNotification = [NSNotification notificationWithName:kCreateThumbDidFinish object:self];
    //[[NSNotificationCenter defaultCenter] enqueueNotification:aNotification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
}

-(void)loadThumbnailImage
{
    if (isLoadingThumb) {
        return;
    }
    isLoadingThumb = YES;
    /*if (!thumb_queue) {
     thumb_queue //dispatch_queue_create("com.pixite.thumbs", DISPATCH_QUEUE_SERIAL);
     }*/
    if (self.thumbnail == nil) {
        
        
        PIXAppDelegate *appDelegate = (PIXAppDelegate *)[[NSApplication sharedApplication] delegate];
        NSOperationQueue *globalQueue = [appDelegate globalBackgroundSaveQueue];
        
        NSString *aPath = self.path;
        __weak Photo *weakSelf = self;
        [globalQueue addOperationWithBlock:^{
            
            if (weakSelf == nil || aPath==nil) {
                DLog(@"thumbnail operation completed after object was dealloced - return");
                return;
            }
            
            NSLog(@"Loading thumbnail");
            NSImage *image = nil;
            NSURL *urlForImage = [NSURL fileURLWithPath:aPath];
            CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)urlForImage, nil);
            if (imageSource) {
                
                // Now, compute the thumbnail
                image = [[weakSelf class] makeThumbnailImageFromImageSource:imageSource];
                //NSBitmapImageRep *rep = [[image representations] objectAtIndex: 0];
                
                //NSData *data = [rep representationUsingType: NSJPEGFileType properties: nil];
                
                NSData *data = [image TIFFRepresentation];
                
                [weakSelf performSelectorOnMainThread:@selector(mainThreadComputePreviewThumbnailFinished:) withObject:data waitUntilDone:YES];
                
                CFRelease(imageSource);
            }
        }];
        
    }
    
}

@end






@implementation Photo(IKImageBrowserItem)


/*!
 @method imageUID
 @abstract Returns a unique string that identify this data source item (required).
 @discussion The image browser uses this identifier to keep the correspondance between its cache and the data source item
 */
- (NSString *)  imageUID;  /* required */
{
    return self.path;
    //NSString *url_prefix = @"file://localhost";
    // 16 = [url_prefix length]
    
    //NSString *newPath = [self.path substringFromIndex:[url_prefix length]];
    //NSLog(@"newPath = %@", newPath);
    //return newPath;
}

/*!
 @method imageRepresentationType
 @abstract Returns the representation of the image to display (required).
 @discussion Keys for imageRepresentationType are defined below.
 */
- (NSString *) imageRepresentationType; /* required */
{
    return IKImageBrowserNSDataRepresentationType;
    //return IKImageBrowserPathRepresentationType;
    //return IKImageBrowserNSURLRepresentationType;
}

/*!
 @method imageRepresentation
 @abstract Returns the image to display (required). Can return nil if the item has no image to display.
 */
- (id) imageRepresentation; /* required */
{
    if (self.thumbnail == nil) {
        
        //return nil;
        ///NSImage *image = [NSImage imageNamed:@"nophoto"];
        //NSData *data = [image TIFFRepresentation];
        
        
        
        [self performSelector:@selector(loadThumbnailImage) withObject:nil afterDelay:0.0];
        
        //return data;
        
        
        
        //
    } else {
        //NSLog(@"Using cache");
    }
    return self.thumbnail;
    //return [NSURL fileURLWithPath:self.path isDirectory:NO];
}

#pragma mark -
#pragma mark Optional Methods IKImageBrowserItem Informal Protocol

/*!
 @method imageVersion
 @abstract Returns a version of this item. The receiver can return a new version to let the image browser knows that it shouldn't use its cache for this item
 */
- (NSUInteger) imageVersion;
{
    if (self.thumbnail!=nil) {
        return 1;
    }
    return 0;
}

/*!
 @method imageTitle
 @abstract Returns the title to display as a NSString. Use setValue:forKey: with IKImageBrowserCellsTitleAttributesKey on the IKImageBrowserView instance to set text attributes.
 */
- (NSString *) imageTitle;
{
    return [self name];
}

/*!
 @method imageSubtitle
 @abstract Returns the subtitle to display as a NSString. Use setValue:forKey: with IKImageBrowserCellsSubtitleAttributesKey on the IKImageBrowserView instance to set text attributes.
 */
- (NSString *) imageSubtitle;
{
    return [NSString stringWithFormat:@"version %ld", [self imageVersion]];
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
