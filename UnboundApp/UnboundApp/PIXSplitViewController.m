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
//@property (nonatomic, strong) PIXImageBrowserViewController *imageBrowserViewController;
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
    }
    
    return self;
}

-(void)awakeFromNib
{
    [self setupSidebar];
    [self setupBrowser];
    
    // set the holding priority for the sidebar to high, so it doesn't resize with the window
    [self.splitView setHoldingPriority:NSLayoutPriorityDefaultHigh forSubviewAtIndex:0];
    [self.splitView setHoldingPriority:NSLayoutPriorityDefaultLow forSubviewAtIndex:1];
    
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
    //_settingsButton.image = [NSImage imageNamed:NSImageNameSmartBadgeTemplate];
    
    
    // set the toggle to the correct view
    [self.backButtonSegment setSelected:![self.splitView isSubviewCollapsed:self.leftPane]
                             forSegment:1];

    
    _backButtonSegmentItem.view = self.backButtonSegment;
    
    [_backButtonSegmentItem setLabel:@"Back"];
    [_backButtonSegmentItem setPaletteLabel:@"Back"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_backButtonSegmentItem setToolTip:@"Back to Albums"];
    
    // Tell the item what message to send when it is clicked
    
    
    
    
    return _backButtonSegmentItem;
}

/*
- (NSToolbarItem *)sidebarToggleButton
{
    if(_sidebarToggleButton != nil) return _sidebarToggleButton;
    
    _sidebarToggleButton = [[NSToolbarItem alloc] initWithItemIdentifier:@"ToggleSideBarButton"];
    _sidebarToggleButton.image = [NSImage imageNamed:NSImageNameRevealFreestandingTemplate];
    
    [_sidebarToggleButton setLabel:@"Sidebar"];
    [_sidebarToggleButton setPaletteLabel:@"Sidebar"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_sidebarToggleButton setToolTip:@"Toggle Sidebar"];
    
    // Tell the item what message to send when it is clicked
    [_sidebarToggleButton setTarget:self];
    [_sidebarToggleButton setAction:@selector(toggleSidebar)];
    
    return _sidebarToggleButton;
    
}
*/

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
    
    [self.splitView adjustSubviews];
    
    
    if([self.splitView isSubviewCollapsed:self.leftPane])
    {
        [self.splitView setPosition:230 ofDividerAtIndex:0];
    }
    
    else
    {
        [self.splitView setPosition:-1 ofDividerAtIndex:0];
    }
    
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

// constrain the positions that the split can be dragged to
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    if(dividerIndex != 0) return proposedMinimumPosition;
    
    float min = 200;
    
    if(proposedMinimumPosition < min)
    {
        self.lastSplitviewWidth = min;
        return min;
    }
    
    self.lastSplitviewWidth = proposedMinimumPosition;
    return proposedMinimumPosition;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    if(dividerIndex != 0) return proposedMaximumPosition;
    
    float max = self.view.frame.size.width - 200;
    
    if(proposedMaximumPosition > max)
    {
        self.lastSplitviewWidth = max;
        return max;
    }
    
    self.lastSplitviewWidth = proposedMaximumPosition;
    return proposedMaximumPosition;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    if(subview == self.leftPane) return YES;
    
    return NO;
}

/*
- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex
{
    // if we're hiding the albums view
    if(dividerIndex == 0 && proposedPosition < 40)
    {
        return 0;
        [splitView ]
    }
    
    
    float min = 200;
    float max = self.view.frame.size.width - 200;
    
    if(proposedPosition < min) return min;
    
    if(proposedPosition > max) return max;
    
    return proposedPosition;
}*/

/*
// constrain the split positions after resizing
- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
    //if([splitView )
}*/
        
- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
    return YES;
}


- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
{
    if(dividerIndex == 0 && [self.splitView isSubviewCollapsed:self.leftPane]) return YES;
    
    return NO;
}


-(void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
    // if the size isn't changing then there is no need to mess with this
    if(CGSizeEqualToSize(oldSize, self.view.bounds.size)) return;
    
    splitView.frame = self.view.bounds;
    
    float dividerPosition = self.leftPane.frame.size.width;
    
    if([self.splitView isSubviewCollapsed:self.leftPane])
    {
        dividerPosition = -1;
    }
    
    else
    {
        self.lastSplitviewWidth = dividerPosition;
    }
    
    NSRect leftFrame = NSRectFromCGRect(splitView.bounds);
    NSRect rightFrame = NSRectFromCGRect(splitView.bounds);
    
    leftFrame.size.width = dividerPosition;
    rightFrame.size.width = rightFrame.size.width - leftFrame.size.width - splitView.dividerThickness;
    rightFrame.origin.x = rightFrame.origin.x + leftFrame.size.width + splitView.dividerThickness;
    
    self.leftPane.frame = leftFrame;
    self.rightPane.frame = rightFrame;
    
    
}



-(void)dealloc
{
    DLog(@"dealloc of splitview");
}

@end
