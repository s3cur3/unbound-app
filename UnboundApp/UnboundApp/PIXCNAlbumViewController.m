//
//  PIXCNAlbumViewController.m
//  UnboundApp
//
//  Created by Scott Sykora on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXNavigationController.h"
#import "PIXCNAlbumViewController.h"
#import "CNGridViewItemLayout.h"

#import "PIXAppDelegate.h"
#import "PIXAppDelegate+CoreDataUtils.h"
#import "PIXDefines.h"

#import "PIXAlbum.h"

#import "PIXAlbumGridViewItem.h"

#import "PIXSplitViewController.h"

@interface PIXCNAlbumViewController ()
{
    
    
}

@property(nonatomic,strong) NSArray * albums;
@property(nonatomic,strong) NSArray * searchedAlbums;
@property(nonatomic,strong) NSMutableArray * selectedAlbums;

@property (nonatomic, strong) NSToolbarItem * trashbutton;
@property (nonatomic, strong) NSToolbarItem * settingsButton;
@property (nonatomic, strong) NSToolbarItem * searchBar;

@property (nonatomic, strong) NSSearchField * searchField;
@property (nonatomic, strong) NSString * lastSearch;

@property (nonatomic, strong) PIXSplitViewController *aSplitViewController;

@end

@implementation PIXCNAlbumViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.

        
    }
    
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.gridView setItemSize:CGSizeMake(190, 210)];
    [self.gridView setAllowsMultipleSelection:YES];
    [self.gridView reloadData];
    [self.gridView setUseHover:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(albumsChanged:)
                                                 name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultThemeChanged:)
                                                 name:@"backgroundThemeChanged"
                                               object:nil];
    
    [self setBGColor];
    
}

-(void)willShowPIXView
{
    NSString * searchString = [[NSUserDefaults standardUserDefaults] objectForKey:@"PIX_AlbumSearchString"];
    
    if(searchString != nil)
    {
        [self.searchField setStringValue:searchString];
    }
    
    else
    {
        [self.searchField setStringValue:@""];
    }
    
    [self updateSearch];
}

-(void)defaultThemeChanged:(NSNotification *)note
{
    [self setBGColor];
    [self.gridView setNeedsDisplay:YES];
    
    for(NSView * item in self.gridView.subviews)
    {
        [item setNeedsDisplay:YES];
    }
    
}

-(void)setBGColor
{
    NSColor * color = nil;
    if([[NSUserDefaults standardUserDefaults] integerForKey:@"backgroundTheme"] == 0)
    {
        color = [NSColor colorWithCalibratedWhite:0.912 alpha:1.000];
    }
    
    else
    {
        color = [NSColor colorWithPatternImage:[NSImage imageNamed:@"dark_bg"]];
        //[[self enclosingScrollView] setBackgroundColor:color];
    }
    
    [self.gridView setBackgroundColor:color];
    
}


#pragma mark - Toolbar Methods

-(void)setupToolbar
{
    NSArray * items = @[self.navigationViewController.middleSpacer, self.trashbutton, self.settingsButton, self.searchBar];
    
    [self.navigationViewController setToolbarItems:items];
    
}

- (NSToolbarItem *)trashbutton
{
    if(_trashbutton != nil) return _trashbutton;
    
    _trashbutton = [[NSToolbarItem alloc] initWithItemIdentifier:@"TrashButton"];
    //_trashbutton.image = [NSImage imageNamed:NSImageNameTrashEmpty];
    
    NSButton * buttonView = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    buttonView.image = [NSImage imageNamed:NSImageNameTrashEmpty];
    [buttonView setImagePosition:NSImageOnly];
    [buttonView setBordered:NO];
    [buttonView.cell setImageScaling:NSImageScaleProportionallyDown];
    [buttonView.cell setHighlightsBy:NSPushInCellMask];
    
    _trashbutton.view = buttonView;
    
    [_trashbutton setLabel:@"Trash"];
    [_trashbutton setPaletteLabel:@"Trash"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_trashbutton setToolTip:@"View Trash"];
    
    // Tell the item what message to send when it is clicked
    //[_trashbutton setTarget:self];
    //[_trashbutton setAction:@selector(showTrash)];
#ifdef DEBUG
    // Tell the item what message to send when it is clicked
    //[_trashbutton setTarget:[PIXAppDelegate sharedAppDelegate]];
    //[_trashbutton setAction:@selector(deleteAllAlbums:)];
    
    [buttonView setTarget:[PIXAppDelegate sharedAppDelegate]];
    [buttonView setAction:@selector(deleteAllAlbums:)];
    
#endif
    
    
    return _trashbutton;
    
}

- (NSToolbarItem *)settingsButton
{
    if(_settingsButton != nil) return _settingsButton;
    
    _settingsButton = [[NSToolbarItem alloc] initWithItemIdentifier:@"SettingsButton"];
    //_settingsButton.image = [NSImage imageNamed:NSImageNameSmartBadgeTemplate];
    
    NSButton * buttonView = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    buttonView.image = [NSImage imageNamed:NSImageNameSmartBadgeTemplate];
    [buttonView setImagePosition:NSImageOnly];
    [buttonView setBordered:NO];
    [buttonView.cell setImageScaling:NSImageScaleProportionallyDown];
    [buttonView.cell setHighlightsBy:NSPushInCellMask];
    
    _settingsButton.view = buttonView;
    
    [_settingsButton setLabel:@"Settings"];
    [_settingsButton setPaletteLabel:@"Settings"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_settingsButton setToolTip:@"Load Files"];
    
    // Tell the item what message to send when it is clicked
    [buttonView setTarget:[PIXAppDelegate sharedAppDelegate]];
    [buttonView setAction:@selector(showLoadingWindow:)];
    
    return _settingsButton;
    
}

- (NSToolbarItem *)searchBar
{
    if(_searchBar != nil) return _searchBar;
    
    self.searchField = [[NSSearchField alloc] initWithFrame:CGRectMake(0, 0, 150, 55)];
    //[searchField setFont:[NSFont systemFontOfSize:18]];
        
    [self.searchField setFocusRingType:NSFocusRingTypeNone];
    self.searchField.delegate = self;
    [self.searchField.cell setPlaceholderString:@"Search Albums"];
    [self.searchField.cell setFont:[NSFont fontWithName:@"Helvetica" size:13]];
    
    _searchBar = [[NSToolbarItem alloc] initWithItemIdentifier:@"SearchBar"];
    
    [_searchBar setView:self.searchField];
    
    [_searchBar setLabel:@"Search"];
    [_searchBar setPaletteLabel:@"Search"];
    
    return _searchBar;
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    [self updateSearch];
}

-(void)updateSearch
{
	
    NSString * searchText = [self.searchField stringValue];
    if(searchText != nil && [searchText length] > 0)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.title CONTAINS[cd] %@", searchText];
        
        if([self.albums count] > 0)
        {
            // if this search is more narrow than the last filter then re-filter based on the last set
            // (this happens while typing)
            
            if(self.lastSearch != nil && [searchText rangeOfString:self.lastSearch].length != 0)
            {
                self.searchedAlbums = [self.searchedAlbums filteredArrayUsingPredicate:predicate];
            }
            
            else
            {
                self.searchedAlbums = [self.albums filteredArrayUsingPredicate:predicate];
            }
            
            self.lastSearch = searchText;
        }        
    }
    
    else
    {
        self.searchedAlbums = nil;
        self.lastSearch = nil;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:searchText forKey:@"PIX_AlbumSearchString"];
    
    
    
    NSArray * visibleArray = self.albums;
    
    if(self.searchedAlbums)
    {
        visibleArray = self.searchedAlbums;
    }
    
    NSArray * selectedCopy = [self.selectedAlbums copy];
    
    // find any albums that were selected and no longer in the list
    for(PIXAlbum * album in selectedCopy)
    {
        NSUInteger index = [visibleArray indexOfObject:album];
        if(index == NSNotFound)
        {
            [self.selectedAlbums removeObject:album];
        }
    }
    
    
    [self updateToolbar];
    [self.gridView reloadData];
	
}


-(void)showTrash
{
    
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNGridView DataSource

- (NSUInteger)gridView:(CNGridView *)gridView numberOfItemsInSection:(NSInteger)section
{
    if(self.searchedAlbums)
    {
        return self.searchedAlbums.count;
    }
    
    return self.albums.count;
}

- (CNGridViewItem *)gridView:(CNGridView *)gridView itemAtIndex:(NSInteger)index inSection:(NSInteger)section
{
    static NSString *reuseIdentifier = @"PIXAlbumGridViewItem";
    
    PIXAlbumGridViewItem *item = [gridView dequeueReusableItemWithIdentifier:reuseIdentifier];
    if (item == nil) {
        item = [[PIXAlbumGridViewItem alloc] initWithLayout:nil reuseIdentifier:reuseIdentifier];
        NSMenu *menu = [self menuForObject:item];
        [item setMenu:menu];
    }
    
    item.album = [self albumForIndex:index];
    
    return item;
}

- (BOOL)gridView:(CNGridView *)gridView itemIsSelectedAtIndex:(NSInteger)index inSection:(NSInteger)section
{
    return [self.selectedAlbums containsObject:[self albumForIndex:index]];
}


-(PIXAlbum *)albumForIndex:(NSInteger)index
{
    PIXAlbum * album = nil;
    if(self.searchedAlbums)
    {
        album = [self.searchedAlbums objectAtIndex:index];
    }
    
    else
    {
        album = [self.albums objectAtIndex:index];
    }
    
    return album;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSNotifications

- (void)detectedNotification:(NSNotification *)notif
{
    //    DLog(@"notification: %@", notif);
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNGridView Delegate

- (void)gridView:(CNGridView *)gridView didClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    DLog(@"didClickItemAtIndex: %li", index);
}

- (void)gridView:(CNGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    //[gridView deselectAllItems];
    
    DLog(@"didDoubleClickItemAtIndex: %li", index);
    PIXAlbum * album = nil;
    
    if(self.searchedAlbums)
    {
        album = [self.searchedAlbums objectAtIndex:index];
    }
    
    else
    {
        album = [self.albums objectAtIndex:index];
    }
    
    [self showPhotosForAlbum:album];
}

-(void)showPhotosForAlbum:(id)anAlbum
{
    self.aSplitViewController.selectedAlbum = anAlbum;
    [self.navigationViewController pushViewController:self.aSplitViewController];
}

- (void)gridView:(CNGridView *)gridView rightMouseButtonClickedOnItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    DLog(@"rightMouseButtonClickedOnItemAtIndex: %li", index);
}

- (void)gridView:(CNGridView *)gridView didSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [self.selectedAlbums addObject:[self albumForIndex:index]];
    
    [self updateToolbar];
}

- (void)gridView:(CNGridView *)gridView didDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [self.selectedAlbums removeObject:[self albumForIndex:index]];
    
    [self updateToolbar];
}

- (void)gridViewDidDeselectAllItems:(CNGridView *)gridView
{
    [self.selectedAlbums removeAllObjects];
    [self updateToolbar];
}


-(void)updateToolbar
{
    if([self.selectedAlbums count] > 0)
    {
        if([self.selectedAlbums count] > 1)
        {
            [self.toolbarTitle setStringValue:[NSString stringWithFormat:@"%ld albums selected", (unsigned long)[self.selectedAlbums count]]];
        }
        
        else
        {
            [self.toolbarTitle setStringValue:@"1 album selected"];
        }
        
        [self showToolbar:YES];
    }
    
    else
    {
        [self hideToolbar:YES];
    }
}



-(void)albumsChanged:(NSNotification *)note
{
    self.albums = nil;
    [self.gridView reloadData];
}

-(NSArray *)albums
{
    if(_albums != nil) return _albums;
    
    _albums = [[PIXAppDelegate sharedAppDelegate] fetchAllAlbums];
    
    return _albums;
}

-(NSMutableArray *)selectedAlbums
{
    if(_selectedAlbums != nil) return _selectedAlbums;
    
    _selectedAlbums = [NSMutableArray new];
    
    return _selectedAlbums;
}

-(PIXSplitViewController *) aSplitViewController
{
    if(_aSplitViewController != nil) return _aSplitViewController;
    
    _aSplitViewController = [[PIXSplitViewController alloc] initWithNibName:@"PIXSplitViewController" bundle:nil];
    
    return _aSplitViewController;

}


@end
