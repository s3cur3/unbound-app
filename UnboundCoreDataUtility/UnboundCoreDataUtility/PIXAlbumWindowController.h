//
//  PIXAlbumWindowController.h
//  UnboundCoreDataUtility
//
//  Created by Bob on 1/7/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PIXAlbumViewController;
@class BCCollectionView;

@interface PIXAlbumWindowController : NSWindowController

@property (nonatomic, strong) PIXAlbumViewController *albumViewController;

@end
