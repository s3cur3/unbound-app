//
//  PIXMainWindowController.m
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXMainWindowController.h"
#import "PIXNavigationController.h"
#import "PIXAlbumViewController.h"

#import "PIXAlbumGridViewController.h"

@interface PIXMainWindowController ()

@end

@implementation PIXMainWindowController

-(id)initWithWindowNibName:(NSString *)nibName
{
    self = [super initWithWindowNibName:nibName];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

//- (void)windowDidLoad
//{
//    [super windowDidLoad];
//    
//    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
//    self.albumViewController = [[PIXAlbumViewController alloc] initWithNibName:@"PIXAlbumViewController" bundle:nil];
//    [self.navigationViewController pushViewController:self.albumViewController];
//}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    self.albumViewController = [[PIXAlbumGridViewController alloc] initWithNibName:@"PIXAlbumGridViewController" bundle:nil];
    [self.navigationViewController pushViewController:self.albumViewController];
}

//- (void)windowDidLoad
//{
//    [super windowDidLoad];
//    
//    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
//    self.albumViewController = [[PIXBCAlbumViewController alloc] initWithNibName:@"PIXBCAlbumViewController" bundle:nil];
//    [self.navigationViewController pushViewController:self.albumViewController];
//}

@end
