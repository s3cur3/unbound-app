//
//  PIXAlbumGridViewItem.h
//  UnboundApp
//
//  Created by Scott Sykora on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PIXGridViewItem.h"

@class PIXAlbum, PIXBorderedImageView;

@interface PIXAlbumGridViewItem : PIXGridViewItem

@property (strong, nonatomic) PIXAlbum * album;



// this is used when dragging an array of albums out of the album view
+ (NSImage *)dragImageForAlbums:(NSArray *)albumArray size:(NSSize)size;

-(void)startEditing;

@end
