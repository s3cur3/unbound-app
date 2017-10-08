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
#import "PIXNavigationController.h"
#import "PIXSplitViewController.h"
#import "PIXSidebarViewController.h"
#import "PIXPhoto.h"
#import "PIXPhotoCollectionViewItem.h"
#import "PIXFileManager.h"
#import "PIXCustomButton.h"
#import "PIXShareManager.h"
#import "PIXCollectionToolbar.h"
#import "PIXCollectionView.h"

@interface PIXPhotoCollectionViewController () <NSCollectionViewDelegate, NSCollectionViewDataSource>

@property(nonatomic, strong) NSCollectionViewFlowLayout *layout;
@property(nonatomic,strong) NSDateFormatter * titleDateFormatter;
@property CGFloat startPinchZoom;

@end

@implementation PIXPhotoCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.

        self.titleDateFormatter = [[NSDateFormatter alloc] init];
        [self.titleDateFormatter setDateStyle:NSDateFormatterLongStyle];
        [self.titleDateFormatter setTimeStyle:NSDateFormatterNoStyle];
        self.selectedItemsName = @"photo";
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateAlbum:) name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(themeChanged:) name:@"backgroundThemeChanged" object:nil];
    }
    
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];

    self.collectionView.delegate = self;

    self.toolbar.collectionView = self.collectionView;

    self.layout = [[NSCollectionViewFlowLayout alloc] init];
    self.layout.sectionInset = NSEdgeInsetsMake(10, 10, 10, 10);
    self.layout.minimumInteritemSpacing = 0;
    self.layout.minimumLineSpacing = 0;
    self.collectionView.collectionViewLayout = self.layout;

    self.toolbar.collectionView = self.collectionView;

    self.view.wantsLayer = YES;
    [self setBGColor];

    [self setupToolbar];

    [self updateAlbum:nil];
}

-(void)willShowPIXView
{
    [super willShowPIXView];

    [self updateAlbum:nil];

    // this will allow droping files into the larger grid view
    [self.collectionView registerForDraggedTypes:@[NSURLPboardType]];
    
    [self updateToolbar];
}

#pragma mark - Background Colors

- (void)themeChanged:(NSNotification *)note {
    [self setBGColor];
    for (NSView *item in self.collectionView.subviews) {
        item.needsDisplay = YES;
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

    [super keyDown:event];
}

// send a size between 0 and 1 (will be transformed into appropriate sizes)
-(void)setThumbSize:(CGFloat)size
{
    // sizes mapped between 140 and 400
    float transformedSize = (float) rint(140 + (260 * size));
    self.layout.itemSize = NSMakeSize(transformedSize, transformedSize);
    for (NSCollectionViewItem *item in self.collectionView.visibleItems) {
        [item.view updateLayer];
    }
    
}

#pragma mark - Album
-(void)setAlbum:(id)album
{
    if (album != _album) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AlbumDidChangeNotification object:_album];
        
        _album = album;
        [[[PIXAppDelegate sharedAppDelegate] window] setTitle:[self.album title]];

        [self.collectionView deselectAll:nil];
        [self updateToolbar];
        [self updateAlbum:nil];

        [self.collectionView scrollPoint:NSZeroPoint];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAlbum:) name:AlbumDidChangeNotification object:_album];
        
        // start a date scan for this album
        //[[PIXFileParser sharedFileParser] dateScanAlbum:self.album];
        
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
    
    // if we've got more than one photo then display the whole date range
    if (self.album.photos.count > 1) {
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
        [self updateToolbar];
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

- (void)openItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.item;
    if (index >= 0 && index < self.album.sortedPhotos.count) {
        PIXPhoto *photo = self.album.sortedPhotos[index];
        [self openItem:photo];
    }
}

- (void)openItem:(PIXPhoto *)photo {
    PIXPageViewController *pageViewController = [[PIXPageViewController alloc] initWithNibName:nil bundle:nil];
    pageViewController.initialSelectedObject = photo;
    pageViewController.album = self.album;
    pageViewController.delegate = self;
    [self.navigationViewController pushViewController:pageViewController];
}

#pragma mark - PIXPageViewControllerDelegate

-(void)pagerDidMoveToPhotoWithPath:(NSString *)aPhotoPath atIndex:(NSUInteger)index;
{
    if (index < self.album.sortedPhotos.count) {
        PIXPhoto *photo = self.album.sortedPhotos[index];
        if ([photo.path isEqualToString:aPhotoPath]) {
            [self.collectionView deselectAll:nil];
            [self.collectionView selectItemsAtIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:index inSection:0]]
                                    scrollPosition:NSCollectionViewScrollPositionNearestVerticalEdge];
        }
    }
}

#pragma mark - NSCollectionViewDataSource Methods

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.album.sortedPhotos.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    PIXPhotoCollectionViewItem *item = [collectionView makeItemWithIdentifier:@"PIXPhotoCollectionViewItem" forIndexPath:indexPath];
    item.representedObject = self.album.sortedPhotos[indexPath.item];
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
        PIXPhoto *album = self.album.sortedPhotos[item.item];
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
    [self updateToolbar];
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
    if([NSEvent modifierFlags] & NSAlternateKeyMask)
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
    if([NSEvent modifierFlags] & NSAlternateKeyMask)
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
        if([NSEvent modifierFlags] & NSAlternateKeyMask)
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

- (void)updateToolbar {
    NSUInteger count = self.collectionView.selectionIndexPaths.count;
    if (count == 0) {
        [self.toolbar hideToolbar:YES];
    } else {
        [self.toolbar showToolbar:YES];
    }
    [self.toolbar setTitle:[NSString localizedStringWithFormat:NSLocalizedString(@"%lu photo(s) selected", @"Number of selected photos"), (unsigned long)count]];
}

- (void)setupToolbar {
    PIXCustomButton * deleteButton = [[PIXCustomButton alloc] initWithFrame:CGRectMake(0, 0, 80, 25)];
    [deleteButton setTitle:@"Delete"];
    [deleteButton setTarget:self];
    [deleteButton setAction:@selector(deleteItems:)];
    
    PIXCustomButton * shareButton = [[PIXCustomButton alloc] initWithFrame:CGRectMake(0, 0, 80, 25)];
    
    //[shareButton setImage:[NSImage imageNamed:NSImageNameShareTemplate]];
    //[shareButton setImagePosition:NSImageLeft];
    
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

@end