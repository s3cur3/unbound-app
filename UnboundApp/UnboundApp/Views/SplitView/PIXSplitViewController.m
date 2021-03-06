//
//  PIXSplitViewController.m
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXSplitViewController.h"
#import "PIXSidebarViewController.h"
#import "PIXAppDelegate.h"
#import "Unbound-Swift.h"
#import "PIXCustomShareSheetViewController.h"
#import "PIXShareManager.h"
#import "PIXFileManager.h"
#import "PIXDefines.h"
#import "PIXPhotoCollectionViewController.h"
#import "PIXCollectionView.h"
#import "Unbound-Swift.h"

@interface PIXSplitViewController ()

@property (nonatomic, strong) NSToolbarItem * backButtonSegmentItem;
@property (nonatomic, strong) NSToolbarItem * sliderItem;
@property (nonatomic, strong) NSToolbarItem * sortButton;

@property float lastSplitviewWidth;
@property BOOL gridWasLastResponder;

@end

@implementation PIXSplitViewController


- (id)initWithCoder:(NSCoder *)aDecoder
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
        self.imageBrowserViewController.splitViewController = self;
        self.imageBrowserViewController = [[PIXPhotoCollectionViewController alloc] initWithNibName:@"PIXPhotoCollectionViewController" bundle:nil];
        
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
    [self.sidebarViewController.outlineView setNextKeyView:self.imageBrowserViewController.collectionView];
    [self.imageBrowserViewController.scrollView setNextKeyView:self.sidebarViewController.searchField];
    [self.sidebarViewController.searchField setNextKeyView:self.sidebarViewController.outlineView];
    
    [self.sidebarViewController.view setNextResponder:self];
//    [self setNextResponder:self.view];
    
    [self.imageBrowserViewController setThumbSize:self.sizeSlider.floatValue];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if([self.splitView isSubviewCollapsed:self.leftPane] || self.gridWasLastResponder)
        {
            [self.view.window makeFirstResponder:self.imageBrowserViewController.collectionView];
        }
        
        else
        {
            [self.view.window makeFirstResponder:self.sidebarViewController.outlineView];
        }
        
        
    });
    
    [[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] setTitle:[self.selectedAlbum title]];


    [self.backButtonSegment setSelected:NO forSegment:0];

    // set the toggle to the correct view
    [self.backButtonSegment setSelected:![self.splitView isSubviewCollapsed:self.leftPane]
                             forSegment:1];

    self.navigationViewController.showBackButton = false;
    self.navigationViewController.leftToolbarItems = @[self.backButtonSegmentItem];
    self.navigationViewController.rightToolbarItems = @[self.sliderItem, self.sortButton];
}


-(void)willHidePIXView
{
    if([self.imageBrowserViewController.collectionView isFirstResponder])
    {
        self.gridWasLastResponder = YES;
    }
    
    else
    {
        self.gridWasLastResponder = NO;
    }
    
    [self.sidebarViewController willHidePIXView];
    [self.imageBrowserViewController willHidePIXView];
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context {
    if (object == self.imageBrowserViewController && [@"title" isEqualToString:keyPath]) {
        self.title = ((NSViewController *) object).title;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSToolbarItem *)sliderItem
{
    if(_sliderItem!= nil) return _sliderItem;
    
    _sliderItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"sliderItem"];
    
    
    
    _sliderItem.view = self.sizeSlider;
    
    [_sliderItem setLabel:@"Adjust Thumb Size"];
    [_sliderItem setPaletteLabel:@"Adjust Thumb Size"];
    
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_sliderItem setToolTip:@"Adjust Thumb Size"];
    
    return _sliderItem;
}

-(IBAction)sliderValueChanged:(id)sender
{
    [self.imageBrowserViewController setThumbSize:self.sizeSlider.floatValue];
}

- (NSToolbarItem *)sortButton
{
    if(_sortButton == nil) {
        _sortButton = [ToolbarButton makePhotoSortWithTarget:self selector:@selector(sortChanged:)];
    }
    return _sortButton;
}

-(void)sortChanged:(id)sender
{
    // this should only be called from the men
    if([sender isKindOfClass:[NSMenuItem class]])
    {
        NSArray * menuItems = [(NSPopUpButton *)self.sortButton.view itemArray];
        for(NSMenuItem * anItem in menuItems) {
            [anItem setState:NSOffState];
        }

        NSMenuItem * thisItem = sender;
        [thisItem setState:NSControlStateValueOn];
        [[NSUserDefaults standardUserDefaults] setInteger:[thisItem tag] forKey:kPrefPhotoSortOrder];
        [NSUserDefaults.standardUserDefaults synchronize];
        
        // update any albums views
        [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
    }
}

- (NSToolbarItem *)backButtonSegmentItem
{
    if(_backButtonSegmentItem != nil) return _backButtonSegmentItem;
    
    _backButtonSegmentItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"backButtonAndSideBarToggle"];
        
    [self.backButtonSegment setSelected:![self.splitView isSubviewCollapsed:self.leftPane]
                             forSegment:1];
    
    CGRect frame = self.backButtonSegment.frame;
    frame.size.height = 25;
    self.backButtonSegment.frame = frame;

    
    _backButtonSegmentItem.view = self.backButtonSegment;
    
    [_backButtonSegmentItem setLabel:@"Back"];
    [_backButtonSegmentItem setPaletteLabel:@"Back"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_backButtonSegmentItem setToolTip:@"Back to Albums"];
    
    return _backButtonSegmentItem;
}

-(void)popViewAndUpdateAlbumSelectionForDelegate
{
    NSInteger index = self.sidebarViewController.outlineView.selectedRow;
    [self.delegate albumSelected:self.selectedAlbum atIndex:index];
    [self.navigationViewController popViewController];
}

-(IBAction)backBarSegmentChanged:(id)sender
{
    if([sender selectedSegment] == 0)
    {
        [self popViewAndUpdateAlbumSelectionForDelegate];
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
        
    // open the sidebar
    if([self.splitView isSubviewCollapsed:self.leftPane])
    {
        float lastPosition = [[NSUserDefaults standardUserDefaults] floatForKey:@"albumSideBarToggleWidth"];
        
        // set this to 300 so if a mouse closes it will re-open to that
        [[NSUserDefaults standardUserDefaults] setFloat:300 forKey:@"albumSideBarToggleWidth"];
        
        [self.splitView setPosition:lastPosition ofDividerAtIndex:0];
        
    
        [self.view.window makeFirstResponder:self.sidebarViewController.outlineView];
        
    }
    
    // close the sidebar
    else
    {
        float currentPosition = (float)self.leftPane.frame.size.width;
        [[NSUserDefaults standardUserDefaults] setFloat:currentPosition forKey:@"albumSideBarToggleWidth"];
        [self.splitView setPosition:0 ofDividerAtIndex:0];
        
        [self.view.window makeFirstResponder:self.imageBrowserViewController.collectionView];
    }
    
    
    [self.splitView adjustSubviews];
    [self.navigationViewController.mainWindow enableFlushWindow];
    
    
}

-(void)setNavigationViewController:(NavigationController *)navigationViewController
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
    [self.imageBrowserViewController.view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
}


-(void)setSelectedAlbum:(id)selectedAlbum
{
    if (!selectedAlbum) {
        NSAssert(selectedAlbum!=nil, @"SplitViewController setAlbum called with nil value");
    } else if (selectedAlbum == _selectedAlbum) {
        // DLog(@"Same album selected, skip reloading");
        return;
    }
    _selectedAlbum = selectedAlbum;
    [self.imageBrowserViewController setAlbum:self.selectedAlbum];
    [[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] setTitle:[self.selectedAlbum title]];
    
    [[PIXAppDelegate sharedAppDelegate] setCurrentlySelectedAlbum:self.selectedAlbum];

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

- (void)setImageBrowserViewController:(PIXPhotoCollectionViewController *)imageBrowserViewController {
    if (_imageBrowserViewController != nil) {
        [_imageBrowserViewController removeObserver:self forKeyPath:@"title"];
    }
    _imageBrowserViewController = imageBrowserViewController;
    self.title = imageBrowserViewController.title;
    [self.imageBrowserViewController addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
}

-(void)dealloc {
    if (self.imageBrowserViewController != nil) {
        [self.imageBrowserViewController removeObserver:self forKeyPath:@"title"];
    }
}

@end
