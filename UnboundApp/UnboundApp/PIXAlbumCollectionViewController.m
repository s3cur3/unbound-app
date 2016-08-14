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

@interface PIXAlbumCollectionViewController () <PIXGridViewDelegate, PIXSplitViewControllerDelegate>

@property(nonatomic,strong) NSArray * albums;
@property(nonatomic,strong) NSArray * searchedAlbums;

@property (nonatomic, strong) NSToolbarItem * trashbutton;
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
    [self.gridView setItemSize:NSMakeSize(190, 210)];
    [self.gridView setAllowsMultipleSelection:YES];
    [self.gridView reloadData];
    [self.gridView setUseHover:NO];
    */
    
    [self.gridView setAllowsMultipleSelection:YES];
    [self.gridView setItemSize:NSMakeSize(190, 210)];
    [self.gridView setGridViewDelegate:self];
    
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
    
    [self setBGColor];
    
    [self albumsChanged:nil];
    
}

- (void)willShowPIXView
{
    [super willShowPIXView];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // make ourselves the first responder after we're added
        [self.view.window makeFirstResponder:self.gridView];
        //        [self setNextResponder:self.scrollView];
        //        [self.gridView setNextResponder:self];
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
    
    [self hideToolbar:NO];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateToolbar];
    });
    
    
    [[PIXLeapInputManager sharedInstance] addResponder:self.gridView];
    
    [[PIXFileParser sharedFileParser] addObserver:self forKeyPath:@"fullScanProgress" options:NSKeyValueObservingOptionNew context:nil];
    
    [[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] setTitle:@"Unbound"];
    
    [self.gridView reloadSelection];
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
    
    [[PIXLeapInputManager sharedInstance] removeResponder:self.gridView];
    
    [[PIXFileParser sharedFileParser] removeObserver:self forKeyPath:@"fullScanProgress"];
}

- (void)defaultThemeChanged:(NSNotification *)note
{
    [self setBGColor];
    [self.gridView setNeedsDisplay:YES];
    
    for(NSView * item in self.gridView.subviews)
    {
        [item setNeedsDisplay:YES];
    }
    
}

- (void)setBGColor
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

#pragma mark - ToolBar
- (void)setupToolbar
{
    NSArray * items = @[self.importItem, self.navigationViewController.activityIndicator, self.navigationViewController.middleSpacer, self.neuAlbumButton, self.searchBar, self.sortButton];
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
    [buttonView setAction:@selector(clearDatabase)];
    
#endif
    
    
    return _trashbutton;
    
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
    [buttonView.cell setArrowPosition:NSPopUpNoArrow];
    
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
    [self.selectedItems removeAllObjects];
    [self.selectedItems addObject:newAlbum];
    [self.gridView reloadSelection];
    [self updateToolbar];

    /*
    // this will scroll to the item and make the text field the first responder
    PIXAlbumGridViewItem * item = (PIXAlbumGridViewItem *)[self.gridView scrollToAndReturnItemAtIndex:index animated:YES];
    */
    PIXCollectionViewItem * item = (PIXCollectionViewItem *)[self.gridView itemAtIndex:index];
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

-(void)updateToolbar
{
    [super updateToolbar];
    
    PIXCustomButton * deleteButton = [[PIXCustomButton alloc] initWithFrame:CGRectMake(0, 0, 80, 25)];
    [deleteButton setTitle:@"Delete Album"];
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
        [deleteButton setTitle:[NSString stringWithFormat:@"Delete %ld Albums", [self.selectedItems count]]];
        [self.toolbar setButtons:@[deleteButton]];
    }
    
    else
    {
        [self.toolbar setButtons:@[deleteButton]];
    }
    
    // keep the the currently selected album updated for importing photos
    if([self.selectedItems count] == 1)
    {
        [[PIXAppDelegate sharedAppDelegate] setCurrentlySelectedAlbum:[self.selectedItems anyObject]];
    }
    
    else
    {
        [[PIXAppDelegate sharedAppDelegate] setCurrentlySelectedAlbum:nil];
    }
    
}

- (void)share:(id)sender
{
    [[PIXShareManager defaultShareManager] showShareSheetForItems:[self.selectedItems allObjects]
                                                   relativeToRect:[sender bounds]
                                                           ofView:sender
                                                    preferredEdge:NSMaxXEdge];
    /*
     PIXCustomShareSheetViewController *controller = [[PIXCustomShareSheetViewController alloc] initWithNibName:@"PIXCustomShareSheetViewController"     bundle:nil];
     
     [controller setAlbumsToShare:[self.selectedItems allObjects]];
     
     NSPopover *popover = [[NSPopover alloc] init];
     
     [popover setContentViewController:controller];
     [popover setAnimates:YES];
     [popover setBehavior:NSPopoverBehaviorTransient];
     [popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];*/
    
}

- (IBAction)deleteItems:(id)inSender
{
    // if we have nothing to delete then do nothing
    if([self.selectedItems count] == 0) return;
    
    [[PIXFileManager sharedInstance] deleteItemsWorkflow:self.selectedItems];
    
}

#pragma mark - Album
- (void)albumsChanged:(NSNotification *)note
{
    // retain the old set of albums so they won't be released on change
    NSArray * oldAlbums = self.albums;
    
    // set the new one
    self.albums = [PIXAlbum sortedAlbums];
    //[self.gridView reloadData]; // the updateSearch call will reload data always so no need to call this
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
            //[self.gridView scrollToAndReturnItemAtIndex:index animated:YES];
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
        [self.selectedItems removeAllObjects];
        [self.selectedItems addObject:myAlbum];
        
        [self.gridView reloadSelection];
        
        /*
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.gridView scrollToAndReturnItemAtIndex:index animated:NO];
        });
         */
    }
}

#pragma mark - Selection
-(void)reselectItems:(NSArray *)itemsToReselect
{
    [self.selectedItems removeAllObjects];
    
    for(NSObject * item in itemsToReselect)
    {
        if([self.albums containsObject:item])
        {
            [self.selectedItems addObject:item];
        }
    }
    
    [self updateToolbar];
    [self.gridView reloadSelection];
    
    NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
    [undoManager registerUndoWithTarget:self selector:@selector(gridViewDidDeselectAllItems:) object:self.gridView];
    [undoManager setActionName:@"Deselect Albums"];
    [undoManager setActionIsDiscardable:YES];
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
    
    
    // Remove Old Albums
    NSArray * oldAlbums = [self.arrayController arrangedObjects];
    [self.arrayController removeObjects:oldAlbums];
    
    // Add New Albums
    [self.arrayController addObjects:visibleArray];
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

#pragma mark - PIXGridViewDelegate
- (void)gridView:(PIXGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    //[gridView deselectAllItems];
    
    if(index == NSNotFound) return;
    
    //DLog(@"didDoubleClickItemAtIndex: %li", index);
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

- (void)gridView:(PIXGridView *)gridView rightMouseButtonClickedOnItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event
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

- (BOOL)gridView:(PIXGridView *)gridView itemIsSelectedAtIndex:(NSInteger)index inSection:(NSInteger)section
{
    return [self.selectedItems containsObject:[self albumForIndex:index]];
}

- (void)gridView:(PIXGridView*)gridView didSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [self.selectedItems addObject:[self albumForIndex:index]];
    
    [self updateToolbar];
}

- (void)gridView:(PIXGridView*)gridView didDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [self.selectedItems removeObject:[self albumForIndex:index]];
    
    [self updateToolbar];
}

- (void)gridView:(PIXGridView*)gridView didShiftSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
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
            NSUInteger thisIndex = [self indexForAlbum:aSelectedAlbum];
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

- (void)gridViewDidDeselectAllItems:(PIXGridView *)gridView
{
    NSArray * oldItems = [self.selectedItems copy];
    
    [self.selectedItems removeAllObjects];
    [self updateToolbar];
    
    [self.gridView reloadSelection];
    
    NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
    //NSDictionary *undoInfo = @{@"albumID" : anAlbum.objectID, @"name" : oldAlbumName};
    [undoManager registerUndoWithTarget:self selector:@selector(reselectItems:) object:oldItems];
    [undoManager setActionName:@"Deselect Albums"];
    [undoManager setActionIsDiscardable:YES];
}

- (void)gridView:(PIXGridView *)gridView dragDidBeginAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event
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
    
    NSImage * dragImage = [PIXAlbumCollectionViewItemView dragImageForAlbums:selectedArray size:NSMakeSize(180, 180)];
    [self.gridView dragImage:dragImage at:location offset:NSZeroSize event:event pasteboard:dragPBoard source:self slideBack:YES];
}

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
