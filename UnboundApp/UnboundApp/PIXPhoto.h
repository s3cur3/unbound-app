//
//  PIXPhoto.h
//  UnboundApp
//
//  Created by Bob on 1/8/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PIXAlbum, PIXThumbnail;
@class MakeThumbnailOperation;

@interface PIXPhoto : NSManagedObject
{
    NSImage *                   _thumbnailImage;
    BOOL                        _thumbnailImageIsLoading;
}

@property (nonatomic, retain) NSDate * dateLastModified;
@property (nonatomic, retain) NSDate * dateLastUpdated;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) PIXAlbum *album;
@property (nonatomic, retain) PIXAlbum *coverPhotoAlbum;
@property (nonatomic, retain) PIXThumbnail *thumbnail;


@property (nonatomic, retain, readonly ) NSImage *thumbnailImage;         // observable, returns a placeholder if the thumbnail isn't available yet.
@property (nonatomic, assign, readwrite) BOOL cancelThumbnailLoadOperation;

//TODO: get rid of this
-(NSURL *)filePath;



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
