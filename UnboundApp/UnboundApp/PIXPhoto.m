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


@implementation PIXPhoto

@dynamic dateLastModified;
@dynamic dateLastUpdated;
@dynamic name;
@dynamic path;
@dynamic album;
@dynamic thumbnail;

//TODO: get rid of this
-(NSURL *)filePath;
{
    return [NSURL fileURLWithPath:self.path isDirectory:NO];
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
    return @"";
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
