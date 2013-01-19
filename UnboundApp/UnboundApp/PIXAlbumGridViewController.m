//
//  PIXAlbumGridViewController.m
//  UnboundApp
//
//  Created by Bob on 1/18/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXAlbumGridViewController.h"
#import "CNGridViewItem.h"
#import "CNGridViewItemLayout.h"
#import "PIXAppDelegate.h"
#import "PIXAppDelegate+CoreDataUtils.h"

#import "PIXAlbum.h"
#import "PIXDefines.h"
#import "PIXGridViewItem.h"

#import "PIXNavigationController.h"
#import "PIXSplitViewController.h"

static NSString *kContentTitleKey, *kContentImageKey;

@interface PIXAlbumGridViewController ()
{
    BOOL startedObserving;
}
@property (strong) CNGridViewItemLayout *defaultLayout;
@property (strong) CNGridViewItemLayout *hoverLayout;
@property (strong) CNGridViewItemLayout *selectionLayout;

@property (nonatomic, strong) NSToolbarItem * trashbutton;
@property (nonatomic, strong) NSToolbarItem * settingsButton;

@end

@implementation PIXAlbumGridViewController

+ (void)initialize
{
    kContentTitleKey = @"title";
    kContentImageKey = @"thumbnailImage";
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        _items = [[NSMutableArray alloc] init];
        _defaultLayout = [CNGridViewItemLayout defaultLayout];
        _hoverLayout = [CNGridViewItemLayout defaultLayout];
        _selectionLayout = [CNGridViewItemLayout defaultLayout];
    }
    
    return self;
}

-(void)awakeFromNib
{
    self.hoverLayout.backgroundColor = [[NSColor grayColor] colorWithAlphaComponent:0.42];
    self.selectionLayout.backgroundColor = [NSColor colorWithCalibratedRed:0.542 green:0.699 blue:0.807 alpha:0.420];
    self.defaultLayout.visibleContentMask = CNGridViewItemVisibleContentImage;
    self.hoverLayout.visibleContentMask = CNGridViewItemVisibleContentImage | CNGridViewItemVisibleContentTitle;
    self.selectionLayout.visibleContentMask = CNGridViewItemVisibleContentImage | CNGridViewItemVisibleContentTitle;
    
    [self.gridView setItemSize:[PIXGridViewItem defaultItemSize]];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewWillHoverItemNotification object:nil];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewWillUnhoverItemNotification object:nil];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewWillSelectItemNotification object:nil];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewDidSelectItemNotification object:nil];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewWillDeselectItemNotification object:nil];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewDidDeselectItemNotification object:nil];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewDidClickItemNotification object:nil];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewDidDoubleClickItemNotification object:nil];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewRightMouseButtonClickedOnItemNotification object:nil];
    
    [nc addObserver:self selector:@selector(refreshNotification:)
                                                 name:kCreateThumbDidFinish
                                               object:nil];
    
    [nc addObserver:self selector:@selector(reloadAlbums:)
                                                 name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM
                                               object:nil];
    
    [self performSelector:@selector(reloadAlbums:) withObject:nil afterDelay:0.1];
}

-(void)refreshNotification:(NSNotification *)note
{
    [self.gridView reloadData];
}

-(NSMutableArray *)albums
{
    return [[[PIXAppDelegate sharedAppDelegate] fetchAllAlbums] mutableCopy];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)reloadAlbums:(NSNotification *)note
{
    [self.items removeAllObjects];
    NSArray *albumsArray = [self albums];
    [self.items addObjectsFromArray:albumsArray];
    [self.gridView reloadData];
}

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
    return self.items.count;
}

- (CNGridViewItem *)gridView:(CNGridView *)gridView itemAtIndex:(NSInteger)index inSection:(NSInteger)section
{
    static NSString *reuseIdentifier = @"CNGridViewItem";
    
    CNGridViewItem *item = [gridView dequeueReusableItemWithIdentifier:reuseIdentifier];
    if (item == nil) {
        item = [[PIXGridViewItem alloc] initWithLayout:self.defaultLayout reuseIdentifier:reuseIdentifier];
    }
    item.hoverLayout = self.hoverLayout;
    item.selectionLayout = self.selectionLayout;
    
//    NSDictionary *contentDict = [self.items objectAtIndex:index];
//    item.itemTitle = [NSString stringWithFormat:@"Item: %lu", index];
//    item.itemImage = [contentDict objectForKey:kContentImageKey];
    
    PIXAlbum *anAlbum = [self.items objectAtIndex:index];
    PIXGridViewItem *pixItem = (PIXGridViewItem *)item;
    pixItem.album = anAlbum;
    item.itemTitle = anAlbum.title;
    item.itemImage = [anAlbum thumbnailImage];

    
    return item;
}

-(void)showPhotosForAlbum:(id)anAlbum
{
    PIXSplitViewController *aSplitViewController  = [[PIXSplitViewController alloc] initWithNibName:@"PIXSplitViewController" bundle:nil];
    aSplitViewController.selectedAlbum = anAlbum;
    [aSplitViewController.view setFrame:self.view.bounds];
    [self.navigationViewController pushViewController:aSplitViewController];
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSNotifications

- (void)detectedNotification:(NSNotification *)notif
{
        //CNLog(@"notification: %@", notif);
}




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNGridView Delegate

- (void)gridView:(CNGridView *)gridView didClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    CNLog(@"didClickItemAtIndex: %li", index);
}

- (void)gridView:(CNGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    CNLog(@"didDoubleClickItemAtIndex: %li", index);
    id anAlbum = [self.items objectAtIndex:index];
    [self showPhotosForAlbum:anAlbum];
}

- (void)gridView:(CNGridView *)gridView rightMouseButtonClickedOnItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    CNLog(@"rightMouseButtonClickedOnItemAtIndex: %li", index);
}

- (void)gridView:(CNGridView *)gridView didSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    CNLog(@"didSelectItemAtIndex: %li", index);
}

- (void)gridView:(CNGridView *)gridView didDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    CNLog(@"didDeselectItemAtIndex: %li", index);
}

@end

