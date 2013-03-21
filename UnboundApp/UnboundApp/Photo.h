//
//  Photo.h
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXObject.h"
#import <MapKit/MapKit.h>

@class Album;

@interface Photo : PIXObject <MKAnnotation>


@property (nonatomic, strong) NSDate *dateLastModified;
@property (nonatomic, strong) NSURL *filePath;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, weak) Album *album;

-(id)initWithURL:(NSURL *)filePathURL;

@end

#pragma mark Required Methods IKImageBrowserItem Informal Protocol
/*!
 @category NSObject (IKImageBrowserItem)
 @abstract The IKImageBrowserItem informal protocol declares the methods that an instance of IKImageBrowserView uses to access the contents of its data source for a given item.
 @discussion Some of the methods in this protocol, such as <i>image</i> are called very frequently, so they must be efficient.
 */
@interface Photo (IKImageBrowserItem)

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
