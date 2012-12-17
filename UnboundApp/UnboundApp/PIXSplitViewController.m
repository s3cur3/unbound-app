//
//  PIXSplitViewController.m
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXSplitViewController.h"
#import "PIXSidebarViewController.h"
#import "PIXImageBrowserViewController.h"

@interface PIXSplitViewController ()

@property (nonatomic, strong) PIXSidebarViewController *sidebarViewController;
@property (nonatomic, strong) PIXImageBrowserViewController *imageBrowserViewController;
@property (nonatomic, strong) NSViewController *mainViewController;

@end

@implementation PIXSplitViewController


- (id)initWithCoder:(NSCoder *)aDecoder;
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        self.sidebarViewController = [[PIXSidebarViewController alloc] initWithNibName:@"PIXSidebarViewController" bundle:nil];
        self.sidebarViewController.splitViewController = self;
        
        self.imageBrowserViewController = [[PIXImageBrowserViewController alloc] initWithNibName:@"PIXImageBrowserViewController" bundle:nil];
    }
    
    return self;
}

-(void)awakeFromNib
{
    [self setupSidebar];
    [self setupBrowser];
}

-(void)setNavigationViewController:(PIXNavigationController *)navigationViewController
{
    [super setNavigationViewController:navigationViewController];
    self.sidebarViewController.navigationViewController = self.navigationViewController;
    self.imageBrowserViewController.navigationViewController = self.navigationViewController;
}

-(void)setupSidebar
{
    NSAssert(self.selectedAlbum, @"SplitViewController requires an album to be set");
    [self.sidebarViewController.view setFrame:self.leftPane.bounds];
    [self.leftPane addSubview:self.sidebarViewController.view];
    [self.sidebarViewController.outlineView reloadData];
}

-(void)setupBrowser
{
    NSAssert(self.selectedAlbum, @"SplitViewController requires an album to be set");
    self.imageBrowserViewController.album = self.selectedAlbum;
    [self.imageBrowserViewController.view setFrame:self.rightPane.bounds];
    [self.rightPane addSubview:self.imageBrowserViewController.view];
}

-(void)setSelectedAlbum:(Album *)selectedAlbum
{
    if (!selectedAlbum) {
        NSAssert(selectedAlbum!=nil, @"SplitViewController setAlbum called with nil value");
    }
    _selectedAlbum = selectedAlbum;
    [self.imageBrowserViewController setAlbum:self.selectedAlbum];
}

-(void)dealloc
{
    DLog(@"dealloc of splitview");
}

@end
