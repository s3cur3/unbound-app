//
//  PIXAlbumCollectionViewItem.h
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PIXBorderedImageView;

@interface PIXAlbumCollectionViewItem : NSCollectionViewItem

@property (weak) IBOutlet NSTextField *mainLabel;
@property (strong) IBOutlet NSTextField * detailLabel;
@property (strong) IBOutlet PIXBorderedImageView * albumImageView;

@property (strong) IBOutlet PIXBorderedImageView * stackPhoto1;
@property (strong) IBOutlet PIXBorderedImageView * stackPhoto2;
@property (strong) IBOutlet PIXBorderedImageView * stackPhoto3;

- (void)doubleClick:(id)sender;

@end
