//
//  PIXMainWindowController.h
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Unbound-Swift.h"

@class PIXAlbumViewController;
@class PIXViewController;

@class PIXAlbumGridViewController;
@class PIXAlbumCollectionViewController;

@interface PIXMainWindowController : NSWindowController
{
    
}

@property (nonatomic, strong) IBOutlet NavigationController *navigationViewController;
//@property (nonatomic, strong) PIXAlbumGridViewController *albumViewController;
@property (nonatomic, strong) PIXAlbumCollectionViewController * albumViewController;

@end
