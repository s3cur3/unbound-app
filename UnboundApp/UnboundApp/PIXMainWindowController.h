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

@interface PIXMainWindowController : NSWindowController
{
    
}

@property (nonatomic, strong) IBOutlet PIXNavigationController *navigationViewController;
@property (nonatomic, strong) PIXAlbumViewController *albumViewController;

@end
