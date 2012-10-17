//
//  Photo.m
//  Unbound5
//
//  Created by Bob on 10/16/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "Photo.h"
#import <Quartz/Quartz.h>

NSString *PhotoDidChangeNotification = @"PhotoDidChangeNotification";

@interface Photo()
{
}

@property (nonatomic, strong) NSURL *filePath;

@end

@implementation Photo

-(id)initWithURL:(NSURL *)filePathURL;
{
    self = [super init];
    if (self) {
        self.filePath = filePathURL;
    }
    return self;
}

-(id)initWithMetadataItem:(NSMetadataItem *)metadataItem;
{
    NSString *aPath = [metadataItem valueForAttribute:(NSString *)kMDItemPath];
    NSURL *aFilePathURL = [NSURL fileURLWithPath:aPath];
    NSAssert(aFilePathURL, @"Photo init called with bad metadataItem");
    return [self initWithURL:aFilePathURL];
}

-(void)dumpAttributesToLog;
{
    DLog(@"%@", self.filePath);
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
    return self.filePath.path;
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
    return self.filePath;
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
    return [self.filePath.path lastPathComponent];
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