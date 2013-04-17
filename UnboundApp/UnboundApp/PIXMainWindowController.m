//
//  PIXMainWindowController.m
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXMainWindowController.h"
#import "PIXNavigationController.h"
#import "PIXAlbumGridViewController.h"
#import "PIXDefines.h"
#import "PIXAppDelegate.h"


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
    
    //        [self openAlert:@"Root Folder Unavailable"
    //            withMessage:@"The folder specified for your photos is unavailable. Would you like to change the root folder in your preferences?"];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kAppObservedDirectoryUnavailable])
    {
        __weak id weakDelegate = [PIXAppDelegate sharedAppDelegate];
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [(PIXAppDelegate *)weakDelegate openAlert:@"Root Folder Unavailable"
                    withMessage:kRootFolderUnavailableDetailMessage];
        });
        
    }
    
    //[self.navigationViewController.view setWantsLayer:YES];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    self.albumViewController = [[PIXAlbumGridViewController alloc] initWithNibName:@"PIXGridViewController" bundle:nil];
    
    [self.albumViewController view];

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
