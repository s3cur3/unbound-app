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
#import "PIXCustomButton.h"

#import "PIXCustomShareSheetViewController.h"

@interface PIXCNAlbumViewController ()
{
    
    
}

@property(nonatomic,strong) NSArray * albums;
@property(nonatomic,strong) NSArray * searchedAlbums;

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
        self.selectedItemsName = @"album";
        
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
    [[self.view window] setTitle:@"Unbound"];
    
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
    
    NSArray * selectedCopy = [self.selectedItems copy];
    
    // find any albums that were selected and no longer in the list
    for(PIXAlbum * album in selectedCopy)
    {
        NSUInteger index = [visibleArray indexOfObject:album];
        if(index == NSNotFound)
        {
            [self.selectedItems removeObject:album];
        }
    }
    
    
    [self updateToolbar];
    [self updateGridTitle];
    [self.gridView reloadData];
	
}

-(void)updateGridTitle
{
    if(self.searchedAlbums)
    {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
        NSString *albumCount = [numberFormatter stringFromNumber:[NSNumber numberWithLong:[self.searchedAlbums count]]];
        
        
        if([self.searchedAlbums count] == 1)
        {
            [self.gridViewTitle setStringValue:[NSString stringWithFormat:@"1 album matched \"%@\"", self.lastSearch]];
        }
        
        else
        {
            [self.gridViewTitle setStringValue:[NSString stringWithFormat:@"%@ albums matched \"%@\"", albumCount, self.lastSearch]];
        }
    }
    else
    {
        NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kPhotoEntityName];
        
        NSUInteger numPhotos = [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] countForFetchRequest:fetchRequest error:nil];
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
        NSString *albumCount = [numberFormatter stringFromNumber:[NSNumber numberWithLong:[self.albums count]]];
         NSString *photosCount = [numberFormatter stringFromNumber:[NSNumber numberWithLong:numPhotos]];
        
        [self.gridViewTitle setStringValue:[NSString stringWithFormat:@"%@ albums containing %@ photos", albumCount, photosCount]];
    }
}

-(void)updateToolbar
{
    [super updateToolbar];
    
    PIXCustomButton * deleteButton = [[PIXCustomButton alloc] initWithFrame:CGRectMake(0, 0, 80, 25)];
    [deleteButton setTitle:@"Delete"];
    [deleteButton setTarget:self];
    [deleteButton setAction:@selector(deleteItems:)];
    
    PIXCustomButton * shareButton = [[PIXCustomButton alloc] initWithFrame:CGRectMake(0, 0, 80, 25)];
    [shareButton setTitle:@"Share"];
    [shareButton setTarget:self];
    [shareButton setAction:@selector(share:)];
    
    PIXCustomButton * mergeButton = [[PIXCustomButton alloc] initWithFrame:CGRectMake(0, 0, 80, 25)];
    [mergeButton setTitle:@"Merge Albums"];
    [mergeButton setTarget:self];
    //[deleteButton setAction:@selector(deleteItems:)];
    
    if([self.selectedItems count] > 1)
    {
        [self.toolbar setButtons:@[deleteButton, shareButton, mergeButton]];
    }
    
    else
    {
        [self.toolbar setButtons:@[deleteButton, shareButton]];
    }
    
}

-(void)share:(id)sender
{
    PIXCustomShareSheetViewController *controller = [[PIXCustomShareSheetViewController alloc] initWithNibName:@"PIXCustomShareSheetViewController"     bundle:nil];
    NSPopover *popover = [[NSPopover alloc] init];
    [popover setContentSize:NSMakeSize(280.0f, 100.0f)];
    [popover setContentViewController:controller];
    [popover setAnimates:YES];
    [popover setBehavior:NSPopoverBehaviorTransient];
    [popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
    
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
        /*NSMenu *menu = [self menuForObject:item];
        [item setMenu:menu];*/
    }
    
    item.album = [self albumForIndex:index];
    
    return item;
}

- (BOOL)gridView:(CNGridView *)gridView itemIsSelectedAtIndex:(NSInteger)index inSection:(NSInteger)section
{
    return [self.selectedItems containsObject:[self albumForIndex:index]];
}


-(PIXAlbum *)albumForIndex:(NSInteger)index
{
    PIXAlbum * album = nil;
    if(self.searchedAlbums)
    {
        if(index > [self.searchedAlbums count]) return nil;
        
        album = [self.searchedAlbums objectAtIndex:index];
    }
    
    else
    {
        if(index > [self.albums count]) return nil;
        
        album = [self.albums objectAtIndex:index];
    }
    
    return album;
}

-(NSInteger)indesForAlbum:(PIXAlbum *)album
{
    if(self.searchedAlbums)
    {
        return [self.searchedAlbums indexOfObject:album];
    }
    
    return [self.albums indexOfObject:album];
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
    
    
    //dispatch_async(dispatch_get_main_queue(), ^{
        [self showPhotosForAlbum:album];
    //});
    
}

-(void)showPhotosForAlbum:(id)anAlbum
{
    self.aSplitViewController.selectedAlbum = anAlbum;
    [self.navigationViewController pushViewController:self.aSplitViewController];
}

- (void)gridView:(CNGridView *)gridView rightMouseButtonClickedOnItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event
{
    PIXAlbum * albumClicked = [self albumForIndex:index];
    
    // we don't handle clicks off of an album right now
    if(albumClicked == nil) return;
    
    // if this album isn't in the selection than re-select only this one
    if(albumClicked != nil && ![self.selectedItems containsObject:albumClicked])
    {
        [self.selectedItems removeAllObjects];
        [self.selectedItems addObject:albumClicked];
        [self.gridView reloadSelection];
        [self updateToolbar];
    }
    
    // otherwise we're doing an operation on the whole selected list
    
    
    NSMenu *contextMenu = [self menuForObject:albumClicked];
    [NSMenu popUpContextMenu:contextMenu withEvent:event forView:self.view];
    
    
    DLog(@"rightMouseButtonClickedOnItemAtIndex: %li", index);
}

#pragma mark - Selection Operations

- (void)gridView:(CNGridView *)gridView didSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [self.selectedItems addObject:[self albumForIndex:index]];
    
    [self updateToolbar];
}

- (void)gridView:(CNGridView *)gridView didDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [self.selectedItems removeObject:[self albumForIndex:index]];
    
    [self updateToolbar];
}

- (void)gridView:(CNGridView *)gridView didShiftSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    
    if([self.selectedItems count] == 0)
    {
        [self.selectedItems addObject:[self albumForIndex:index]];
    }
    
    else
    {
        // loop through the current selection and find the index that's closest the the newly clicked index
        NSUInteger startIndex = NSNotFound;
        NSUInteger distance = NSUIntegerMax;
        
        for(PIXAlbum * aSelectedAlbum in self.selectedItems)
        {
            NSUInteger thisIndex = [self indesForAlbum:aSelectedAlbum];
            NSUInteger thisDistance = abs((int)(thisIndex-index));
            
            if(thisIndex != NSNotFound && thisDistance < distance)
            {
                startIndex = thisIndex;
                distance = thisDistance;
            }
        }
        
        // prep the indexes we're going to loop through
        NSUInteger endIndex = index;
        
        // flip them so we always go the right rections
        if(endIndex < startIndex)
        {
            endIndex = startIndex;
            startIndex = index;
        }
        
        // now add all the items between the two indexes to the selection
        for(NSUInteger i = startIndex; i <= endIndex; i++)
        {
            [self.selectedItems addObject:[self albumForIndex:i]];
        }
    }
    
    [self.gridView reloadSelection];
    [self updateToolbar];
}

- (void)gridViewDidDeselectAllItems:(CNGridView *)gridView
{
    [self.selectedItems removeAllObjects];
    [self updateToolbar];
}

-(void)selectAll:(id)sender
{
    if(self.searchedAlbums)
    {
        self.selectedItems = [NSMutableSet setWithArray:self.searchedAlbums];
    }
    
    else
    {
        self.selectedItems = [NSMutableSet setWithArray:self.albums];
    }
    
    [self.gridView reloadSelection];
    [self updateToolbar];
}

-(void)toggleSelection:(id)sender
{
    NSMutableSet * visibleItems = [NSMutableSet setWithArray:self.albums];
    
    if(self.searchedAlbums)
    {
        visibleItems = [NSMutableSet setWithArray:self.searchedAlbums];
    }
    
    
    // now remove items from the list that are already selected
    [visibleItems minusSet:self.selectedItems];
    
    self.selectedItems = visibleItems;
    
    [self.gridView reloadSelection];
    [self updateToolbar];
    
}

#pragma mark - Drag Operations

- (void)gridView:(CNGridView *)gridView dragDidBeginAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event
{
    // move the item we just selected to the front (so it will show up correctly in the drag image)
    PIXAlbum * topAlbum = [self albumForIndex:index];
    
    NSMutableArray * selectedArray = [[self.selectedItems allObjects] mutableCopy];
    
    if(topAlbum)
    {
        [selectedArray removeObject:topAlbum];
        [selectedArray insertObject:topAlbum atIndex:0];
    }
 
    
    NSPasteboard *dragPBoard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [dragPBoard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:nil];
    
    NSMutableArray * filenames = [[NSMutableArray alloc] initWithCapacity:[selectedArray count]];
    
    for(PIXAlbum * anAlbum in selectedArray)
    {
        [filenames addObject:anAlbum.path];
        //[dragPBoard setString:anAlbum.path forType:NSFilenamesPboardType];
    }
        
    [dragPBoard setPropertyList:filenames
                        forType:NSFilenamesPboardType];
    NSPoint location = [self.gridView convertPoint:[event locationInWindow] fromView:nil];
    location.x -= 90;
    location.y += 90;
    
    NSImage * dragImage = [PIXAlbumGridViewItem dragImageForAlbums:selectedArray size:NSMakeSize(180, 180)];
    [self.gridView dragImage:dragImage at:location offset:NSZeroSize event:event pasteboard:dragPBoard source:self slideBack:YES];
    
}


-(void)albumsChanged:(NSNotification *)note
{
    self.albums = nil;
    [self.gridView reloadData];
    [self updateGridTitle];
    [self updateSearch];
}

-(NSArray *)albums
{
    if(_albums != nil) return _albums;
    
    _albums = [[PIXAppDelegate sharedAppDelegate] fetchAllAlbums];
    
    return _albums;
}

-(PIXSplitViewController *) aSplitViewController
{
    if(_aSplitViewController != nil) return _aSplitViewController;
    
    _aSplitViewController = [[PIXSplitViewController alloc] initWithNibName:@"PIXSplitViewController" bundle:nil];
    
    return _aSplitViewController;

}


@end
