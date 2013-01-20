//
//  PIXAlbumGridViewItem.h
//  UnboundApp
//
//  Created by Scott Sykora on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CNGridViewItem.h"

@class PIXAlbum, PIXBorderedImageView;

@interface PIXAlbumGridViewItem : CNGridViewItem

@property (strong, nonatomic) PIXAlbum * album;

@property (strong, nonatomic) IBOutlet NSTextField *mainLabel;
@property (strong, nonatomic) IBOutlet NSTextField * detailLabel;
@property (strong, nonatomic) IBOutlet PIXBorderedImageView * albumImageView;

@property (strong, nonatomic) IBOutlet PIXBorderedImageView * stackPhoto1;
@property (strong, nonatomic) IBOutlet PIXBorderedImageView * stackPhoto2;
@property (strong, nonatomic) IBOutlet PIXBorderedImageView * stackPhoto3;

@end
