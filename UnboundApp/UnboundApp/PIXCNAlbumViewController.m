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

@property (strong) CNGridViewItemLayout *defaultLayout;
@property (strong) CNGridViewItemLayout *hoverLayout;
@property (strong) CNGridViewItemLayout *selectionLayout;

@property (nonatomic, strong) NSToolbarItem * trashbutton;
@property (nonatomic, strong) NSToolbarItem * settingsButton;

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
    [self.gridView setItemSize:CGSizeMake(190, 180)];
    [self.gridView setAllowsMultipleSelection:YES];
    [self.gridView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(albumsChanged:)
                                                 name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM
                                               object:nil];
}


#pragma mark - Toolbar Methods

-(void)setupToolbar
{
    NSArray * items = @[self.navigationViewController.middleSpacer, self.trashbutton, self.settingsButton];
    
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

-(void)showTrash
{
    
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNGridView DataSource

- (NSUInteger)gridView:(CNGridView *)gridView numberOfItemsInSection:(NSInteger)section
{
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
    
    PIXAlbum * album  = [self.albums objectAtIndex:index];
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
    DLog(@"didDoubleClickItemAtIndex: %li", index);
    PIXAlbum * album = [self.albums objectAtIndex:index];
    [self showPhotosForAlbum:album];
}

-(void)showPhotosForAlbum:(id)anAlbum
{
    PIXSplitViewController *aSplitViewController  = [[PIXSplitViewController alloc] initWithNibName:@"PIXSplitViewController" bundle:nil];
    aSplitViewController.selectedAlbum = anAlbum;
    [aSplitViewController.view setFrame:self.view.bounds];
    [self.navigationViewController pushViewController:aSplitViewController];
}

- (void)gridView:(CNGridView *)gridView rightMouseButtonClickedOnItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    DLog(@"rightMouseButtonClickedOnItemAtIndex: %li", index);
}

- (void)gridView:(CNGridView *)gridView didSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    DLog(@"didSelectItemAtIndex: %li", index);
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


@end
