//
//  PIXMainWindowController.h
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PIXAlbumViewController;
@class PIXNavigationController;
@class PIXViewController;

//@class PIXBCAlbumViewController;

@interface PIXMainWindowController : NSWindowController
{
    
}

@property (nonatomic, strong) IBOutlet PIXNavigationController *navigationViewController;
@property (nonatomic, strong) PIXViewController *albumViewController;
//@property (nonatomic, strong) PIXAlbumViewController *albumViewController;
//@property (nonatomic, strong) PIXBCAlbumViewController *albumViewController;

@end
