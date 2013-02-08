//
//  PIXSplitViewController.m
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXSplitViewController.h"
#import "PIXSidebarViewController.h"
//#import "PIXImageBrowserViewController.h"
#import "PIXPhotoGridViewController.h"
#import "PIXNavigationController.h"

@interface PIXSplitViewController ()

@property (nonatomic, strong) PIXSidebarViewController *sidebarViewController;
@property (nonatomic, strong) PIXPhotoGridViewController *imageBrowserViewController;
@property (nonatomic, strong) NSViewController *mainViewController;

@property (nonatomic, strong) NSToolbarItem * backButtonSegmentItem;
@property float lastSplitviewWidth;

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
        
        self.imageBrowserViewController = [[PIXPhotoGridViewController alloc] initWithNibName:@"PIXGridViewController" bundle:nil];
        
        [self.splitView adjustSubviews];
    }
    
    return self;
}

-(void)awakeFromNib
{
    [self setupSidebar];
    [self setupBrowser];
}

-(void)willShowPIXView
{
    [self.sidebarViewController willShowPIXView];
    [self.imageBrowserViewController willShowPIXView];
}

-(void)willHidePIXView
{
    [self.sidebarViewController willHidePIXView];
    [self.imageBrowserViewController willHidePIXView];
}

-(void)setupToolbar
{
    
    [self.backButtonSegment setSelected:NO forSegment:0];
    
    // set the toggle to the correct view
    [self.backButtonSegment setSelected:![self.splitView isSubviewCollapsed:self.leftPane]
                             forSegment:1];
    

    NSArray * items = @[self.backButtonSegmentItem];
    
    [self.navigationViewController setToolbarItems:items];
    
}

- (NSToolbarItem *)backButtonSegmentItem
{
    if(_backButtonSegmentItem != nil) return _backButtonSegmentItem;
    
    _backButtonSegmentItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"backButtonAndSideBarToggle"];
        
    [self.backButtonSegment setSelected:![self.splitView isSubviewCollapsed:self.leftPane]
                             forSegment:1];

    
    _backButtonSegmentItem.view = self.backButtonSegment;
    
    [_backButtonSegmentItem setLabel:@"Back"];
    [_backButtonSegmentItem setPaletteLabel:@"Back"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_backButtonSegmentItem setToolTip:@"Back to Albums"];
    
    return _backButtonSegmentItem;
}


-(IBAction)backBarSegmentChanged:(id)sender
{
    if([sender selectedSegment] == 0)
    {
        [self.navigationViewController popViewController];
    }
    
    if([sender selectedSegment] == 1)
    {
        [self toggleSidebar];
        
        // set the toggle to the correct view
        [self.backButtonSegment setSelected:![self.splitView isSubviewCollapsed:self.leftPane]
                                 forSegment:1];
    }
}

-(void)toggleSidebar
{
    // disable window flushing to keep views from rendering half way
    [self.navigationViewController.mainWindow disableFlushWindow];
        
    
    if([self.splitView isSubviewCollapsed:self.leftPane])
    {
        float lastPosition = [[NSUserDefaults standardUserDefaults] floatForKey:@"albumSideBarToggleWidth"];
        
        // set this to 300 so if a mouse closes it will re-open to that
        [[NSUserDefaults standardUserDefaults] setFloat:300 forKey:@"albumSideBarToggleWidth"];
        
        [self.splitView setPosition:lastPosition ofDividerAtIndex:0];
        
    }
    
    else
    {
        float currentPosition = self.leftPane.frame.size.width;
        [[NSUserDefaults standardUserDefaults] setFloat:currentPosition forKey:@"albumSideBarToggleWidth"];
        [self.splitView setPosition:0 ofDividerAtIndex:0];
    }
    
    
    [self.splitView adjustSubviews];
    [self.navigationViewController.mainWindow enableFlushWindow];
    
    
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


-(void)setSelectedAlbum:(id)selectedAlbum
{
    if (!selectedAlbum) {
        NSAssert(selectedAlbum!=nil, @"SplitViewController setAlbum called with nil value");
    } else if (selectedAlbum == _selectedAlbum) {
        DLog(@"Same album selected, skip reloading");
        return;
    }
    _selectedAlbum = selectedAlbum;
    [self.imageBrowserViewController setAlbum:self.selectedAlbum];
}



- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    if(subview == self.leftPane) return YES;
    
    return NO;
}


- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
    return YES;
}



- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
{
    [self.backButtonSegment setSelected:![self.splitView isSubviewCollapsed:self.leftPane] forSegment:1];
    
    return YES;
}

-(void)dealloc
{
    DLog(@"dealloc of splitview");
}

@end
