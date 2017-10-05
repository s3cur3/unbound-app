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

@interface PIXPhotoCollectionViewController () <PIXGridViewDelegate, NSCollectionViewDataSource>

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAlbum:) name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
        
    }
    
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self performSelector:@selector(updateAlbum:) withObject:nil afterDelay:0.1];

    self.layout = [[NSCollectionViewFlowLayout alloc] init];
    self.layout.sectionInset = NSEdgeInsetsMake(10, 10, 10, 10);
    self.layout.minimumInteritemSpacing = 0;
    self.layout.minimumLineSpacing = 0;
    self.gridView.collectionViewLayout = self.layout;

    self.view.wantsLayer = YES;
}

-(void)willShowPIXView
{
    [super willShowPIXView];

    [self.gridView setGridViewDelegate:self];
    
    [self updateAlbum:nil];

    [self.gridView reloadSelection];
    
    // this will allow droping files into the larger grid view
    [self.gridView registerForDraggedTypes:[NSArray arrayWithObject: NSURLPboardType]];
    
    [self hideToolbar:NO];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateToolbar];
    });

}

// handle escape key here if needed
-(void)keyDown:(NSEvent *)event
{
    if ([event type] == NSKeyDown)
    {
        NSString* pressedChars = [event characters];
        if ([pressedChars length] == 1)
        {
            unichar pressedUnichar = [pressedChars characterAtIndex:0];
            
            if (pressedUnichar == 0x001B)  // escape key
            {
                [self.navigationViewController popViewController];
                return;
            }
            
            if(pressedUnichar == 'f') // f should togge fullscreen
            {
                [self.view.window toggleFullScreen:event];
                return;
            }
            
        }
    }
    
    
    [super keyDown:event];
    
}

// send a size between 0 and 1 (will be transformed into appropriate sizes)
-(void)setThumbSize:(CGFloat)size
{
    // sizes mapped between 140 and 400
    float transformedSize = rint(140 + (260 * size));
    self.layout.itemSize = NSMakeSize(transformedSize, transformedSize);
    for (NSCollectionViewItem *item in self.gridView.visibleItems) {
        [item.view updateLayer];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gridView setScrollElasticity:YES];
    });
    
}

#pragma mark -
#pragma mark Leap Thumb Size Adjustment

-(void)leapPanZoomStart
{
    if(![self.view.window isKeyWindow]) return;
    
    self.startPinchZoom = [[NSUserDefaults standardUserDefaults] floatForKey:@"photoThumbSize"];
    
}



-(void)leapPanZoomPosition:(NSPoint)position andScale:(CGFloat)scale
{
    if(![self.view.window isKeyWindow]) return;
    
    
    float magnification = self.startPinchZoom + (scale - 1.0);
    
    magnification = magnification * 0.5;
    
    if(magnification < 0.0) magnification = 0.0;
    if(magnification > 1.0) magnification = 1.0;
    
    // set the new default
    [[NSUserDefaults standardUserDefaults] setFloat:magnification forKey:@"photoThumbSize"];
    
    // set the actual maginification
    [self setThumbSize:magnification];
}


#pragma mark - Album
-(void)setAlbum:(id)album
{
    if (album != _album) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AlbumDidChangeNotification object:_album];
        
        _album = album;
        [[[PIXAppDelegate sharedAppDelegate] window] setTitle:[self.album title]];
        
        [self.selectedItems removeAllObjects];
        [self updateToolbar];
        [self updateAlbum:nil];

        [self.gridView resetSelection];
        [self.gridView scrollPoint:NSZeroPoint];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAlbum:) name:AlbumDidChangeNotification object:_album];
        
        // start a date scan for this album
        //[[PIXFileParser sharedFileParser] dateScanAlbum:self.album];
        
        [self.album checkDates];

        [self.gridView reloadData];
    }
}

-(void)updateAlbum:(NSNotification *)note
{
    //self.items = [self fetchItems];
    // remove any items that are no longer in the selection
    //[self.selectedItems intersectSet:[NSSet setWithArray:self.items]];
    //[self.gridView reloadData];

    NSMutableArray * newPhotos = [self fetchItems];

    [self.selectedItems intersectSet:[NSSet setWithArray:newPhotos]];
    
    // Remove Old Photos
    NSArray * oldPhotos = [self.arrayController arrangedObjects];
    [self.arrayController removeObjects:oldPhotos];
    
    if( [newPhotos count] > 0 )
    {
        // Add New Photos
        [self.arrayController addObjects:newPhotos];
    }
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    NSString *photosCount = [numberFormatter stringFromNumber:[NSNumber numberWithLong:[self.items count]]];
    
    
    NSString * gridTitle = nil;
    
    // if we've got more than one photo then display the whole date range
    if([self.items count] >= 2)
    {
        NSDate * startDate = [self.album startDate];
        NSDate * endDate = [self.album albumDate];
        
        
        NSCalendar* calendar = [NSCalendar currentCalendar];
        
        unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
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
            /*// This will remove the second month name if they are the same
             if([startComponents month] == [endComponents month])
             {
             [self.titleDateFormatter setDateFormat:@"d, YYYY"];
             }*/
            
            NSString * endDateString = [self.titleDateFormatter stringFromDate:endDate];
            gridTitle = [NSString stringWithFormat:@"%@ photos from %@ to %@", photosCount, startDateString, endDateString];
        }
        
        else
        {
            NSString * endDateString = [self.titleDateFormatter stringFromDate:endDate];
            gridTitle = [NSString stringWithFormat:@"%@ photos from %@", photosCount, endDateString];
        }
    }
    
    else if ([self.items count] == 1)
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

-(NSMutableArray *)fetchItems
{
    //return [[[PIXAppDelegate sharedAppDelegate] fetchAllPhotos] mutableCopy];
    return [NSMutableArray arrayWithArray:[self.album sortedPhotos]];
}

#pragma mark - Page View Controller
-(void)showPageControllerForIndex:(NSUInteger)index
{
    PIXPageViewController *pageViewController = [[PIXPageViewController alloc] initWithNibName:@"PIXPageViewController" bundle:nil];
    
    pageViewController.initialSelectedObject = [self.items objectAtIndex:index];
    
    pageViewController.album = self.album;
    
    pageViewController.delegate = self;
    
    [self.navigationViewController pushViewController:pageViewController];
}

//PIXPageViewControllerDelegate callback
-(void)pagerDidMoveToPhotoWithPath:(NSString *)aPhotoPath atIndex:(NSUInteger)index;
{
    if(index < [self.items count])
    {
        PIXPhoto * photo = nil;
        photo = [self.items objectAtIndex:index];
        if ([photo.path isEqualToString:aPhotoPath]) {
            [self.selectedItems removeAllObjects];
            [self.selectedItems addObject:photo];
            [self.gridView scrollToAndReturnItemAtIndex:index animated:YES];
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


#pragma mark - PIXGridViewDelegate
- (BOOL)gridView:(PIXGridView *)gridView itemIsSelectedAtIndex:(NSInteger)index inSection:(NSInteger)section
{
    PIXPhoto * photo = nil;
    
    if(index < [self.items count])
    {
        photo = [self.items objectAtIndex:index];
        return [self.selectedItems containsObject:photo];
    }
    
    return NO;
}

- (void)gridView:(PIXGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    if(index == NSNotFound) return;
    
    //CNLog(@"didDoubleClickItemAtIndex: %li", index);
    [self showPageControllerForIndex:index];
}

- (void)gridView:(PIXGridView *)gridView rightMouseButtonClickedOnItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event
{
    PIXPhoto * itemClicked = nil;
    
    if(index < [self.items count])
    {
        itemClicked = [self.items objectAtIndex:index];
    }
    
    // we don't handle clicks off of an album right now
    if(itemClicked == nil) return;
    
    // if this photo isn't in the selection than re-select only this
    if(itemClicked != nil && ![self.selectedItems containsObject:itemClicked])
    {
        [self.selectedItems removeAllObjects];
        [self.selectedItems addObject:itemClicked];
        [self.gridView reloadSelection];
        
        [self updateToolbar];
    }
    
    
    NSMenu *contextMenu = [self menuForObject:itemClicked];
    [NSMenu popUpContextMenu:contextMenu withEvent:event forView:self.view];
    
    // can use this and the self.selectedAlbum array to build a right click menu here
    
    DLog(@"rightMouseButtonClickedOnItemAtIndex: %li", index);
}

- (void)gridView:(PIXGridView *)gridView dragDidBeginAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event
{
    if(index == NSNotFound) return;
    
    // move the item we just selected to the front (so it will show up correctly in the drag image)
    PIXPhoto * topPhoto = [self.items objectAtIndex:index];
    
    NSMutableArray * selectedArray = [[self.selectedItems allObjects] mutableCopy];
    
    if(topPhoto)
    {
        [selectedArray removeObject:topPhoto];
        [selectedArray insertObject:topPhoto atIndex:0];
    }
    
    
    NSPasteboard *dragPBoard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [dragPBoard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:nil];
    
    NSMutableArray * filenames = [[NSMutableArray alloc] initWithCapacity:[self.selectedItems count]];
    
    for(PIXPhoto * aPhoto in selectedArray)
    {
        [filenames addObject:aPhoto.path];
        //[dragPBoard setString:anAlbum.path forType:NSFilenamesPboardType];
    }
    
    [dragPBoard setPropertyList:filenames
                        forType:NSFilenamesPboardType];
    NSPoint location = [self.gridView convertPoint:[event locationInWindow] fromView:nil];
    location.x -= 90;
    location.y += 90;
    
    
    
    NSImage * dragImage = [PIXPhotoCollectionViewItemView dragImageForPhotos:selectedArray size:NSMakeSize(180, 180)];
    [self.gridView dragImage:dragImage at:location offset:NSZeroSize event:event pasteboard:dragPBoard source:self slideBack:YES];
}

- (void)gridViewDidPressLeftArrowKeyAtFirstColumn:(PIXGridView *)gridView
{
    // make the album view the first responder if it's open
    if(![self.splitViewController.splitView isSubviewCollapsed:self.splitViewController.leftPane] &&
       [self.selectedItems count] == 1) // make sure only one item is selected
    {
        [self.view.window makeFirstResponder:self.splitViewController.sidebarViewController.outlineView];
        [self selectNone:nil];
    }
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

-(void)updateToolbar
{
    [super updateToolbar];
    
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
