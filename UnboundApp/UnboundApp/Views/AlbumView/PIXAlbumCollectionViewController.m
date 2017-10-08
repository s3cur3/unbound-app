//
//  PIXAlbumCollectionViewController.m
//  UnboundApp
//
//  Created by Ditriol Wei on 28/7/16.
//  Copyright © 2016 Pixite Apps LLC. All rights reserved.
//

#import "PIXAlbumCollectionViewController.h"
#import "PIXSplitViewController.h"
#import "PIXMainWindowController.h"
#import "PIXNavigationController.h"

#import "PIXDefines.h"
#import "PIXAppDelegate.h"
#import "PIXFileParser.h"
#import "PIXFileManager.h"
#import "PIXAlbum.h"
#import "PIXCustomButton.h"
#import "PIXShareManager.h"

#import "PIXAlbumCollectionViewItem.h"
#import "PIXCollectionToolbar.h"

@interface PIXAlbumCollectionViewController () <NSCollectionViewDelegate, NSCollectionViewDataSource, PIXSplitViewControllerDelegate>

@property(nonatomic,strong) NSArray * albums;
@property(nonatomic,strong) NSArray * searchedAlbums;

@property (nonatomic, strong) NSToolbarItem * sortButton;
@property (nonatomic, strong) NSToolbarItem * neuAlbumButton;
@property (nonatomic, strong) NSToolbarItem * searchBar;
@property (nonatomic, strong) NSToolbarItem * importItem;

@property (nonatomic, strong) NSSearchField * searchField;
@property (nonatomic, strong) NSString * lastSearch;

@property (nonatomic, strong) PIXSplitViewController *aSplitViewController;

@property BOOL isMountDisconnected;
@end

@implementation PIXAlbumCollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        self.selectedItemsName = @"album";
        
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    /*
    [self.collectionView setItemSize:NSMakeSize(190, 210)];
    [self.collectionView setAllowsMultipleSelection:YES];
    [self.collectionView reloadData];
    [self.collectionView setUseHover:NO];
    */

    self.collectionView.delegate = self;

    self.toolbar.collectionView = self.collectionView;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(albumsChanged:)
                                                 name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(albumRenamed:)
                                                 name:AlbumWasRenamedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultThemeChanged:)
                                                 name:@"backgroundThemeChanged"
                                               object:nil];
    
    [self.scrollView setIdentifier:@"albumGridScroller"];

    NSCollectionViewFlowLayout *flowLayout = [[NSCollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = NSMakeSize(190, 210);
    flowLayout.sectionInset = NSEdgeInsetsMake(10, 20, 10, 20);
    flowLayout.minimumInteritemSpacing = 20;
    flowLayout.minimumLineSpacing = 20;
    self.collectionView.collectionViewLayout = flowLayout;

    self.view.wantsLayer = YES;
    [self setBGColor];

    [self setupCollectionToolbar];

    [self albumsChanged:nil];
    
}

- (void)willShowPIXView
{
    [super willShowPIXView];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // make ourselves the first responder after we're added
        [self.view.window makeFirstResponder:self.collectionView];
        //        [self setNextResponder:self.scrollView];
        //        [self.collectionView setNextResponder:self];
    });
    
    
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

    [self updateCollectionToolbar];
    
    [[PIXFileParser sharedFileParser] addObserver:self forKeyPath:@"fullScanProgress" options:NSKeyValueObservingOptionNew context:nil];
    
    [[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] setTitle:@"Unbound"];

}

// this is called when the full scan progress changes
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    dispatch_async(dispatch_get_main_queue(), ^{
        float progress = [[PIXFileParser sharedFileParser] fullScanProgress];
        
        if(progress < 1.0)
        {
            [self.gridViewTitle setHidden:YES];
            [self.gridViewProgress setHidden:NO];
            
            
            [self.gridViewProgress setProgress:progress];
        }
        
        else
        {
            [self.gridViewTitle setHidden:NO];
            [self.gridViewProgress setHidden:YES];
        }
    });
    
}

- (void)willHidePIXView
{
    [super willHidePIXView];
    
    [[PIXFileParser sharedFileParser] removeObserver:self forKeyPath:@"fullScanProgress"];
}

- (void)defaultThemeChanged:(NSNotification *)note
{
    [self setBGColor];
    [self.collectionView setNeedsDisplay:YES];
    
    for(NSView * item in self.collectionView.subviews)
    {
        [item setNeedsDisplay:YES];
    }
    
}

- (void)setBGColor
{
    NSColor * color = nil;
    NSColor *textColor = nil;
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"backgroundTheme"] == 0) {
        color = [NSColor colorWithCalibratedWhite:0.912 alpha:1.0];
        textColor = [NSColor colorWithCalibratedWhite:0.45 alpha:1.0];
    } else {
        color = [NSColor colorWithPatternImage:[NSImage imageNamed:@"dark_bg"]];
        textColor = [NSColor colorWithCalibratedWhite:0.55 alpha:1.000];
    }

    self.collectionView.layer.backgroundColor = color.CGColor;
    self.view.layer.backgroundColor = color.CGColor;
    self.gridViewTitle.textColor = textColor;
}

#pragma mark - ToolBar

- (void)setupToolbar
{
    NSArray * items = @[self.importItem, self.navigationViewController.activityIndicator, self.navigationViewController.middleSpacer, self.neuAlbumButton, self.searchBar, self.sortButton];
    [self.navigationViewController setToolbarItems:items];
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
    
    [_sortButton setLabel:@"Sort Albums"];
    [_sortButton setPaletteLabel:@"Sort Albums"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_sortButton setToolTip:@"Choose Album Sort"];
    
    
    // Tell the item what message to send when it is clicked
    
    [buttonView insertItemWithTitle:@"" atIndex:0]; // first index is always the title
    [buttonView insertItemWithTitle:@"New to Old" atIndex:1];
    [buttonView insertItemWithTitle:@"Old to New" atIndex:2];
    [buttonView insertItemWithTitle:@"A to Z" atIndex:3];
    [buttonView insertItemWithTitle:@"Z to A" atIndex:4];
    
    NSMenuItem * item = [[buttonView itemArray] objectAtIndex:0];
    item.image = [NSImage imageNamed:@"sortbutton"];
    [item.image setTemplate:YES];
    
    
    int sortOrder = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"PIXAlbumSort"];
    
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
        [[NSUserDefaults standardUserDefaults] setInteger:[thisItem tag] forKey:@"PIXAlbumSort"];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // update any albums views
        [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
        
    }
}

- (NSToolbarItem *)importItem
{
    if(_importItem != nil) return _importItem;
    
    _importItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"importAlbumButton"];
    //_settingsButton.image = [NSImage imageNamed:NSImageNameSmartBadgeTemplate];
    
    NSButton * buttonView = [[NSButton alloc] initWithFrame:CGRectMake(0, -2, 60, 25)];
    
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
    PIXAlbum * currentAlbum = nil;

    if (self.collectionView)
    if(self.selectedItems.count == 1)
    {
        currentAlbum = [self.selectedItems anyObject];
    }
    
    [[PIXFileManager sharedInstance] importPhotosToAlbum:currentAlbum allowDirectories:YES];
}

- (NSToolbarItem *)neuAlbumButton
{
    if(_neuAlbumButton != nil) return _neuAlbumButton;
    
    _neuAlbumButton = [[NSToolbarItem alloc] initWithItemIdentifier:@"NewAlbumButton"];
    //_settingsButton.image = [NSImage imageNamed:NSImageNameSmartBadgeTemplate];
    
    NSButton * buttonView = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 100, 25)];
    buttonView.image = [NSImage imageNamed:@"addbutton"];
    [buttonView.image setTemplate:YES];
    [buttonView setImagePosition:NSImageLeft];
    [buttonView setBordered:YES];
    [buttonView setBezelStyle:NSTexturedSquareBezelStyle];
    [buttonView setTitle:@"New Album"];
    
    [buttonView setFont:[NSFont fontWithName:@"Helvetica" size:13]];
    
    _neuAlbumButton.view = buttonView;
    
    [_neuAlbumButton setLabel:@"New Album"];
    [_neuAlbumButton setPaletteLabel:@"New Album"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_neuAlbumButton setToolTip:@"Create a New Album"];
    
    // Tell the item what message to send when it is clicked
    [buttonView setTarget:self];
    [buttonView setAction:@selector(newAlbumPressed:)];
    
    return _neuAlbumButton;
    
}

- (IBAction)newAlbumPressed:(id)sender
{
    
    // turn off the search if needed
    if(self.searchedAlbums)
    {
        self.searchField.stringValue = @"";
        [self updateSearch];
    }
    
    PIXAlbum * newAlbum = [[PIXFileManager sharedInstance] createAlbumWithName:@"New Album"];
    
    // the above method will automatically call a notification that causes the album list to refresh
    
    NSUInteger index = [self.albums indexOfObject:newAlbum];

    NSAssert(index != NSNotFound, @"We should always find the album");

    // select just this item
    self.collectionView.selectionIndexPaths = [NSSet setWithObject:[NSIndexPath indexPathForItem:index inSection:0]];
    [self updateCollectionToolbar];

    /*
    // this will scroll to the item and make the text field the first responder
    PIXAlbumGridViewItem * item = (PIXAlbumGridViewItem *)[self.collectionView scrollToAndReturnItemAtIndex:index animated:YES];
    */
    PIXCollectionViewItem * item = (PIXCollectionViewItem *)[self.collectionView itemAtIndex:index];
    if( item != nil )
    {
        PIXAlbumCollectionViewItemView * itemView = (PIXAlbumCollectionViewItemView *)item.view;
        double delayInSeconds = 0.2;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [itemView startEditing];
        });
    }
    
    //[self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    
    //[self.outlineView editColumn:0 row:index withEvent:nil select:YES];
    //[self.outlineView scrollRowToVisible:index];
    
}

- (NSToolbarItem *)searchBar
{
    if(_searchBar != nil) return _searchBar;
    
    self.searchField = [[NSSearchField alloc] initWithFrame:CGRectMake(0, 0, 150, 55)];
    //[searchField setFont:[NSFont systemFontOfSize:18]];
    
    //[self.searchField setFocusRingType:NSFocusRingTypeNone];
    self.searchField.delegate = self;
    [(NSFormCell *) self.searchField.cell setPlaceholderString:@"Search Albums"];
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

- (void)updateCollectionToolbar {
    NSUInteger count = self.collectionView.selectionIndexPaths.count;
    if (count == 0) {
        [self.toolbar hideToolbar:YES];
    } else {
        [self.toolbar showToolbar:YES];
    }
    [self.toolbar setTitle:[NSString localizedStringWithFormat:NSLocalizedString(@"%lu photo(s) selected", @"Number of selected photos"), (unsigned long)count]];
}

- (void)setupCollectionToolbar {
    PIXCustomButton * deleteButton = [[PIXCustomButton alloc] initWithFrame:CGRectMake(0, 0, 80, 25)];
    if([self.selectedItems count] > 1) {
        [deleteButton setTitle:[NSString stringWithFormat:@"Delete %ld Albums", [self.selectedItems count]]];
    } else {
        [deleteButton setTitle:@"Delete Album"];
    }
    [deleteButton setTarget:self];
    [deleteButton setAction:@selector(deleteItems:)];

    PIXCustomButton * shareButton = [[PIXCustomButton alloc] initWithFrame:CGRectMake(0, 0, 80, 25)];
    [shareButton setTitle:@"Share"];
    [shareButton setTarget:self];
    [shareButton setAction:@selector(share:)];

    PIXCustomButton * mergeButton = [[PIXCustomButton alloc] initWithFrame:CGRectMake(0, 0, 80, 25)];
    [mergeButton setTitle:@"Merge Albums"];
    [mergeButton setTarget:self];


    [self.toolbar setButtons:@[deleteButton]];

    // keep the the currently selected album updated for importing photos
    if([self.selectedItems count] == 1) {
        [[PIXAppDelegate sharedAppDelegate] setCurrentlySelectedAlbum:[self.selectedItems anyObject]];
    } else {
        [[PIXAppDelegate sharedAppDelegate] setCurrentlySelectedAlbum:nil];
    }
    
}

- (void)share:(id)sender
{
    [[PIXShareManager defaultShareManager] showShareSheetForItems:[self.selectedItems allObjects]
                                                   relativeToRect:[sender bounds]
                                                           ofView:sender
                                                    preferredEdge:NSMaxXEdge];
}

- (IBAction)deleteItems:(id)inSender
{
    NSSet<NSIndexPath *> *selectionIndexPaths = self.collectionView.selectionIndexPaths;
    if (selectionIndexPaths.count == 0) {
        return;
    }

    [PIXFileManager.sharedInstance deleteItemsWorkflow:self.selectedItems];
}

#pragma mark - Album
- (void)albumsChanged:(NSNotification *)note
{
    // retain the old set of albums so they won't be released on change
    NSArray * oldAlbums = self.albums;
    
    // set the new one
    self.albums = [PIXAlbum sortedAlbums];
    //[self.collectionView reloadData]; // the updateSearch call will reload data always so no need to call this
    [self updateGridTitle];
    
    self.lastSearch = nil; // clear this out because we need to do a new search when all the albums change
    [self updateSearch];
    
    // this does nothing and is just to keep the old albums retained during the execution of this method
    [oldAlbums count];
    
    
    if([self.albums count] == 0 && ![[NSUserDefaults standardUserDefaults] boolForKey:kDeepScanIncompleteKey])
    {
        [self.centerStatusView setHidden:NO];
        
        NSArray * directoryURLs = [[PIXFileParser sharedFileParser] observedDirectories];
        
        NSString * rootFolderInfo = nil;
        
        if([directoryURLs count])
        {
            rootFolderInfo = [NSString stringWithFormat:@"Current Folder: %@", [(NSURL *)[directoryURLs objectAtIndex:0] path]];
            [self.centerStatusViewSubTextField setStringValue:rootFolderInfo];
        }
        
        else
        {
            [self.centerStatusViewSubTextField setStringValue:@"No Current Folder"];
        }
        
        
    }
    
    else
    {
        [self.centerStatusView setHidden:YES];
    }
    
    //NSLog(@"updated");
    
}

- (void)albumRenamed:(NSNotification *)notification
{
    PIXAlbum * album = [notification object];
    
    if(album)
    {
        NSUInteger index = [self.albums indexOfObject:album];
        
        if(index != NSNotFound)
        {
#warning Uncomment the following line
            //[self.collectionView scrollToAndReturnItemAtIndex:index animated:YES];
        }
    }
}

- (NSArray *)albums
{
    if(_albums != nil) return _albums;
    
    _albums = [PIXAlbum sortedAlbums];
    
    return _albums;
}

- (PIXAlbum *)albumForIndex:(NSInteger)index
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

- (NSInteger)indexForAlbum:(PIXAlbum *)album
{
    if(self.searchedAlbums)
    {
        return [self.searchedAlbums indexOfObject:album];
    }
    
    return [self.albums indexOfObject:album];
}

- (PIXSplitViewController *) aSplitViewController
{
    if(_aSplitViewController != nil) return _aSplitViewController;
    
    _aSplitViewController = [[PIXSplitViewController alloc] initWithNibName:@"PIXSplitViewController" bundle:nil];
    
    _aSplitViewController.delegate = self;
    
    return _aSplitViewController;
    
}

//PIXSplitViewControllerDelegate
-(void)albumSelected:(PIXAlbum *)anAlbum atIndex:(NSUInteger)index;
{
    PIXAlbum *myAlbum = [self albumForIndex:index];
    if (![myAlbum.path isEqualToString:anAlbum.path]) {
        DLog(@"Albums at same indexes don't match between split and album view controllers. index : %ld", index);
        index = [self indexForAlbum:anAlbum];
        if (index!= NSNotFound) {
            DLog(@"Found index at %ld", index);
        } else {
            index = -1;
        }
    }
    
    if (index != -1) {
        self.collectionView.selectionIndexPaths = [NSSet setWithObject:[NSIndexPath indexPathForItem:index inSection:0]];
    }
}

#pragma mark - Clicks

- (void)collectionItemViewDoubleClick:(id)sender {
    PIXAlbumCollectionViewItem *item = sender;
    [self showPhotosForAlbum:item.representedObject];
}

#pragma mark - Selection
- (NSSet<PIXAlbum *> *)selectedItems {
    NSSet<NSIndexPath *> *selectionIndexPaths = self.collectionView.selectionIndexPaths;
    if (selectionIndexPaths.count == 0) {
        return [NSSet set];
    }

    NSArray<NSIndexPath *> *selectionArray = [selectionIndexPaths sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO]]];
    NSMutableSet<PIXAlbum *> *items = [NSMutableSet setWithCapacity:selectionArray.count];
    for (NSIndexPath *item in selectionArray) {
        PIXAlbum *album = self.albums[item.item];
        [items addObject:album];
    }

    return items;
}

- (void)highlightIndexPaths:(NSSet<NSIndexPath *> *)indexPaths selected:(BOOL)selected {
    for (NSIndexPath *indexPath in indexPaths) {
        NSCollectionViewItem *item = [self.collectionView itemAtIndexPath:indexPath];
        if (item) {
            ((PIXCollectionViewItem *) item).selected = selected;
        }
    }

    NSUInteger count = self.collectionView.selectionIndexPaths.count;
    if (count == 0) {
        [self.toolbar hideToolbar:YES];
    } else {
        [self.toolbar showToolbar:YES];
    }

    [self.toolbar setTitle:[NSString localizedStringWithFormat:NSLocalizedString(@"%lu album(s) selected", @"Number of selected albums"), (unsigned long)count]];
}

-(void)reselectItems:(NSArray *)itemsToReselect
{
    NSMutableSet<NSIndexPath *> *indices = [NSMutableSet setWithCapacity:itemsToReselect.count];
    for (NSObject *item in itemsToReselect) {
        NSUInteger index = [self.albums indexOfObject:item];
        if (index != NSNotFound) {
            [indices addObject:[NSIndexPath indexPathForItem:index inSection:0]];
        }
    }
    self.collectionView.animator.selectionIndexPaths = indices;

    NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
    [undoManager registerUndoWithTarget:self selector:@selector(gridViewDidDeselectAllItems:) object:self.collectionView];
    [undoManager setActionName:@"Deselect Albums"];
    [undoManager setActionIsDiscardable:YES];
}

#pragma mark - Filtering
- (void)updateSearch
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

    [self updateCollectionToolbar];
    [self updateGridTitle];

    // TODO filter the items
//
//    // Remove Old Albums
//    NSArray * oldAlbums = [self.arrayController arrangedObjects];
//    [self.arrayController removeObjects:oldAlbums];
//
//    // Add New Albums
//    [self.arrayController addObjects:visibleArray];
}

- (void)updateGridTitle
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

-(void)showPhotosForAlbum:(id)anAlbum
{
    self.aSplitViewController.selectedAlbum = anAlbum;
    [self.navigationViewController pushViewController:self.aSplitViewController];
}

#pragma mark - Keyboard
-(void)keyDown:(NSEvent *)event
{
    if ([event type] == NSKeyDown)
    {
        NSString* pressedChars = [event characters];
        if ([pressedChars length] == 1)
        {
            unichar pressedUnichar = [pressedChars characterAtIndex:0];
            
            if(pressedUnichar == 'f') // f should togge fullscreen
            {
                [self.view.window toggleFullScreen:event];
                return;
            }
            
        }
    }
    
    [super keyDown:event];
}

#pragma mark - NSCollectionViewDataSource Methods

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.albums.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    PIXAlbumCollectionViewItem *item = [collectionView makeItemWithIdentifier:@"PIXAlbumCollectionViewItem" forIndexPath:indexPath];
    item.representedObject = self.albums[indexPath.item];
    return item;
}

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView {
    return 1;
}

#pragma mark - NSCollectionViewDelegate Methods

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    [self highlightIndexPaths:indexPaths selected:YES];
}

- (void)collectionView:(NSCollectionView *)collectionView didDeselectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    [self highlightIndexPaths:indexPaths selected:NO];
}

// TODO handle double click

#pragma mark - Drop Operations
- (NSDragOperation)dropOperationsForDrag:(id < NSDraggingInfo >)sender
{
    // for now don't accept drags from our own app
    if([sender draggingSource] != nil)
    {
        return NSDragOperationNone;
    }
    
    if([NSEvent modifierFlags] & NSAlternateKeyMask)
    {
        return NSDragOperationMove;
    }
    
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    // for now don't accept drags from our own app
    if([sender draggingSource] != nil)
    {
        return NSDragOperationNone;
    }
    
    // here we need to return the kind of drop operation allowed. This is where we decide if its a copy or move
    if([NSEvent modifierFlags] & NSAlternateKeyMask)
    {
        return NSDragOperationMove;
    }
    
    return NSDragOperationCopy;
}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender
{
    // here we need to return NO if we can't accept the drag
    
    // for now don't accept drags from our own app
    if([sender draggingSource] != nil)
    {
        return NO;
    }
    
    
    return YES;
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
{
    // for now don't accept drags from our own app
    if([sender draggingSource] != nil)
    {
        return NO;
    }
    
    
    // here we need perform the operation for the drop
    
    return YES;
}

@end
