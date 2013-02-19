//
//  PIXPhotoGridViewController.m
//  UnboundApp
//
//  Created by Bob on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXPhotoGridViewController.h"
#import "PIXAppDelegate.h"
#import "PIXAppDelegate+CoreDataUtils.h"
#import "PIXAlbum.h"
#import "PIXPageViewController.h"
#import "PIXNavigationController.h"
#import "PIXDefines.h"
#import "PIXPhotoGridViewItem.h"
#import "PIXPhoto.h"
#import "PIXGradientBarView.h"
#import "PIXCustomButton.h"
#import "PIXCustomShareSheetViewController.h"

@interface PIXPhotoGridViewController ()

@property(nonatomic,strong) NSDateFormatter * titleDateFormatter;

@end

@implementation PIXPhotoGridViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        
        
        self.titleDateFormatter = [[NSDateFormatter alloc] init];
        [self.titleDateFormatter setDateStyle:NSDateFormatterLongStyle];
        [self.titleDateFormatter setTimeStyle:NSDateFormatterNoStyle];
        self.selectedItemsName = @"photo";
        
    }
    
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self performSelector:@selector(updateAlbum) withObject:nil afterDelay:0.1];

//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadItems:) name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
    
    //
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(albumsChanged:)
//                                                 name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM
//                                               object:nil];
    
}

-(void)willShowPIXView
{
    [super willShowPIXView];
    
    [self.gridView reloadSelection];
    
}


-(void)setAlbum:(id)album
{
  
    
    if (album != _album)
    {
        _album = album;
        [[[PIXAppDelegate sharedAppDelegate] window] setTitle:[self.album title]];
        
        [self.selectedItems removeAllObjects];
        [self updateToolbar];
        [self updateAlbum];
        
        [self.gridView scrollPoint:NSZeroPoint];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAlbum) name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
        
    }
}

-(void)updateAlbum
{
    self.items = [self fetchItems];
    
    // remove any items that are no lon
    [self.selectedItems intersectSet:[NSSet setWithArray:self.items]];
    
    
    [self.gridView reloadData];
    
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    NSString *photosCount = [numberFormatter stringFromNumber:[NSNumber numberWithLong:[self.items count]]];
    
    
    NSString * gridTitle = nil;
    
    // if we've got more than one photo then display the whole date range
    if([self.items count] > 2)
    {
        NSDate * startDate = [[self.items objectAtIndex:0] dateTaken];
        NSDate * endDate = [[self.items lastObject] dateTaken];
        
        
        NSCalendar* calendar = [NSCalendar currentCalendar];
        
        unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
        NSDateComponents* startComponents = [calendar components:unitFlags fromDate:startDate];
        NSDateComponents* endComponents = [calendar components:unitFlags fromDate:endDate];
        
        [self.titleDateFormatter setDateFormat:@"MMMM d, yyyy"];
        if([startComponents year] == [endComponents year])
        {
            // don't show the year on the first date if they're the same
            [self.titleDateFormatter setDateFormat:@"MMMM d"];
        }
        
        NSString * startDateString = [self.titleDateFormatter stringFromDate:startDate];
        
        [self.titleDateFormatter setDateFormat:@"MMMM d, yyyy"];
        
        
        
        // if the date goes multiple days print the span
        if([startComponents day] != [endComponents day])
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
    
    else
    {
        [self.titleDateFormatter setDateStyle:NSDateFormatterLongStyle];
        
        gridTitle = [NSString stringWithFormat:@"%@ photo from %@", photosCount, [self.titleDateFormatter stringFromDate:self.album.albumDate]];
    }
    
    [self.gridViewTitle setStringValue:gridTitle];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateToolbar];
    });
    
    
}

-(NSMutableArray *)fetchItems
{
    //return [[[PIXAppDelegate sharedAppDelegate] fetchAllPhotos] mutableCopy];
    return [NSMutableArray arrayWithArray:[self.album.photos array]];
}

- (CNGridViewItem *)gridView:(CNGridView *)gridView itemAtIndex:(NSInteger)index inSection:(NSInteger)section
{
    static NSString *reuseIdentifier = @"CNGridViewItem";
    
    PIXPhotoGridViewItem *item = [gridView dequeueReusableItemWithIdentifier:reuseIdentifier];
    if (item == nil) {
        item = [[PIXPhotoGridViewItem alloc] initWithLayout:nil reuseIdentifier:reuseIdentifier];
    }
    
    //    NSDictionary *contentDict = [self.items objectAtIndex:index];
    //    item.itemTitle = [NSString stringWithFormat:@"Item: %lu", index];
    //    item.itemImage = [contentDict objectForKey:kContentImageKey];
    
    PIXPhoto * photo = [self.items objectAtIndex:index];
    [item setPhoto:photo];
    return item;
}

- (BOOL)gridView:(CNGridView *)gridView itemIsSelectedAtIndex:(NSInteger)index inSection:(NSInteger)section
{
    PIXPhoto * photo = nil;
    
    if(index < [self.items count])
    {
        photo = [self.items objectAtIndex:index];
        return [self.selectedItems containsObject:photo];
    }
    
    return NO;
    
}



-(void)showPageControllerForIndex:(NSUInteger)index
{
    PIXPageViewController *pageViewController = [[PIXPageViewController alloc] initWithNibName:@"PIXPageViewController" bundle:nil];
    pageViewController.album = self.album;
    pageViewController.initialSelectedObject = [self.album.photos objectAtIndex:index];
    [self.navigationViewController pushViewController:pageViewController];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNGridView Delegate

//- (void)gridView:(CNGridView *)gridView didClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
//{
//    CNLog(@"didClickItemAtIndex: %li", index);
//}

- (void)gridView:(CNGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    CNLog(@"didDoubleClickItemAtIndex: %li", index);
    [self showPageControllerForIndex:index];
}

- (void)gridView:(CNGridView *)gridView rightMouseButtonClickedOnItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event
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

#pragma mark - Drag Operations

- (void)gridView:(CNGridView *)gridView dragDidBeginAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event
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
    
    
    
    NSImage * dragImage = [PIXPhotoGridViewItem dragImageForPhotos:selectedArray size:NSMakeSize(180, 180)];
    [self.gridView dragImage:dragImage at:location offset:NSZeroSize event:event pasteboard:dragPBoard source:self slideBack:YES];
    
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
    
    [self.toolbar setButtons:@[deleteButton, shareButton]];
    
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







@end
