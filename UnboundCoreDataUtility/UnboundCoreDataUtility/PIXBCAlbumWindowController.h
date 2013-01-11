//
//  PIXBCAlbumWindowController.h
//  UnboundCoreDataUtility
//
//  Created by Bob on 1/10/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PIXBCCollectionViewController;

@interface PIXBCAlbumWindowController : NSWindowController

@property (nonatomic, strong) PIXBCCollectionViewController *albumViewController;

@end
