//
//  PIXPhotoCollectionViewController.m
//  UnboundApp
//
//  Created by Ditriol Wei on 14/9/16.
//  Copyright © 2016 Pixite Apps LLC. All rights reserved.
//

#import "PIXPhotoCollectionViewController.h"
#import "PIXAppDelegate.h"
#import "PIXDefines.h"
#import "PIXAlbum.h"
#import "PIXPhoto.h"
#import "PIXPhotoCollectionViewItem.h"
#import "PIXFileManager.h"
#import "PIXShareManager.h"
#import "PIXCollectionToolbar.h"
#import "PIXCollectionView.h"
#import "Unbound-Swift.h"
@import Quartz;

@protocol PhotoItem;

@interface PIXPhotoCollectionViewController () <NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, NSCollectionViewDataSource, QLPreviewPanelDataSource>

@property (nonatomic, strong) NSArray<PIXPhoto *> *photos;
@property (nonatomic, strong) NSObject<PhotoItem> *clickedItem;
@property (nonatomic, strong) NSCollectionViewFlowLayout *layout;
@property (nonatomic, strong) NSDateFormatter * titleDateFormatter;
@property (nonatomic, strong) NSMutableDictionary *prototypes;
@property CGFloat startPinchZoom;
@property CGFloat itemSize;
@property CGFloat targetItemSize;
@property PhotoStyle photoStyle;

- (void)scrollContainerFrameDidChange;

@end

@implementation PIXPhotoCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.collectionView addObserver:self forKeyPath:@"selectionIndexPaths" options:0 context:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.

        self.prototypes = [NSMutableDictionary dictionaryWithCapacity:3];
        self.titleDateFormatter = [[NSDateFormatter alloc] init];
        [self.titleDateFormatter setDateStyle:NSDateFormatterLongStyle];
        [self.titleDateFormatter setTimeStyle:NSDateFormatterNoStyle];
        self.selectedItemsName = @"photo";

        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateAlbum:) name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(photoViewTypeChanged:) name:kNotePhotoStyleChanged object:nil];

        // initialize the photo view type
        [self photoViewTypeChanged:nil];
    }

    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];

    self.collectionView.delegate = self;

    self.toolbar.collectionView = self.collectionView;

    self.layout = [[NSCollectionViewFlowLayout alloc] init];
    self.layout.minimumInteritemSpacing = 2;
    self.layout.minimumLineSpacing = 2;
    self.layout.sectionInset = NSEdgeInsetsMake(2, 2, 2, 2);
    self.collectionView.collectionViewLayout = self.layout;

    self.toolbar.collectionView = self.collectionView;

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(scrollContainerFrameDidChange)
                                               name:NSViewFrameDidChangeNotification
                                             object:self.scrollView];

    self.view.wantsLayer = YES;
    self.collectionView.wantsLayer = YES;

    [self setupToolbar];

    [self updateAlbum:nil];
}

- (void)dealloc {
    [self.collectionView removeObserver:self forKeyPath:@"selectionIndexPaths"];
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selectionIndexPaths"]) {
        if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
            [[QLPreviewPanel sharedPreviewPanel] reloadData];
        }
    }
}

-(void)willShowPIXView
{
    [super willShowPIXView];

    [self updateAlbum:nil];

    // this will allow droping files into the larger grid view
    [self.collectionView registerForDraggedTypes:@[NSPasteboardTypeURL]];

    [self updateToolbarForPhotos];
}

#pragma mark - Background Colors

-(void)keyDown:(NSEvent *)event
{
    DLog("Keycode pressed: %d", event.keyCode);

    switch (event.keyCode) {
        case 36: // return
        case 76: // enter
            [self openFirstSelectedItem];
            return;
        case 49: // space
            [self togglePreviewPanel];
            return;
    }

    int modifiers = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;

    if ([@"f" isEqualToString:event.characters]) {
        [self.view.window toggleFullScreen:event];
        return;
    }

    // command modified keystrokes
    if (modifiers == NSEventModifierFlagCommand) {
        if ([@"e" isEqualToString:event.characters]) {
            [self openInDefaultApp];
            return;
        } else if (event.keyCode == 51) {
            [self deleteItems];
            return;
        } else if ([@"d" isEqualToString:event.characters]) {
            [self duplicateItems];
            return;
        } else if ([@"n" isEqualToString:event.characters] && self.collectionView.selectionIndexPaths.count > 1) {
            [self newFolderWithSelection];
            return;
        }
    }

    [super keyDown:event];
}

// Tyler says: this is suspicious
-(void)updateItemDimensions {
    CGFloat columnCount = (int) (self.scrollView.frame.size.width / (140  + (self.itemSize * 260)));
    CGFloat actualWidth = (self.scrollView.frame.size.width
            - self.layout.sectionInset.left
            - self.layout.sectionInset.right
            - (self.layout.minimumInteritemSpacing * (columnCount - 1))) - 1;
    CGFloat width = actualWidth / columnCount;
    if (width != self.targetItemSize) {
        self.targetItemSize = width;
        self.layout.itemSize = NSMakeSize(width, width);
        [self.collectionView reloadData];
    }
}

// send a size between 0 and 1 (will be transformed into appropriate sizes)
-(void)setThumbSize:(CGFloat)size {
    // Instead of mapping directly to thumbnail sizes, this value will map to number of
    // columns, larger sizes meaning smaller number of columns. The image sizes will
    // roughly equate to 140-400
    self.itemSize = size;
    [self updateItemDimensions];
}

-(void)scrollContainerFrameDidChange {
    [self updateItemDimensions];
}

- (void)photoViewTypeChanged:(NSNotification *)note {
    NSString *styleName = [NSUserDefaults.standardUserDefaults stringForKey:kPrefPhotoStyle];
    if (styleName) {
        if ([styleName isEqualToString:@"Compact"]) {
            self.photoStyle = PhotoStyleCompact;
        } else if ([styleName isEqualToString:@"Regular"]) {
            self.photoStyle = PhotoStyleRegular;
        }
        [self.collectionView reloadData];
    }
}

#pragma mark - Album
-(void)setAlbum:(id)album
{
    if (album != _album) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AlbumDidChangeNotification object:_album];
        [self.collectionView deselectAll:nil];

        _album = album;
        self.photos = _album.sortedPhotos;
        [[[PIXAppDelegate sharedAppDelegate] window] setTitle:[self.album title]];

        self.title = _album.title;
        [self updateToolbarForPhotos];
        [self updateAlbum:nil];

        [self.collectionView scrollPoint:NSZeroPoint];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAlbum:) name:AlbumDidChangeNotification object:_album];

        [self.album checkDates];

        [self.collectionView reloadData];
    }
}

-(void)updateAlbum:(NSNotification *)note
{
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
	NSString *photosCount = [numberFormatter stringFromNumber:@((self.album.photos.count))];

	NSString * gridTitle = nil;
	
	// Only reload if the photos changed, to prevent your selection wigging out on you unnecessarily
	NSArray<PIXPhoto *> * latest = _album.sortedPhotos;
	if(![self.photos isEqualToArray:latest]) {
		NSMutableArray<PIXPhoto *> * prevSelected = [NSMutableArray arrayWithCapacity:self.collectionView.selectionIndexPaths.count];
		for(NSIndexPath * idxPath in self.collectionView.selectionIndexPaths)
		{
			if(!idxPath.section && [self.photos count] > idxPath.item)
			{
				[prevSelected addObject:self.photos[idxPath.item]];
			}
		}
		
		self.photos = latest;
		[self.collectionView reloadData]; // This blows away our previous selection

		// Replace the selection
		NSMutableSet<NSIndexPath *> * newSelection = [NSMutableSet setWithCapacity:prevSelected.count];
		for(PIXPhoto * photo in prevSelected)
		{
			NSUInteger idx = [self.photos indexOfObject:photo];
			if(idx != NSNotFound)
			{
				[newSelection addObject:[NSIndexPath indexPathForItem:idx inSection:0]];
			}
		}
		self.collectionView.selectionIndexPaths = newSelection;
	}

	if(self.album.startDate == nil) {
		if(self.album.photos.count == 1) {
			gridTitle = @"1 photo";
		} else if(self.album.photos.count > 1) {
			gridTitle = [NSString stringWithFormat:@"%@ photos", photosCount];
		} else {
			gridTitle = @"No Photos";
		}
	}
    // if we've got more than one photo then display the whole date range
    else if (self.album.photos.count > 1) {
        NSDate * startDate = [self.album startDate];
        NSDate * endDate = [self.album albumDate];

        NSCalendar* calendar = [NSCalendar currentCalendar];

        unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
        NSDateComponents* startComponents = [calendar components:unitFlags fromDate:startDate];
        NSDateComponents* endComponents = [calendar components:unitFlags fromDate:endDate];

        [self.titleDateFormatter setDateFormat:@"MMMM d, YYYY"];
        if([startComponents year] == [endComponents year])
        {
            // don't show the year on the first date if they're the same
            [self.titleDateFormatter setDateFormat:@"MMMM d"];
        }
        NSString * startDateString = [self.titleDateFormatter stringFromDate:startDate];

        [self.titleDateFormatter setDateFormat:@"MMMM d, YYYY"];

        // if the date goes multiple days print the span
        if(([startComponents day] != [endComponents day] || [startComponents month] != [endComponents month] || [startComponents year] != [endComponents year]) && [startDate compare:endDate] == NSOrderedAscending)
        {
            NSString * endDateString = [self.titleDateFormatter stringFromDate:endDate];
            gridTitle = [NSString stringWithFormat:@"%@ photos from %@ to %@", photosCount, startDateString, endDateString];
        }

        else
        {
            NSString * endDateString = [self.titleDateFormatter stringFromDate:endDate];
            gridTitle = [NSString stringWithFormat:@"%@ photos from %@", photosCount, endDateString];
        }
    }
    else if (self.album.photos.count == 1)
    {
        [self.titleDateFormatter setDateStyle:NSDateFormatterLongStyle];

        gridTitle = [NSString stringWithFormat:@"%@ photo from %@", photosCount, [self.titleDateFormatter stringFromDate:self.album.albumDate]];
    }
    else
    {
        gridTitle = @"No Photos";
    }

    [self.gridViewTitle setStringValue:gridTitle];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateToolbarForPhotos];
    });
}

#pragma mark - Clicks

- (void)collectionItemViewDoubleClick:(id)sender {
    PIXPhotoCollectionViewItemView *item = sender;
    [self openItem:item.photo];
}

- (void)openFirstSelectedItem {
    NSSet<NSIndexPath *> *selection = self.collectionView.selectionIndexPaths;
    if (selection.count > 0) {
        [self openItemAtIndexPath:selection.anyObject];
    }
}

- (void)togglePreviewPanel {
    NSSet<NSIndexPath *> *selection = self.collectionView.selectionIndexPaths;

    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];

    } else if (selection.count > 0) {
        [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
    }
}

- (void)openItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.item;
    if (index >= 0 && index < self.photos.count) {
        PIXPhoto *photo = self.photos[index];
        [self openItem:photo];
    }
}

- (void)openItem:(PIXPhoto *)photo {
    PIXPageViewController *pageViewController = [[PIXPageViewController alloc] initWithNibName:nil bundle:nil];
    pageViewController.initialSelectedObject = photo;
    pageViewController.album = self.album;
    pageViewController.delegate = self;
    [self.navigationViewController pushViewControllerWithViewController:pageViewController];
}

- (void)openItem {
    [self openItem:self.clickedItem.photo];
}

- (void)openInDefaultApp {
    NSString *appName = [[NSUserDefaults standardUserDefaults] stringForKey:@"defaultEditorName"];
    [self.selectedItems enumerateObjectsUsingBlock:^(PIXPhoto *obj, BOOL *stop) {
        if (appName) {
            [NSWorkspace.sharedWorkspace openFile:obj.path withApplication:appName];
        } else {
            [NSWorkspace.sharedWorkspace openFile:obj.path];
        }
    }];
}

- (void)openInApp {
    [self.selectedItems enumerateObjectsUsingBlock:^(PIXPhoto *obj, BOOL *stop) {
        [NSWorkspace.sharedWorkspace openFile:obj.path];
    }];
}

- (void)setDesktopPicture:(id)sender {
    if (![sender isKindOfClass:NSMenuItem.class]) return;

    PIXPhoto *photo = ((NSMenuItem *) sender).representedObject;
    [PIXFileManager.sharedInstance setDesktopImage:photo];
}

- (void)revealItems {
    if (self.selectedItems.count == 0) return;

    NSMutableArray<NSURL *> *urls = [NSMutableArray arrayWithCapacity:self.selectedItems.count];
    [self.selectedItems enumerateObjectsUsingBlock:^(PIXPhoto *obj, BOOL *stop) {
        [urls addObject:obj.filePath];
    }];
    [NSWorkspace.sharedWorkspace activateFileViewerSelectingURLs:urls];
}

- (void)deleteItems {
	NSSet * toDelete = self.selectedItems.count ? self.selectedItems : [NSSet setWithObject:self.album];
    [PIXFileManager.sharedInstance deleteItemsWorkflow:toDelete];
}

- (void)duplicateItems {
    if (self.selectedItems.count == 0) return;

    [PIXFileManager.sharedInstance duplicatePhotos:self.selectedItems];
}

- (void)newFolderWithSelection {
    NSSet<PIXPhoto *> * selected = self.selectedItems;
    if(self.selectedItems.count) {
		NSString * parentPath = self.album.path.stringByDeletingLastPathComponent;
        PIXAlbum * newAlbum = [PIXFileManager.sharedInstance createAlbumAtPath:parentPath withName:@"New Album"];

        NSMutableArray * pathChangeSpec = [NSMutableArray arrayWithCapacity:[selected count]];
        for(PIXPhoto * photo in selected)
        {
            [pathChangeSpec addObject:@{@"source" : photo.path, @"destination" : newAlbum.path}];
        }
        [PIXFileManager.sharedInstance moveFiles:pathChangeSpec];
    }
}

- (void)getInfo {
    if (self.selectedItems.count == 0) return;
    [self.selectedItems enumerateObjectsUsingBlock:^(PIXPhoto *obj, BOOL *stop) {
        NSPasteboard *pboard = [NSPasteboard pasteboardWithUniqueName];
        [pboard declareTypes:@[NSPasteboardTypeString] owner:nil];
        [pboard setString:obj.path forType:NSPasteboardTypeString];
        NSPerformService(@"Finder/Show Info", pboard);
    }];
}

- (void)shareItems:(NSMenuItem *)menuItem {
    NSSharingService *service = menuItem.representedObject;
    NSMutableArray<NSURL *> *urls = [NSMutableArray arrayWithCapacity:self.selectedItems.count];
    [self.selectedItems enumerateObjectsUsingBlock:^(PIXPhoto *obj, BOOL *stop) {
        [urls addObject:obj.filePath];
    }];
    [service performWithItems:urls];
}

- (void)rightMouseDown:(NSEvent *)event {
    [super rightMouseDown:event];

    NSPoint localPoint = [self.collectionView convertPoint:event.locationInWindow fromView:nil];
    for (NSCollectionViewItem *item in self.collectionView.visibleItems) {
        if (NSPointInRect(localPoint, item.view.frame)) {
            self.clickedItem = item;
            break;
        }
    }

    if (self.clickedItem != nil) {
        NSMenu *menu = [[NSMenu alloc] init];

        // if the clicked item isn't part of the current selection, reset the current selection
        if (![self.collectionView.selectionIndexPaths containsObject:[self.collectionView indexPathForItem:self.clickedItem]]) {
            self.collectionView.selectionIndexPaths = [NSSet setWithObject:[self.collectionView indexPathForItem:self.clickedItem]];
            [self updateToolbarForPhotos];
        }

        NSUInteger count = self.collectionView.selectionIndexPaths.count;
        if (count > 0) {
            [menu addItemWithTitle:NSLocalizedString(@"menu.open", @"Open") action:@selector(openItem) keyEquivalent:@""];

            NSMenuItem *duplicateItem = [[NSMenuItem alloc] init];
            duplicateItem.title = NSLocalizedString(@"menu.duplicate", @"Duplicate");
            duplicateItem.action = @selector(duplicateItems);
            duplicateItem.keyEquivalent = @"d";
            duplicateItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
            [menu addItem:duplicateItem];

            NSMutableArray<NSURL *> *urls = [NSMutableArray arrayWithCapacity:self.selectedItems.count];
            [self.selectedItems enumerateObjectsUsingBlock:^(PIXPhoto *obj, BOOL *stop) {
                [urls addObject:obj.filePath];
            }];
            NSArray<NSSharingService *> *sharingServices = [NSSharingService sharingServicesForItems:urls];
            if (sharingServices.count > 0) {
                NSMenu *sharingSubmenu = [[NSMenu alloc] init];
                for (NSSharingService *service in sharingServices) {
                    NSMenuItem *item = [[NSMenuItem alloc] init];
                    item.representedObject = service;
                    item.title = service.menuItemTitle;
                    item.image = service.image;
                    item.action = @selector(shareItems:);
                    [sharingSubmenu addItem:item];
                }

                NSMenuItem *shareItem = [[NSMenuItem alloc] init];
                shareItem.title = NSLocalizedString(@"menu.share", "Share");
                shareItem.submenu = sharingSubmenu;
                [menu addItem:shareItem];
            }

            [menu addItem:[NSMenuItem separatorItem]];

            NSUInteger selectionCount = self.collectionView.selectionIndexPaths.count;
            if(selectionCount > 1) {
				NSMenuItem * newFolderWithSelection = [[NSMenuItem alloc] init];
                newFolderWithSelection.title = [NSString stringWithFormat:NSLocalizedString(@"menu.new_folder_with_selection", @"New Folder with Selection (%lu Items)"), selectionCount];
                newFolderWithSelection.target = self;
                newFolderWithSelection.action = @selector(newFolderWithSelection);
                newFolderWithSelection.keyEquivalent = @"n";
                newFolderWithSelection.keyEquivalentModifierMask = NSEventModifierFlagCommand;
				[menu addItem:newFolderWithSelection];
            }

            NSString *defaultAppName = [[NSUserDefaults standardUserDefaults] stringForKey:@"defaultEditorName"];
            if (!defaultAppName) {
                defaultAppName = [[PIXFileManager sharedInstance] defaultAppNameForOpeningFileWithPath:self.clickedItem.photo.path];
            }
            NSMenuItem *editWithDefault = [[NSMenuItem alloc] init];
            editWithDefault.title = [NSString stringWithFormat:NSLocalizedString(@"menu.edit_with_default", @"Edit with %@"), defaultAppName];
            editWithDefault.target = self;
            editWithDefault.action = @selector(openInDefaultApp);
            editWithDefault.keyEquivalent = @"e";
            editWithDefault.keyEquivalentModifierMask = NSEventModifierFlagCommand;
            [menu addItem:editWithDefault];

            NSMenuItem *editWithMenuItem = [[NSMenuItem alloc] init];
            editWithMenuItem.title = NSLocalizedString(@"menu.edit_with", @"Edit with");
            NSMutableArray<NSString *> *stringPaths = [NSMutableArray arrayWithCapacity:urls.count];
            [urls enumerateObjectsUsingBlock:^(NSURL *obj, NSUInteger idx, BOOL *stop) {
                [stringPaths addObject:obj.path];
            }];
            editWithMenuItem.submenu = [PIXFileManager.sharedInstance openWithMenuItemForFiles:stringPaths];
            [menu addItem:editWithMenuItem];

            [menu addItem:[NSMenuItem separatorItem]];

            [menu addItemWithTitle:NSLocalizedString(@"menu.get_info", @"Get Info") action:@selector(getInfo) keyEquivalent:@""];

            NSMenuItem *deleteItem = [[NSMenuItem alloc] init];
            deleteItem.title = NSLocalizedString(@"menu.move_to_trash", @"Move to Trash");
            deleteItem.action = @selector(deleteItems);
            deleteItem.keyEquivalent = [NSString stringWithFormat:@"%c", 0x08];
            deleteItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
            [menu addItem:deleteItem];

            [menu addItem:[NSMenuItem separatorItem]];

            NSMenuItem *desktopMenuItem = [[NSMenuItem alloc] init];
            desktopMenuItem.title = NSLocalizedString(@"menu.set_desktop_picture", @"Set Desktop Picture");
            desktopMenuItem.action = @selector(setDesktopPicture:);
            desktopMenuItem.representedObject = self.clickedItem.photo;
            [menu addItem:desktopMenuItem];

            [menu addItemWithTitle:NSLocalizedString(@"menu.reveal", @"Reveal in Finder") action:@selector(revealItems) keyEquivalent:@""];
            [NSMenu popUpContextMenu:menu withEvent:event forView:self.clickedItem.view];
        }
    }

}

#pragma mark - PIXPageViewControllerDelegate

-(void)pagerDidMoveToPhotoWithPath:(NSString *)aPhotoPath atIndex:(NSUInteger)index
{
    if (index < self.photos.count) {
        PIXPhoto *photo = self.photos[index];
        if ([photo.path isEqualToString:aPhotoPath]) {
            [self.collectionView deselectAll:nil];
            [self.collectionView selectItemsAtIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:index inSection:0]]
                                          scrollPosition:NSCollectionViewScrollPositionNearestVerticalEdge];
        }
    }
}

#pragma mark - NSCollectionViewDataSource Methods

- (NSString *)photoItemIdentifier {
    switch (self.photoStyle) {
        case PhotoStyleCompact: return @"SimplePhotoItem";
        case PhotoStyleRegular: return @"RegularPhotoItem";
    }
    assert(false); // "Unhandleded photo style"
    return @"SimplePhotoItem";
}

- (NSCollectionViewItem *)photoItemForObjectAtIndexPath:(NSIndexPath *)indexPath inCollectionView:(NSCollectionView *)collectionView {
    return [collectionView makeItemWithIdentifier:self.photoItemIdentifier forIndexPath:indexPath];
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photos.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
	NSCollectionViewItem * item = [self photoItemForObjectAtIndexPath:indexPath inCollectionView:collectionView];
	NSObject<PhotoItem> * photoItem = (NSObject<PhotoItem> *)item;
	photoItem.photo = self.photos[indexPath.item];
    return item;
}

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView {
    return 1;
}

#pragma mark - NSCollectionViewDelegate

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    [self highlightIndexPaths:indexPaths selected:YES];
}

- (void)collectionView:(NSCollectionView *)collectionView didDeselectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    [self highlightIndexPaths:indexPaths selected:NO];
}

- (BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths withEvent:(NSEvent *)event {
    return YES;
}

- (id <NSPasteboardWriting>)collectionView:(NSCollectionView *)collectionView pasteboardWriterForItemAtIndexPath:(NSIndexPath *)indexPath {
    PIXPhoto *photo = self.photos[indexPath.item];
    return photo.filePath;
}

- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSSize size = NSZeroSize;
    PIXPhoto *photo = self.photos[indexPath.item];
    NSSize dimens = photo.dimensions;
    NSSize cellDimens = NSMakeSize(self.targetItemSize, self.targetItemSize);
    if (dimens.width != 0 && dimens.height != 0) {
        CGFloat scale;
        if (dimens.width > dimens.height) {
            scale = cellDimens.width / dimens.width;
        } else {
            scale = cellDimens.height / dimens.height;
        }
        size = NSMakeSize(dimens.width * scale, dimens.height * scale);
    }
    return size;
}

#pragma mark - Selection

- (void)selectFirstItem {
    self.collectionView.selectionIndexPaths = [NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]];
}

- (NSSet<PIXPhoto *> *)selectedItems {
    NSSet<NSIndexPath *> *selectionIndexPaths = self.collectionView.selectionIndexPaths;
    if (selectionIndexPaths.count == 0) {
        return [NSSet set];
    }

    NSArray<NSIndexPath *> *selectionArray = [selectionIndexPaths sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO]]];
    NSMutableSet<PIXPhoto *> *items = [NSMutableSet setWithCapacity:selectionArray.count];
    for (NSIndexPath *item in selectionArray) {
        PIXPhoto *album = self.photos[item.item];
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
    [self updateToolbarForPhotos];
}

#pragma mark - Drop Operation
- (NSDragOperation)dropOperationsForDrag:(id < NSDraggingInfo >)sender
{
    // we can check the files here and return NSDragOperationNone if we can't accept them

    // for now don't accept drags from our own app (this will be used for re-ordering photos later)
    if([sender draggingSource] != nil)
    {
        return NSDragOperationNone;
    }
    NSArray *pathsToPaste = [[PIXFileManager sharedInstance] itemsForDraggingInfo:sender forDestination:self.album.path];
    NSUInteger fileCount = [pathsToPaste count];
    sender.numberOfValidItemsForDrop = fileCount;
    if (fileCount==0) {
        return NSDragOperationNone;
    }

    [sender setNumberOfValidItemsForDrop:fileCount];

    // check the modifier keys and show with operation we support
    if([NSEvent modifierFlags] & NSEventModifierFlagOption)
    {
        return NSDragOperationMove;
    }

    return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    // we can check the files here and return NSDragOperationNone if we can't accept them
    // for now don't accept drags from our own app (this will be used for re-ordering photos later)
    if([sender draggingSource] != nil)
    {
        return NSDragOperationNone;
    }

    // check the modifier keys and show with operation we support
    if([NSEvent modifierFlags] & NSEventModifierFlagOption)
    {
        return NSDragOperationMove;
    }

    return NSDragOperationCopy;
}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender
{
    // here we need to return NO if we can't accept the drag

    // for now don't accept drags from our own app (this will be used for re-ordering photos later)
    if([sender draggingSource] != nil || (sender.numberOfValidItemsForDrop == 0))
    {
        return NO;
    }

    return YES;
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
{
    // for now don't accept drags from our own app (this will be used for re-ordering photos later)
    if([sender draggingSource] != nil || (sender.numberOfValidItemsForDrop == 0))
    {
        return NO;
    }

    NSArray *pathsToPaste = [[PIXFileManager sharedInstance] itemsForDraggingInfo:sender forDestination:self.album.path];
    if (pathsToPaste.count > 0)
    {
        if([NSEvent modifierFlags] & NSEventModifierFlagOption)
        {
            // perform a move here
            [[PIXFileManager sharedInstance] moveFiles:pathsToPaste];
        }

        else
        {
            // perform a copy here
            [[PIXFileManager sharedInstance] copyFiles:pathsToPaste];
        }
    }

    return YES;
}

- (void)setupToolbar {
    NSButton * deleteButton = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 80, 25)];
    [deleteButton setTitle:@"Delete"];
    [deleteButton setTarget:self];
    [deleteButton setAction:@selector(deleteItems:)];

    NSButton * shareButton = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 80, 25)];
    [shareButton setTitle:@"Share"];
    [shareButton setTarget:self];
    [shareButton setAction:@selector(share:)];

    [self.toolbar setButtons:@[deleteButton, shareButton]];
}

- (void)deleteItems:(id)sender {
    NSSet<NSIndexPath *> *selectionIndexPaths = self.collectionView.selectionIndexPaths;
    if (selectionIndexPaths.count == 0) {
        return;
    }

    [PIXFileManager.sharedInstance deleteItemsWorkflow:self.selectedItems];
}

-(void)share:(id)sender
{
    [[PIXShareManager defaultShareManager] showShareSheetForItems:[self.selectedItems allObjects]
                                                   relativeToRect:[sender bounds]
                                                           ofView:sender
                                                    preferredEdge:NSMaxXEdge];

    /*
     PIXCustomShareSheetViewController *controller = [[PIXCustomShareSheetViewController alloc] initWithNibName:@"PIXCustomShareSheetViewController"     bundle:nil];
     
     [controller setPhotosToShare:[self.selectedItems allObjects]];
     
     NSPopover *popover = [[NSPopover alloc] init];
     [popover setContentViewController:controller];
     [popover setAnimates:YES];
     [popover setBehavior:NSPopoverBehaviorTransient];
     [popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
     */
}

// MARK: - QLPreviewPanelDataSource

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel {
    NSSet<NSIndexPath *> *selection = self.collectionView.selectionIndexPaths;
    return selection.count > 0 ? 1 : 0;
}

- (id<QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index {
    NSSet<NSIndexPath *> * selection = self.collectionView.selectionIndexPaths;
    if (selection.count > 0)
	{
        NSInteger selectionIdx = selection.anyObject.item;
        if (selectionIdx >= 0 && selectionIdx < self.photos.count)
		{
            PIXPhoto *photo = self.photos[selectionIdx];
            return photo.filePath;
        }
    }
    return nil;
}

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel {
    return true;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel {
    panel.dataSource = self;
    panel.delegate = self;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel {
    panel.dataSource = nil;
    panel.delegate = nil;
}

// MARK: - QLPreviewPanelDelegate

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event {
    // handle user changing selection via d-pad
    switch (event.keyCode) {
        case 123: // left
        case 124: // right
        case 126: // up
        case 125: // down
            if (event.type == NSEventTypeKeyDown) {
                [self.collectionView keyDown:event];

            } else if (event.type == NSEventTypeKeyUp) {
                [self.collectionView keyUp:event];

            } else {
                break;
            }

            // don't need to manually reload the panel here, because we do that via KVO of the collection view's selection

            return YES;

        default:
            break;
    }

    return NO;
}

@end
