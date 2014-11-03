//
//  PIXPhoto.h
//  UnboundApp
//
//  Created by Bob on 1/8/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#ifdef USE_OLD_MAPS
#import "MapKit.h"
#else
#import <MapKit/MapKit.h>
#endif

#import "PIXThumbnailLoadingDelegate.h"

@class QTMovie;

@class PIXAlbum, PIXThumbnail;
@class MakeThumbnailOperation;

@interface PIXPhoto : NSManagedObject <PIXThumbnailLoadingDelegate, MKAnnotation>
{
    BOOL                        _thumbnailImageIsLoading;
    BOOL                        _fullsizeImageIsLoading;
}

@property (nonatomic, retain) NSDate * dateLastModified;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateLastUpdated;
@property (nonatomic, retain) NSDate * dateTaken;
@property (nonatomic, retain) NSDate * sortDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSString * caption;
@property (nonatomic, retain) PIXAlbum *album;
@property (nonatomic, retain) PIXAlbum *datePhotoAlbum;
@property (atomic, retain) PIXAlbum *stackPhotoAlbum;
@property (atomic, retain) NSDictionary * exifData;
@property (atomic, retain) NSNumber * fileSize;

@property (atomic, copy) NSString * thumbnailFilePath;

@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;

@property (atomic, strong) NSImage *thumbnailImage;
@property (atomic, assign, readwrite) BOOL cancelThumbnailLoadOperation;

@property (atomic, strong) NSImage *fullsizeImage;
@property (atomic, assign, readwrite) BOOL cancelFullsizeLoadOperation;

@property (atomic) BOOL isReallyDeleted;

//TODO: get rid of this
-(NSURL *)filePath;

//PIXThumbnailLoadingDelegate methods
-(NSImage *)thumbnailImage;
// if this is a faster thumb load image (for the top images in album stacks, so they load at a higher priority)
-(NSImage *)thumbnailImageFast;
-(void)cancelThumbnailLoading;

-(void)clearFiles;

//Image pre-loading from disk methods
-(NSImage *)fullsizeImage;
-(NSImage *)fullsizeImageStartLoadingIfNeeded:(BOOL)shouldLoad;
-(NSImage *)fullsizeImageForFullscreenDisplay;

-(void)cancelFullsizeLoading;

-(NSDate *)findDisplayDate;

-(void)findExifData;

-(void)postPhotoUpdatedNote;

-(void)userSetCaption:(NSString *)userCaption;

-(BOOL)isVideo;

-(QTMovie *)videoFile;
-(NSDictionary *)videoAttributes;

@end

#pragma mark Required Methods IKImageBrowserItem Informal Protocol
/*!
 @category NSObject (IKImageBrowserItem)
 @abstract The IKImageBrowserItem informal protocol declares the methods that an instance of IKImageBrowserView uses to access the contents of its data source for a given item.
 @discussion Some of the methods in this protocol, such as <i>image</i> are called very frequently, so they must be efficient.
 */
@interface PIXPhoto (IKImageBrowserItem)

/*!
 @method imageUID
 @abstract Returns a unique string that identify this data source item (required).
 @discussion The image browser uses this identifier to keep the correspondance between its cache and the data source item
 */
- (NSString *)  imageUID;  /* required */

/*!
 @method imageRepresentationType
 @abstract Returns the representation of the image to display (required).
 @discussion Keys for imageRepresentationType are defined below.
 */
- (NSString *) imageRepresentationType; /* required */

/*!
 @method imageRepresentation
 @abstract Returns the image to display (required). Can return nil if the item has no image to display.
 */
- (id) imageRepresentation; /* required */

#pragma mark -
#pragma mark Optional Methods IKImageBrowserItem Informal Protocol

/*!
 @method imageVersion
 @abstract Returns a version of this item. The receiver can return a new version to let the image browser knows that it shouldn't use its cache for this item
 */
- (NSUInteger) imageVersion;

/*!
 @method imageTitle
 @abstract Returns the title to display as a NSString. Use setValue:forKey: with IKImageBrowserCellsTitleAttributesKey on the IKImageBrowserView instance to set text attributes.
 */
- (NSString *) imageTitle;

/*!
 @method imageSubtitle
 @abstract Returns the subtitle to display as a NSString. Use setValue:forKey: with IKImageBrowserCellsSubtitleAttributesKey on the IKImageBrowserView instance to set text attributes.
 */
- (NSString *) imageSubtitle;

/*!
 @method isSelectable
 @abstract Returns whether this item is selectable.
 @discussion The receiver can implement this methods to forbid selection of this item by returning NO.
 */
- (BOOL) isSelectable;



@end
