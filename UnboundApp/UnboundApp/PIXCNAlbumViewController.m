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

@property(nonatomic,strong) NSMutableArray * albums;
@property(nonatomic,strong) NSArray * searchedAlbums;

@property (strong) CNGridViewItemLayout *defaultLayout;
@property (strong) CNGridViewItemLayout *hoverLayout;
@property (strong) CNGridViewItemLayout *selectionLayout;

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
        _defaultLayout = [CNGridViewItemLayout defaultLayout];
        _hoverLayout = [CNGridViewItemLayout defaultLayout];
        _selectionLayout = [CNGridViewItemLayout defaultLayout];
        
    }
    
    return self;
}

-(void)awakeFromNib
{
    //[self.view setWantsLayer:YES];
    //[self.gridView setWantsLayer:YES];
    
    [self.gridView setItemSize:CGSizeMake(190, 180)];
    [self.gridView setAllowsMultipleSelection:YES];
    [self.gridView reloadData];
    [self.gridView setUseHover:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(albumsChanged:)
                                                 name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM
                                               object:nil];
    
    
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
    _trashbutton.image = [NSImage imageNamed:NSImageNameTrashEmpty];
    
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
    [_trashbutton setTarget:[PIXAppDelegate sharedAppDelegate]];
    [_trashbutton setAction:@selector(deleteAllAlbums:)];
#endif
    
    return _trashbutton;
    
}

- (NSToolbarItem *)settingsButton
{
    if(_settingsButton != nil) return _settingsButton;
    
    _settingsButton = [[NSToolbarItem alloc] initWithItemIdentifier:@"SettingsButton"];
    _settingsButton.image = [NSImage imageNamed:NSImageNameSmartBadgeTemplate];
    
    [_settingsButton setLabel:@"Settings"];
    [_settingsButton setPaletteLabel:@"Settings"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_settingsButton setToolTip:@"Load Files"];
    
    // Tell the item what message to send when it is clicked
    [_settingsButton setTarget:[PIXAppDelegate sharedAppDelegate]];
    [_settingsButton setAction:@selector(showLoadingWindow:)];
    
    return _settingsButton;
    
}

- (NSToolbarItem *)searchBar
{
    if(_searchBar != nil) return _searchBar;
    
    self.searchField = [[NSSearchField alloc] initWithFrame:CGRectMake(0, 0, 150, 55)];
    //[searchField setFont:[NSFont systemFontOfSize:18]];
    
    [self.searchField setFocusRingType:NSFocusRingTypeNone];
    self.searchField.delegate = self;
    
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
        item = [[PIXAlbumGridViewItem alloc] initWithLayout:self.defaultLayout reuseIdentifier:reuseIdentifier];
    }
    item.hoverLayout = self.hoverLayout;
    item.selectionLayout = self.selectionLayout;
    
    
    PIXAlbum * album = nil;
    if(self.searchedAlbums)
    {
        album = [self.searchedAlbums objectAtIndex:index];
    }
    
    else
    {
        album = [self.albums objectAtIndex:index];
    }
    
    
    item.album = album;
    
    return item;
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
    PIXAlbum * album = [self.albums objectAtIndex:index];
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
    DLog(@"didSelectItemAtIndex: %li", index);
    DLog(@"%@",[self.albums objectAtIndex:index]);
}

- (void)gridView:(CNGridView *)gridView didDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    DLog(@"didDeselectItemAtIndex: %li", index);
}


-(void)albumsChanged:(NSNotification *)note
{
    self.albums = nil;
    [self.gridView reloadData];
}

-(NSMutableArray *)albums
{
    if(_albums != nil) return _albums;
    
    _albums = [[[PIXAppDelegate sharedAppDelegate] fetchAllAlbums] mutableCopy];
    
    return _albums;
}

-(PIXSplitViewController *) aSplitViewController
{
    if(_aSplitViewController != nil) return _aSplitViewController;
    
    _aSplitViewController = [[PIXSplitViewController alloc] initWithNibName:@"PIXSplitViewController" bundle:nil];
    
    return _aSplitViewController;

}


@end
