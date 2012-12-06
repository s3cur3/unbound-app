//
//  CollectionViewItem.h
//  Unbound
//
//  Created by Bob on 11/6/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BorderedImageView;

@interface CollectionViewItem : NSCollectionViewItem
{
    
}
@property (weak) IBOutlet NSTextField *mainLabel;

- (void)doubleClick:(id)sender;

@property (strong) IBOutlet NSTextField * detailLabel;
@property (strong) IBOutlet BorderedImageView * albumImageView;

@property (strong) IBOutlet BorderedImageView * stackPhoto1;
@property (strong) IBOutlet BorderedImageView * stackPhoto2;
@property (strong) IBOutlet BorderedImageView * stackPhoto3;


@end
