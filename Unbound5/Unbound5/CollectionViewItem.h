//
//  CollectionViewItem.h
//  Unbound
//
//  Created by Bob on 11/6/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CollectionViewItem : NSCollectionViewItem
{
    
}

- (void)doubleClick:(id)sender;

@property (strong) IBOutlet NSTextField * detailLabel;
@property (strong) IBOutlet NSImageView * albumImageView;
@property (strong, nonatomic) CALayer * borderLayer;

@end
