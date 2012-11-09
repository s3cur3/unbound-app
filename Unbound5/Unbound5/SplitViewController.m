//
//  SplitViewController.m
//  Unbound
//
//  Created by Bob on 11/7/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "SplitViewController.h"
#import "Album.h"
#import "ImageBrowserViewController.h"
#import "SidebarViewController.h"
#import "PINavigationViewController.h"

@interface SplitViewController ()

@end

@implementation SplitViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil albums:(NSArray *)newAlbums selectedAlbum:(Album *)aSelectedAlbum
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        self.imageBrowserViewController = [[ImageBrowserViewController alloc] initWithNibName:@"ImageBrowserViewController" bundle:nil album:aSelectedAlbum];
        self.albums = newAlbums;
        self.selectedAlbum = aSelectedAlbum;
        
        self.sidebarViewController = [[SidebarViewController alloc] initWithNibName:@"SidebarViewController" bundle:nil];
        self.sidebarViewController.splitViewController = self;
        
        self.sidebarViewController.mainWindow = (MainWindowController *) [[[NSApplication sharedApplication] mainWindow] delegate];
    }
    
    return self;
}

-(void)awakeFromNib
{
    self.sidebarViewController.selectedAlbum = self.selectedAlbum;
    self.sidebarViewController.directoryArray = [self.albums mutableCopy];
    
    [self.sidebarViewController.view setFrame:self.leftPane.bounds];
    [self.leftPane addSubview:self.sidebarViewController.view];
    [self.sidebarViewController.outlineView reloadData];
    
    self.imageBrowserViewController.album = self.selectedAlbum;
    [self.imageBrowserViewController.view setFrame:self.rightPane.bounds];
    [self.rightPane addSubview:self.imageBrowserViewController.view];
    //self.rightPane = self.imageBrowserViewController.browserView;
    [self.imageBrowserViewController.browserView reloadData];
}

-(void)setNavigationViewController:(PINavigationViewController *)newNavigationViewController
{
    super.navigationViewController = newNavigationViewController;
    self.imageBrowserViewController.navigationViewController = newNavigationViewController;
}


@end
