//
//  PIXSplitViewController.m
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXSplitViewController.h"
#import "PIXSidebarViewController.h"
#import "PIXNavigationController.h"
#import "PIXAppDelegate.h"
#import "PIXMainWindowController.h"
#import "PIXCustomShareSheetViewController.h"
#import "PIXShareManager.h"
#import "PIXFileManager.h"
#import "PIXDefines.h"
#import "PIXPhotoCollectionViewController.h"
#import "PIXCollectionView.h"

@interface PIXSplitViewController ()


@property (nonatomic, strong) NSViewController *mainViewController;

@property (nonatomic, strong) NSToolbarItem * backButtonSegmentItem;
@property (nonatomic, strong) NSToolbarItem * sliderItem;
@property (nonatomic, strong) NSToolbarItem * shareItem;
@property (nonatomic, strong) NSToolbarItem * importItem;
@property (nonatomic, strong) NSToolbarItem * deleteAlbumItem;
@property (nonatomic, strong) NSToolbarItem * sortButton;

@property float lastSplitviewWidth;
@property BOOL gridWasLastResponder;

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
        
#ifndef USE_NSCOLLECTIONVIEW
        self.imageBrowserViewController = [[PIXPhotoGridViewController alloc] initWithNibName:@"PIXGridViewController" bundle:nil];
#else
        self.imageBrowserViewController = [[PIXPhotoCollectionViewController alloc] initWithNibName:@"PIXPhotoCollectionViewController" bundle:nil];
#endif
        self.imageBrowserViewController.splitViewController = self;
        
        
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

-(void)setupToolbar
{
    [self.backButtonSegment setSelected:NO forSegment:0];
    
    // set the toggle to the correct view
    [self.backButtonSegment setSelected:![self.splitView isSubviewCollapsed:self.leftPane]
                             forSegment:1];
    
    NSArray * items = @[self.backButtonSegmentItem, self.importItem, self.navigationViewController.activityIndicator, self.navigationViewController.middleSpacer, self.sliderItem, self.deleteAlbumItem, self.sortButton];
    
    [self.navigationViewController setNavBarHidden:NO];
    [self.navigationViewController setToolbarItems:items];
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
    if(_sortButton != nil) return _sortButton;
    
    _sortButton = [[NSToolbarItem alloc] initWithItemIdentifier:@"sortButton"];
    //_settingsButton.image = [NSImage imageNamed:NSImageNameSmartBadgeTemplate];
    
    NSPopUpButton * buttonView = [[NSPopUpButton alloc] initWithFrame:CGRectMake(0, 0, 25, 25) pullsDown:YES];
    
    [buttonView setImagePosition:NSImageOverlaps];
    [buttonView setBordered:YES];
    [buttonView setBezelStyle:NSTexturedSquareBezelStyle];
    [buttonView setTitle:@""];
    [(NSPopUpButtonCell *) buttonView.cell setArrowPosition:NSPopUpNoArrow];
    
    _sortButton.view = buttonView;
    
    [_sortButton setLabel:@"Sort Photos"];
    [_sortButton setPaletteLabel:@"Sort Photos"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_sortButton setToolTip:@"Choose Photo Sort"];
    
    
    // Tell the item what message to send when it is clicked
    
    [buttonView insertItemWithTitle:@"" atIndex:0]; // first index is always the title
    [buttonView insertItemWithTitle:@"New to Old" atIndex:1];
    [buttonView insertItemWithTitle:@"Old to New" atIndex:2];
    [buttonView insertItemWithTitle:@"Filename A to Z" atIndex:3];
    [buttonView insertItemWithTitle:@"Filename Z to A" atIndex:4];
    
    NSMenuItem * item = [[buttonView itemArray] objectAtIndex:0];
    item.image = [NSImage imageNamed:@"sortbutton"];
    [item.image setTemplate:YES];
    
    
    int sortOrder = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"PIXPhotoSort"];
    
    for (int i = 1; i <= 4; i++) {
        
        NSMenuItem * item = [[buttonView itemArray] objectAtIndex:i];
        
        if(i-1 == sortOrder)
        {
            [item setState:NSOnState];
        }
        
        [item setTag:i-1];
        [item setTarget:self];
        [item setAction:@selector(sortChanged:)];
        
    }
    
    return _sortButton;
    
}



-(void)sortChanged:(id)sender
{
    // this should only be called from the men
    if([sender isKindOfClass:[NSMenuItem class]])
    {
        NSArray * menuItems = [(NSPopUpButton *)self.sortButton.view itemArray];
        
        for(NSMenuItem * anItem in menuItems)
        {
            [anItem setState:NSOffState];
        }
        
        
        NSMenuItem * thisItem = sender;
        [thisItem setState:NSOnState];
        [[NSUserDefaults standardUserDefaults] setInteger:[thisItem tag] forKey:@"PIXPhotoSort"];
        
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

- (NSToolbarItem *)shareItem
{
    if(_shareItem != nil) return _shareItem;
    
    _shareItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"shareAlbumButton"];
    //_settingsButton.image = [NSImage imageNamed:NSImageNameSmartBadgeTemplate];
    
    NSButton * buttonView = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 110, 25)];

    [buttonView setImage:[NSImage imageNamed:NSImageNameShareTemplate]];
    [buttonView setImagePosition:NSImageLeft];
    [buttonView setBordered:YES];
    [buttonView setBezelStyle:NSTexturedSquareBezelStyle];
    [buttonView setTitle:@"Share Album"];
        
    _shareItem.view = buttonView;
    
    [_shareItem setLabel:@"Share Album"];
    [_shareItem setPaletteLabel:@"Share Album"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_shareItem setToolTip:@"Share an Album"];
    
    // Tell the item what message to send when it is clicked
    [buttonView setTarget:self];
    [buttonView setAction:@selector(shareButtonPressed:)];
    
    return _shareItem;
    
}




-(IBAction)shareButtonPressed:(id)sender
{
    
    [[PIXShareManager defaultShareManager] showShareSheetForItems:@[self.selectedAlbum]
                                                   relativeToRect:[sender bounds]
                                                           ofView:sender
                                                    preferredEdge:NSMaxXEdge];
    
    /*
    PIXCustomShareSheetViewController *controller = [[PIXCustomShareSheetViewController alloc] initWithNibName:@"PIXCustomShareSheetViewController"     bundle:nil];
    
    [controller setAlbumsToShare:@[self.selectedAlbum]];
    
    NSPopover *popover = [[NSPopover alloc] init];
    [popover setContentViewController:controller];
    [popover setAnimates:YES];
    [popover setBehavior:NSPopoverBehaviorTransient];
    [popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
     */
}

- (NSToolbarItem *)deleteAlbumItem
{
    if(_deleteAlbumItem != nil) return _deleteAlbumItem;
    
    _deleteAlbumItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"deleteAlbumButton"];
    //_settingsButton.image = [NSImage imageNamed:NSImageNameSmartBadgeTemplate];
    
    NSButton * buttonView = [[NSButton alloc] initWithFrame:CGRectMake(0, -2, 100, 25)];
    
    [buttonView setImage:nil];
    [buttonView setImagePosition:NSImageLeft];
    [buttonView setBordered:YES];
    [buttonView setBezelStyle:NSTexturedSquareBezelStyle];
    [buttonView setTitle:@"Delete Album"];
    
    _deleteAlbumItem.view = buttonView;
    
    [_deleteAlbumItem setLabel:@"Delete Album"];
    [_deleteAlbumItem setPaletteLabel:@"Delete Album"];
    
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_deleteAlbumItem setToolTip:@"Delete Album"];
    
    // Tell the item what message to send when it is clicked
    [buttonView setTarget:self];
    [buttonView setAction:@selector(deleteAlbumPressed:)];
    
    return _deleteAlbumItem;
    
}

-(void)deleteAlbumPressed:(id)sender
{
    NSSet *itemsToDelete = [NSSet setWithObject:self.selectedAlbum];
    [[PIXFileManager sharedInstance] deleteItemsWorkflow:itemsToDelete];
}

- (NSToolbarItem *)importItem
{
    if(_importItem != nil) return _importItem;
    
    _importItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"importAlbumButton"];
    //_settingsButton.image = [NSImage imageNamed:NSImageNameSmartBadgeTemplate];

    NSButton * buttonView = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 60, 29)];
    
    [buttonView setImage:nil];
    [buttonView setImagePosition:NSImageLeft];
    [buttonView setBordered:YES];
    [buttonView setBezelStyle:NSTexturedSquareBezelStyle];
    [buttonView setTitle:@"Import"];
    
    _importItem.view = buttonView;
    
    [_importItem setLabel:@"Import"];
    [_importItem setPaletteLabel:@"Import"];
    
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_importItem setToolTip:@"Import photos"];
    
    // Tell the item what message to send when it is clicked
    [buttonView setTarget:self];
    [buttonView setAction:@selector(importPhotosPressed:)];
    
    return _importItem;
    
}

-(void)importPhotosPressed:(id)sender
{
    [[PIXFileManager sharedInstance] importPhotosToAlbum:self.selectedAlbum allowDirectories:NO];
}

-(void)leapSwipeUp
{
    if(self.view.window == nil) return;
    
    [(NSSound *)[NSSound soundNamed:@"Pop"] play];
    
    [self popViewAndUpdateAlbumSelectionForDelegate];
    //[self.navigationViewController popViewController];
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
        float currentPosition = self.leftPane.frame.size.width;
        [[NSUserDefaults standardUserDefaults] setFloat:currentPosition forKey:@"albumSideBarToggleWidth"];
        [self.splitView setPosition:0 ofDividerAtIndex:0];
        
        [self.view.window makeFirstResponder:self.imageBrowserViewController.collectionView];
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

-(void)dealloc
{
    DLog(@"dealloc of splitview");
}

@end
