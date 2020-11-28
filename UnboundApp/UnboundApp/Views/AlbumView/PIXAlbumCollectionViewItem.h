//
//  PIXAlbumCollectionViewItem.h
//  UnboundApp
//
//  Created by Ditriol Wei on 3/8/16.
//  Copyright © 2016 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PIXCollectionViewItem.h"

/**
 * An album in the album overview collection. Represented as a cover photo with a "stack" of photos beneath.
 */
@interface PIXAlbumCollectionViewItem : PIXCollectionViewItem
@end


@class PIXAlbum;
@interface PIXAlbumCollectionViewItemView : PIXCollectionViewItemView

@property (strong, nonatomic) PIXAlbum * album;

// this is used when dragging an array of albums out of the album view
+ (NSImage *)dragImageForAlbums:(NSArray *)albumArray size:(NSSize)size;
- (void)startEditing;

@end
