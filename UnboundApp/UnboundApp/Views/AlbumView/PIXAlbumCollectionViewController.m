//
//  PIXAlbumCollectionViewController.m
//  UnboundApp
//
//  Created by Ditriol Wei on 28/7/16.
//  Copyright © 2016 Pixite Apps LLC. All rights reserved.
//

#import "PIXAlbumCollectionViewController.h"
#import "PIXSplitViewController.h"
#import "Unbound-Swift.h"
#import "PIXDefines.h"
#import "PIXAppDelegate.h"
#import "PIXFileParser.h"
#import "PIXFileManager.h"
#import "PIXAlbum.h"
#import "PIXShareManager.h"

#import "PIXAlbumCollectionViewItem.h"
#import "PIXCollectionToolbar.h"
#import "PIXCollectionView.h"
#import "PIXApplicationExtensions.h"

@interface PIXAlbumCollectionViewController () <NSCollectionViewDelegate, NSCollectionViewDataSource, PIXSplitViewControllerDelegate, NSSearchFieldDelegate>

@property (strong) PIXAlbumCollectionViewItem *clickedItem;
@property(nonatomic,strong) NSArray * albums;

@property (nonatomic, strong) NSToolbarItem * sortButton;
@property (nonatomic, strong) NSToolbarItem * neuAlbumButton;
@property (nonatomic, strong) NSToolbarItem * searchBar;
@property (nonatomic, strong) NSToolbarItem * importItem;
@property (nonatomic, strong) NSToolbarItem * observeNewDirectory;
@property (nonatomic, strong) NSSearchField * searchField;

@property (nonatomic, strong) PIXSplitViewController *aSplitViewController;

@property BOOL isMountDisconnected;

- (void)updateCenterSetupView;
- (void)albumsCreated:(NSNotification *)notification;

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

	NSViewController * childLibPicker = [LibraryPickerObjCBridge makeLibraryPickerForFirstRunWithLib:PIXAppDelegate.sharedAppDelegate.libraryDirs];
    [self addChildViewController:childLibPicker];
    [childLibPicker.view setFrame:[self.centerLibraryPicker bounds]];
    [self.centerLibraryPicker addSubview:childLibPicker.view];
	
	[self updateCenterSetupView];
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.collectionView.delegate = self;

    self.toolbar.collectionView = self.collectionView;
    
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(albumsChanged:) name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
	[nc addObserver:self selector:@selector(albumRenamed:)  name:AlbumWasRenamedNotification       object:nil];
	[nc addObserver:self selector:@selector(albumsCreated:) name:AlbumsCreatedNotification         object:nil];

    [self.scrollView setIdentifier:@"albumGridScroller"];

    NSCollectionViewFlowLayout *flowLayout = [[NSCollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = NSMakeSize(190, 210);
    flowLayout.sectionInset = NSEdgeInsetsMake(5, 5, 5, 5);
    flowLayout.minimumInteritemSpacing = 10;
    flowLayout.minimumLineSpacing = 10;
    self.collectionView.collectionViewLayout = flowLayout;

    [self setupCollectionToolbar];

    [self albumsChanged:nil];
}

- (void)willShowPIXView
{
    [super willShowPIXView];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // make ourselves the first responder after we're added
        [self.view.window makeFirstResponder:self.collectionView];
    });
    
    
    [[self.view window] setTitle:@"Unbound"];

    NSString * searchString = [[NSUserDefaults standardUserDefaults] objectForKey:@"PIX_AlbumSearchString"];
    if(searchString != nil) {
        [self.searchField setStringValue:searchString];
    } else {
        [self.searchField setStringValue:@""];
    }

    [self updateToolbarForAlbums];
    
    [[PIXFileParser sharedFileParser] addObserver:self forKeyPath:@"fullScanProgress" options:NSKeyValueObservingOptionNew context:nil];
    
	NSWindow * window = [[[PIXAppDelegate sharedAppDelegate] mainWindowController] window];
    [window setTitle:@"Unbound"];
    #if TRIAL
        // Gotta have enough room for the big "go to Mac App Store" button next to the centered title
        [window setMinSize:NSMakeSize(855, 480)];
	#else
        [window setMinSize:NSMakeSize(720, 480)];
	#endif

    self.navigationViewController.leftToolbarItems = @[self.observeNewDirectory, self.importItem];
    self.navigationViewController.rightToolbarItems = @[self.self.neuAlbumButton, self.sortButton, self.searchBar];
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

#pragma mark - ToolBar

- (NSToolbarItem *)sortButton
{
    if(_sortButton == nil) {
        _sortButton = [ToolbarButton makeAlbumSortWithTarget:self selector:@selector(sortChanged:)];
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
        [thisItem setState:NSControlStateValueOn];
        [[NSUserDefaults standardUserDefaults] setInteger:[thisItem tag] forKey:kPrefAlbumSortOrder];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // update any albums views
        [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
    }
}

- (NSToolbarItem *)importItem
{
    if(_importItem != nil) return _importItem;
    
    _importItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"importAlbumButton"];
    [_importItem setLabel:@"Copy Photos into Library"];
    [_importItem setPaletteLabel:@"Copy Photos into Library"];
    [_importItem setToolTip:@"Copy photos into library"];

    NSButton *button = [[ToolbarButton alloc] initWithImageNamed:@"ic_import" target:self action:@selector(importPhotosPressed:)];
    _importItem.view = button;

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

- (NSToolbarItem *)observeNewDirectory
{
	if(_observeNewDirectory != nil) return _observeNewDirectory;

	_observeNewDirectory = [[NSToolbarItem alloc] initWithItemIdentifier:@"observeNewDirectoryButton"];
	[_observeNewDirectory setTitle:@"Add Existing Folder to Scan"];
	[_observeNewDirectory setLabel:@"Scan Existing Folder"];
	[_observeNewDirectory setPaletteLabel:@"Scan Existing Folder"];
	[_observeNewDirectory setToolTip:@"Scan an existing folder for photos"];

	NSButton *button = [[ToolbarButton alloc] initWithImageNamed:@"ic_folder_check" target:self action:@selector(observeNewDirectoryPressed:)];
	_observeNewDirectory.view = button;

	return _observeNewDirectory;
}

-(void)observeNewDirectoryPressed:(id)sender
{
	LibraryDirectoriesObjCBridge * sharedLibDirs = PIXAppDelegate.sharedAppDelegate.libraryDirs;
	NSArray * selections = [LibraryDirectoryObjCBridge chooseFromSystemDialogWithExisting:sharedLibDirs];
	if(selections.count > 0) {
		[sharedLibDirs addLibDirs:selections];
	}
}

- (NSToolbarItem *)neuAlbumButton
{
    if(_neuAlbumButton != nil) return _neuAlbumButton;
    
    _neuAlbumButton = [[NSToolbarItem alloc] initWithItemIdentifier:@"NewAlbumButton"];
    _neuAlbumButton.label = NSLocalizedString(@"New Folder", @"New Folder");
    _neuAlbumButton.paletteLabel = NSLocalizedString(@"New Folder", @"New Folder");
    _neuAlbumButton.toolTip = NSLocalizedString(@"Create new folder", @"Create new folder");

    NSButton *buttonView = [[ToolbarButton alloc] initWithImageNamed:@"ic_folder_plus" target:self action:@selector(newAlbumPressed:)];
    _neuAlbumButton.view = buttonView;

    return _neuAlbumButton;
}

- (IBAction)newAlbumPressed:(id)sender
{
    
    // turn off the search if needed
    self.searchField.stringValue = @"";
    
    PIXAlbum * newAlbum = [[PIXFileManager sharedInstance] createAlbumWithName:@"New Folder"];
    
    // the above method will automatically call a notification that causes the album list to refresh
    
    NSUInteger index = [self.albums indexOfObject:newAlbum];

    NSAssert(index != NSNotFound, @"We should always find the album");

    // select just this item
    self.collectionView.selectionIndexPaths = [NSSet setWithObject:[NSIndexPath indexPathForItem:index inSection:0]];
    [self updateToolbarForAlbums];

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
    self.searchField.delegate = self;
    self.searchField.sendsWholeSearchString = YES;
    self.searchField.sendsSearchStringImmediately = NO;
    self.searchField.placeholderString = NSLocalizedString(@"Search Albums", @"Album Search placeholder string.");
    self.searchField.font = [NSFont fontWithName:@"Helvetica" size:13];
    
    _searchBar = [[NSToolbarItem alloc] initWithItemIdentifier:@"SearchBar"];
    
    [_searchBar setView:self.searchField];
    
    [_searchBar setLabel:@"Search"];
    [_searchBar setPaletteLabel:@"Search"];
    
    return _searchBar;
}

- (void)setupCollectionToolbar {
    NSButton * deleteButton = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 80, 25)];
    if([self.selectedItems count] > 1) {
        [deleteButton setTitle:[NSString stringWithFormat:@"Delete %ld Albums", [self.selectedItems count]]];
    } else {
        [deleteButton setTitle:@"Delete Album"];
    }
    [deleteButton setTarget:self];
    [deleteButton setAction:@selector(deleteItems:)];

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
	self.collectionView.selectionIndexes = [NSIndexSet new];
	[self updateToolbarForAlbums];
}

#pragma mark - Album

- (void)albumsChanged:(NSNotification *)note
{
    // retain the old set of albums so they won't be released on change
    NSArray * oldAlbums = self.albums;
	NSMutableArray<PIXAlbum *> * prevSelectedAlbums = [NSMutableArray arrayWithCapacity:self.collectionView.selectionIndexPaths.count];
	for(NSIndexPath * idxPath in self.collectionView.selectionIndexPaths)
	{
		if(!idxPath.section && [oldAlbums count] > idxPath.item)
		{
			[prevSelectedAlbums addObject:oldAlbums[idxPath.item]];
		}
	}
    
    // set the new one
    self.albums = [PIXAlbum sortedAlbums:self.searchField.stringValue];
    [self.collectionView reloadData]; // This blows away our previous selection
    [self updateGridTitle];

	// Replace the selection
	NSMutableSet<NSIndexPath *> * newSelection = [NSMutableSet setWithCapacity:prevSelectedAlbums.count];
	for(PIXAlbum * album in prevSelectedAlbums)
	{
		NSUInteger idx = [self.albums indexOfObject:album];
		if(idx != NSNotFound)
		{
			[newSelection addObject:[NSIndexPath indexPathForItem:idx inSection:0]];
		}
	}
	self.collectionView.selectionIndexPaths = newSelection;

	[self updateCenterSetupView];
}

- (void)updateCenterSetupView
{
	BOOL haveAnythingToShow = [self.albums count] > 0;
	[self.centerStatusView setHidden:haveAnythingToShow];
	if(!haveAnythingToShow) {
		NSArray<NSURL *> * directoryURLs = [[PIXFileParser sharedFileParser] observedDirectories];
		if(directoryURLs.count > 0) { // we're observing a directory, it's just totally empty
			NSString * firstLibraryDir = [FileUtilsBridge formatUrlForDisplay:directoryURLs[0]];
			[self.centerStatusViewTextField setStringValue:@"Choose where you keep your photos, or copy into your existing folders"];
			[self.centerImportAlbumBtn setTitle:[NSString stringWithFormat:@"Copy Photos Into %@", firstLibraryDir]];
			self.centerImportAlbumBtn.hidden = NO;
		} else {
			[self.centerStatusViewTextField setStringValue:@"Choose where you keep your photos"];
			self.centerImportAlbumBtn.hidden = YES;
		}
	}
}

- (void)albumsCreated:(NSNotification *)notification
{
	[self albumsChanged:nil]; // force-reload all our albums first, so that we already have the album(s) in question when we try to select them & scroll to them

	NSArray * albums = [notification object];
	if(albums)
	{
		NSMutableSet<NSIndexPath *> * newSelections = [NSMutableSet new];
		for(PIXAlbum * album in albums)
		{
			NSUInteger index = [self.albums indexOfObject:album];
			if(index != NSNotFound)
			{
				[newSelections addObject:[NSIndexPath indexPathForItem:index inSection:0]];
			}
		}
		[self.collectionView scrollToItemsAtIndexPaths:newSelections scrollPosition:NSCollectionViewScrollPositionNearestHorizontalEdge|NSCollectionViewScrollPositionNearestVerticalEdge];
		self.collectionView.selectionIndexPaths = newSelections;
		[self updateToolbarForAlbums];
	}
}

- (void)albumRenamed:(NSNotification *)notification
{
    PIXAlbum * album = [notification object];
    if(album)
    {
        NSUInteger index = [self.albums indexOfObject:album];
        if(index != NSNotFound)
        {
			NSSet<NSIndexPath *> * indices = [NSSet setWithObject:[NSIndexPath indexPathForItem:index inSection:0]];
			[self.collectionView scrollToItemsAtIndexPaths:indices scrollPosition:NSCollectionViewScrollPositionNearestHorizontalEdge|NSCollectionViewScrollPositionNearestVerticalEdge];
        }
    }
}

- (NSArray *)albums
{
    if(_albums != nil) return _albums;
    
    _albums = [PIXAlbum sortedAlbums];
    
    return _albums;
}

- (PIXAlbum *)albumForIndex:(NSInteger)index {
    if(index > [self.albums count]) return nil;
    return [self.albums objectAtIndex:index];
}

- (NSInteger)indexForAlbum:(PIXAlbum *)album {
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
-(void)albumSelected:(PIXAlbum *)anAlbum atIndex:(NSUInteger)index
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

- (void) openItem {
    if (self.clickedItem == nil) return;
    [self openItemAtIndexPath:[self.collectionView indexPathForItem:self.clickedItem]];
}

- (void) revealItems {
    if (self.selectedItems.count == 0) return;

    NSMutableArray<NSURL *> *urls = [NSMutableArray arrayWithCapacity:self.selectedItems.count];
    [self.selectedItems enumerateObjectsUsingBlock:^(PIXAlbum *obj, BOOL *stop) {
        [urls addObject:obj.filePathURL];
    }];
    [NSWorkspace.sharedWorkspace activateFileViewerSelectingURLs:urls];
}

- (void) renameItem {
    if (self.clickedItem == nil) return;

    PIXAlbumCollectionViewItemView *itemView = (PIXAlbumCollectionViewItemView *) self.clickedItem.view;
    [itemView startEditing];
}

#pragma mark - Clicks

- (void)collectionItemViewDoubleClick:(id)sender {
    PIXAlbumCollectionViewItem *item = sender;
    [self showPhotosForAlbum:item.representedObject];
}

- (void)openFirstSelectedItem {
    NSSet<NSIndexPath *> *selection = self.collectionView.selectionIndexPaths;
    if (selection.count > 0) {
        [self openItemAtIndexPath:selection.anyObject];
    }
}

- (void)openItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.item;
    if (index >= 0 && index < self.albums.count) {
        PIXAlbum *album = self.albums[index];
        [self showPhotosForAlbum:album];
    }
}

- (void)rightMouseDown:(NSEvent *)event {
    [super rightMouseDown:event];

    NSPoint localPoint = [self.collectionView convertPoint:event.locationInWindow fromView:nil];
    for (NSCollectionViewItem *item in self.collectionView.visibleItems) {
        if (NSPointInRect(localPoint, item.view.frame)) {
            self.clickedItem = (PIXAlbumCollectionViewItem *) item;
            break;
        }
    }

    if (self.clickedItem != nil) {
        NSMenu *menu = [[NSMenu alloc] init];

        // if the clicked item isn't part of the current selection, reset the current selection
        if (![self.collectionView.selectionIndexPaths containsObject:[self.collectionView indexPathForItem:self.clickedItem]]) {
            self.collectionView.selectionIndexPaths = [NSSet setWithObject:[self.collectionView indexPathForItem:self.clickedItem]];
            [self updateToolbarForAlbums];
        }

        NSUInteger count = self.collectionView.selectionIndexPaths.count;
        if (count > 0) {
            [menu addItemWithTitle:NSLocalizedString(@"menu.open", @"Open") action:@selector(openItem) keyEquivalent:@""];
            [menu addItem:[NSMenuItem separatorItem]];

            [menu addItemWithTitle:NSLocalizedString(@"menu.rename", @"Rename") action:@selector(renameItem) keyEquivalent:@""];

            NSMenuItem *deleteItem = [[NSMenuItem alloc] init];
            deleteItem.title = NSLocalizedString(@"menu.move_to_trash", @"Move to Trash");
            deleteItem.action = @selector(deleteItems:);
            deleteItem.keyEquivalent = [NSString stringWithFormat:@"%c", 0x08];
            deleteItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
            [menu addItem:deleteItem];

            [menu addItem:[NSMenuItem separatorItem]];

            [menu addItemWithTitle:NSLocalizedString(@"menu.reveal", @"Reveal in Finder") action:@selector(revealItems) keyEquivalent:@""];
            [NSMenu popUpContextMenu:menu withEvent:event forView:self.clickedItem.view];
        }
    }

}

#pragma mark - Selection

- (void)selectFirstItem {
    self.collectionView.selectionIndexPaths = [NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]];
}

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
    [self updateToolbarForAlbums];
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

- (void)updateGridTitle
{
    if (self.isSearching) {
        NSString *format = NSLocalizedString(@"%lu album(s) matched search", @"Count albums matching search");
        self.gridViewTitle.stringValue = [NSString stringWithFormat:format, self.albums.count, self.searchField.stringValue];
    } else {
        NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kPhotoEntityName];
        #if TRIAL
            [fetchRequest setFetchLimit:TRIAL_MAX_PHOTOS];
        #endif
        NSUInteger numPhotos = [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] countForFetchRequest:fetchRequest error:nil];

		if(TRIAL && (self.albums.count == TRIAL_MAX_ALBUMS || numPhotos == TRIAL_MAX_PHOTOS))
		{
			self.gridViewTitle.stringValue = [NSString stringWithFormat:@"Trial limited to %d albums & %d photos.", TRIAL_MAX_ALBUMS, TRIAL_MAX_PHOTOS];
		}
        else
		{
			NSString * format = NSLocalizedString(@"%lu album(s) containing %lu photos", @"Count albums and photos");
			self.gridViewTitle.stringValue = [NSString stringWithFormat:format, self.albums.count, numPhotos];
		}
    }
}

-(void)showPhotosForAlbum:(id)anAlbum
{
    self.aSplitViewController.selectedAlbum = anAlbum;
    [self.navigationViewController pushViewControllerWithViewController:self.aSplitViewController];
}

#pragma mark - Search

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    [[NSUserDefaults standardUserDefaults] setObject:self.searchField.stringValue forKey:@"PIX_AlbumSearchString"];

    [self albumsChanged:nil];

    [self updateToolbarForAlbums];
    [self updateGridTitle];
}

- (BOOL)isSearching {
    return self.searchField.stringValue && self.searchField.stringValue.length > 0;
}

#pragma mark - Keyboard
-(void)keyDown:(NSEvent *)event
{
    switch (event.keyCode) {
        case 36: // return
        case 76: // enter
            [self openFirstSelectedItem];
            return;
    }

    if ([@"f" isEqualToString:event.characters]) {
        [self.view.window toggleFullScreen:event];
        return;
    }

    // command modified keystrokes
    int modifiers = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;
    if (modifiers == NSEventModifierFlagCommand) {
        if (event.keyCode == 51) {
            [self deleteItems:nil];
            return;
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

#pragma mark - Drop Operations
- (NSDragOperation)dropOperationsForDrag:(id < NSDraggingInfo >)sender
{
    // for now don't accept drags from our own app
    if([sender draggingSource] != nil)
    {
        return NSDragOperationNone;
    }
    
    if([NSEvent modifierFlags] & NSEventModifierFlagOption)
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
    if([NSEvent modifierFlags] & NSEventModifierFlagOption)
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
