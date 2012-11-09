//
//  SplitViewController.h
//  Unbound
//
//  Created by Bob on 11/7/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIViewController.h"

@class Album;
@class ImageBrowserViewController;
@class SidebarViewController;

@interface SplitViewController : PIViewController
{
    
}

@property (strong) IBOutlet NSSplitView *splitView;
@property (strong) IBOutlet NSView *leftPane;
@property (strong) IBOutlet NSView *rightPane;
@property (strong) IBOutlet ImageBrowserViewController *imageBrowserViewController;
@property (strong) IBOutlet SidebarViewController *sidebarViewController;

@property (strong, nonatomic) Album *selectedAlbum;
@property (strong, nonatomic) NSArray *albums;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil albums:(NSArray *)newAlbums selectedAlbum:(Album *)aSelectedAlbum;

@end
