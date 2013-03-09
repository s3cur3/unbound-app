//
//  PIXGridViewController.m
//  UnboundApp
//
//  Created by Bob on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXGridViewController.h"
#import "PIXGridViewItem.h"
#import "CNGridViewItem.h"
#import "CNGridViewItemLayout.h"
#import "PIXAppDelegate.h"
#import "PIXAppDelegate+CoreDataUtils.h"
#import "PIXPhotoGridViewItem.h"
#import "PIXAlbumGridViewItem.h"

#import "PIXMiniExifViewController.h"

//#import "PIXAlbum.h"
#import "PIXThumbnailLoadingDelegate.h"
#import "PIXDefines.h"


#import "PIXNavigationController.h"
#import "PIXSplitViewController.h"

#import "PIXPhoto.h"
#import "PIXAlbum.h"

#import "PIXFileManager.h"


#import <Quartz/Quartz.h>

static NSString *kContentTitleKey, *kContentImageKey;

@interface PIXGridViewController () <NSMenuDelegate>
{
    BOOL startedObserving;
}
@property (strong) CNGridViewItemLayout *defaultLayout;
@property (strong) CNGridViewItemLayout *hoverLayout;
@property (strong) CNGridViewItemLayout *selectionLayout;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarPosition;

@end

@implementation PIXGridViewController

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
        _defaultLayout = [CNGridViewItemLayout defaultLayout];
        _hoverLayout = [CNGridViewItemLayout defaultLayout];
        _selectionLayout = [CNGridViewItemLayout defaultLayout];
        
        [self.gridView setAllowsMultipleSelection:YES];
                
        [self.view setWantsLayer:YES];
    }
    
    return self;
}

-(void)awakeFromNib
{
    [self.gridView setHeaderSpace:35];
    [self.gridView setItemSize:CGSizeMake(200, 200)];
    [self.gridView setAllowsMultipleSelection:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultThemeChanged:)
                                                 name:@"backgroundThemeChanged"
                                               object:nil];
    [self setBGColor];
    
    
    // make the toolbar animate a little faster than default
    CABasicAnimation * toolBarAnim = [CABasicAnimation animation];
    toolBarAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    toolBarAnim.duration = 0.1;
    self.toolbarPosition.animations = [NSDictionary dictionaryWithObject:toolBarAnim forKey:@"constant"];
    
    // make the toolbar animate a little faster than default
    CABasicAnimation * scrollAnim = [CABasicAnimation animation];
    scrollAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    scrollAnim.duration = 0.1;
    self.gridView.superview.animations = [NSDictionary dictionaryWithObject:scrollAnim forKey:@"bounds"];
    
    [self updateToolbar];
    
    
}

-(void)showToolbar:(BOOL)animated
{

    CGPoint origin = self.scrollView.bounds.origin;
    origin.y += 35;

    
    //NSClipView *clipView = (NSClipView *)[self.gridView superview];
    
    
    [NSAnimationContext beginGrouping];
    [self.toolbarPosition.animator setConstant:0];
    //[[clipView animator] setBoundsOrigin:origin];
    [NSAnimationContext endGrouping];
    
}

-(void)hideToolbar:(BOOL)animated
{
    [self.toolbarPosition.animator setConstant:-self.toolbar.frame.size.height];
    //[self.view updateConstraintsForSubtreeIfNeeded];
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

-(void)refreshNotification:(NSNotification *)note
{
    [self.gridView reloadData];
}

-(NSMutableArray *)fetchItems
{
    //NSAssert(NO,@"PXIGridViewController's fetchItems should be implemented in subclass.");
    return nil;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)reloadItems:(NSNotification *)note
{
    [self.items removeAllObjects];
    NSArray *itemsArray = [self fetchItems];
    [self.items addObjectsFromArray:itemsArray];
    [self.gridView reloadData];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Context Menu Support

-(BOOL)verifyActionFoItemsWithMessage:(NSString *)warningMessage
{
    if (NSRunCriticalAlertPanel(@"Alert", warningMessage, @"OK", @"Cancel", nil) == NSAlertDefaultReturn) {
        return YES;
    } else {
        return NO;
    }
}

//TODO: Only for use with photos right now, fix to handle albums
- (IBAction) deleteItems:(id )inSender
{
    
    NSMutableArray *itemsToDelete = [[self.selectedItems allObjects] mutableCopy];
    NSSet *selectedSet = self.selectedItems;
    if (self.selectedItems.count != selectedSet.count)
    {
        DLog(@"selectedItems contains duplicates : %@", self.selectedItems);
        itemsToDelete = [[selectedSet allObjects] mutableCopy];
    }
    
    NSString * deleteString = @"Delete";
    
    NSManagedObject *object = [itemsToDelete lastObject];
    NSString *objectType = @"Item";
    if([object isKindOfClass:[PIXPhoto class]])
    {
        objectType = PHOTO;
    } else if([object isKindOfClass:[PIXAlbum class]]) {
        objectType = ALBUM;
    }
    if([self.selectedItems count] > 1)
    {
        deleteString = [NSString stringWithFormat:@"%ld %@s", [self.selectedItems count], objectType];
    } else {
        deleteString = objectType;
    }
    
    NSString *warningMessage = [NSString stringWithFormat:@"%@ will be deleted immediately.\nAre you sure you want to continue?", deleteString];
    if (NSRunCriticalAlertPanel(warningMessage, @"You cannot undo this action.", @"Delete", @"Cancel", nil) == NSAlertDefaultReturn) {
        
        if ([[itemsToDelete lastObject] class] == [PIXAlbum class]) {
            [[PIXFileManager sharedInstance] recycleAlbums:itemsToDelete];
        } else {
            [[PIXFileManager sharedInstance] recyclePhotos:itemsToDelete];
        }
        
    } else {
        // User clicked cancel, they do not want to delete the files
    }
    
}

- (IBAction) openInApp:(id)sender
{
    if (self.selectedItems.count>1) {
        NSString *msg = @"Are you sure you want to open all of the selected files?";
        if (![self verifyActionFoItemsWithMessage:msg]) {
            return;
        }
    }
    NSArray *itemsToOpen = [self.selectedItems allObjects];
    NSManagedObject *mObj = [itemsToOpen lastObject];
    //if ([mObj.entity.name isEqualToString:kPhotoEntityName]) {
    if ([mObj.entity.name isEqualToString:kAlbumEntityName]) {
        NSString *defaultAppPath = [[PIXFileManager sharedInstance] defaultAppPathForOpeningFileWithPath:[(PIXPhoto *)mObj path]];
        if ([[defaultAppPath lastPathComponent] isEqualToString:@"Preview.app"]) {
            
//            NSArray *photoPaths = [itemsToOpen valueForKey:@"path"];
//            NSMutableArray *photoURLs = [NSMutableArray arrayWithCapacity:photoPaths.count];
//            for (NSString *aPath in photoPaths)
//            {
//                NSURL *aURL = [NSURL fileURLWithPath:aPath isDirectory:NO];
//                [photoURLs addObject:aURL];
//            }
//            if (![[NSWorkspace sharedWorkspace] openURLs:photoURLs withAppBundleIdentifier:@"com.apple.Preview" options:NSWorkspaceLaunchAllowingClassicStartup additionalEventParamDescriptor:nil launchIdentifiers:NULL])
//            {
//                NSString *failureDescription = [NSString stringWithFormat:@"Failed to open selected photos in Preview."];
//                NSLog(@"%@", failureDescription);
//                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//                [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
//                NSError *error = [NSError errorWithDomain:@"com.pixite.unbound" code:042 userInfo:dict];
//                
//                [[NSApplication sharedApplication] presentError:error];
//            }
            
            //NSString* albumPath = [[(PIXPhoto *)mObj path] stringByDeletingLastPathComponent];
            NSString* albumPath = [(PIXAlbum *)mObj path];
            [[PIXFileManager sharedInstance] openFileWithPath:albumPath withApplication:defaultAppPath];
            return;
        }
    }
    for (id obj in itemsToOpen) {
        
        NSString* path = [obj path];
        [[NSWorkspace sharedWorkspace] openFile:path];
        
    }
}

- (IBAction) revealInFinder:(id)inSender
{
    NSSet *aSet = [self.selectedItems copy];
    [aSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        NSString* path = [obj path];
        NSString* folder = [path stringByDeletingLastPathComponent];
        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:folder];
        
    }];
}

-(IBAction)getInfo:(id)sender;
{
    if (self.selectedItems.count>1) {
        NSString *msg = @"Are you sure you want to open an info window for each of the selected files?";
        if (![self verifyActionFoItemsWithMessage:msg]) {
            return;
        }
    }
    NSSet *aSet = [self.selectedItems copy];
    [aSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {

        NSPasteboard *pboard = [NSPasteboard pasteboardWithUniqueName];
        [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [pboard setString:[obj path]  forType:NSStringPboardType];
        NSPerformService(@"Finder/Show Info", pboard);

    }];
    
}

-(NSMenu *)menuForObject:(id)object
{
    NSMenu*  menu = nil;
    
    menu = [[NSMenu alloc] initWithTitle:@"menu"];
    [menu setAutoenablesItems:NO];
    
    
    // only show the mini exif view on photos
    if([object isKindOfClass:[PIXPhoto class]])
    {   
        NSMenuItem * miniExifDisplay = [[NSMenuItem alloc] init];
        
        PIXMiniExifViewController * exifVC = [[PIXMiniExifViewController alloc] initWithNibName:@"PIXMiniExifViewController" bundle:nil];
        
        exifVC.photo = object;
        
        miniExifDisplay.view = exifVC.view;
        
        [miniExifDisplay.view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        
        [menu addItem:miniExifDisplay];
    }
    
    // Get Info
    //TODO: pop up message if multiple items selected for these actions
    [menu addItemWithTitle:[NSString stringWithFormat:@"Get Info"] action:
     @selector(getInfo:) keyEquivalent:@""];
    
    // Show in Finder
    [menu addItemWithTitle:[NSString stringWithFormat:@"Show In Finder"] action:
     @selector(revealInFinder:) keyEquivalent:@""];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    // only show open with options on Photo objects
    if([object isKindOfClass:[PIXPhoto class]])
    {
        
        
        // Open with Defualt
        NSString *defaultAppName = [[PIXFileManager sharedInstance] defaultAppNameForOpeningFileWithPath:[object path]];
        if (defaultAppName!=nil && ([defaultAppName isEqualToString:@"Finder"]==NO)) {
            [menu addItemWithTitle:[NSString stringWithFormat:@"Open with %@", defaultAppName] action:
             @selector(openInApp:) keyEquivalent:@""];
        }
        
        // Open with Others
        NSArray *filePaths = [[self.selectedItems allObjects] valueForKey:@"path"];
        NSMenu *openWithMenu = [[PIXFileManager sharedInstance] openWithMenuItemForFiles:filePaths];
        NSMenuItem *openWithMenuItem = [[NSMenuItem alloc] init];
        [openWithMenuItem setTitle:@"Open With"];
        [openWithMenuItem setSubmenu:openWithMenu];
        [menu addItem:openWithMenuItem];
        
        [menu addItem:[NSMenuItem separatorItem]];
    }
    
    // Selection Options
    [menu addItemWithTitle:[NSString stringWithFormat:@"Select All"] action:
     @selector(selectAll:) keyEquivalent:@""];
    [menu addItemWithTitle:[NSString stringWithFormat:@"Select None"] action:
     @selector(selectNone:) keyEquivalent:@""];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSString * deleteString = @"Delete";
    
    if([object isKindOfClass:[PIXPhoto class]])
    {
        if([self.selectedItems count] > 1)
        {
            deleteString = [NSString stringWithFormat:@"Delete %ld Photos", [self.selectedItems count]];
        }
        
        else
        {
            deleteString = @"Delete Photo";
        }
    }
    
    else if([object isKindOfClass:[PIXAlbum class]])
    {
        if([self.selectedItems count] > 1)
        {
            deleteString = [NSString stringWithFormat:@"Delete %ld Albums", [self.selectedItems count]];
        }
        
        else
        {
            deleteString = @"Delete Album";
        }
    }
    
    

    [menu addItemWithTitle:deleteString action:@selector(deleteItems:) keyEquivalent:@""];
    
    for (NSMenuItem * anItem in [menu itemArray])
    {
        [anItem setRepresentedObject:object];
        [anItem setTarget:self];
    }
    
    menu.delegate = self;
    
    
    //NSMenu *openWithMenu = [[PIXFileManager sharedInstance] openWithMenuItemForFile:[object path]];
    
    return menu;
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
        item = [[CNGridViewItem alloc] initWithLayout:self.defaultLayout reuseIdentifier:reuseIdentifier];
    }
    item.hoverLayout = self.hoverLayout;
    item.selectionLayout = self.selectionLayout;
    
    //    NSDictionary *contentDict = [self.items objectAtIndex:index];
    //    item.itemTitle = [NSString stringWithFormat:@"Item: %lu", index];
    //    item.itemImage = [contentDict objectForKey:kContentImageKey];
    
//    id itemObject = [self.items objectAtIndex:index];
    return item;
}

/*-(void)showPhotosForAlbum:(id)anAlbum
{
    PIXSplitViewController *aSplitViewController  = [[PIXSplitViewController alloc] initWithNibName:@"PIXSplitViewController" bundle:nil];
    aSplitViewController.selectedAlbum = anAlbum;
    [aSplitViewController.view setFrame:self.view.bounds];
    [self.navigationViewController pushViewController:aSplitViewController];
}*/


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSNotifications

- (void)detectedNotification:(NSNotification *)notif
{
    //CNLog(@"notification: %@", notif);
}


-(NSMutableSet *)selectedItems
{
    if(_selectedItems != nil) return _selectedItems;
    
    _selectedItems = [NSMutableSet new];
    
    return _selectedItems;
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNGridView Delegate Selection Methods


- (void)gridView:(CNGridView *)gridView didSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [self.selectedItems addObject:[self.items objectAtIndex:index]];
    [self updateToolbar];
}

- (void)gridView:(CNGridView *)gridView didShiftSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    
    if([self.selectedItems count] == 0)
    {
        [self.selectedItems addObject:[self.items objectAtIndex:index]];
    }
    
    else
    {
        // loop through the current selection and find the index that's closest the the newly clicked index
        NSUInteger startIndex = NSNotFound;
        NSUInteger distance = NSUIntegerMax;
        
        for(PIXAlbum * aSelectedAlbum in self.selectedItems)
        {
            NSUInteger thisIndex = [self.items indexOfObject:aSelectedAlbum];
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
            [self.selectedItems addObject:[self.items objectAtIndex:i]];
        }
    }
    
    [self.gridView reloadSelection];
    [self updateToolbar];
}

- (void)gridView:(CNGridView *)gridView didDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [self.selectedItems removeObject:[self.items objectAtIndex:index]];
    [self updateToolbar];
}

- (void)gridViewDidDeselectAllItems:(CNGridView *)gridView
{
    [self.selectedItems removeAllObjects];
    [self updateToolbar];
}


-(IBAction)selectAll:(id)sender
{
    self.selectedItems = [NSMutableSet setWithArray:self.items];
    
    [self.gridView reloadSelection];
    [self updateToolbar];
}

-(IBAction)selectNone:(id)sender
{
    [self.selectedItems removeAllObjects];
    [self.gridView reloadSelection];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateToolbar];
    });
    
}

-(void)toggleSelection:(id)sender
{
    NSMutableSet * mutableItems = [NSMutableSet setWithArray:self.items];
    
    // now remove items from the list that are already selected
    [mutableItems minusSet:self.selectedItems];
    
    self.selectedItems = mutableItems;
    
    [self.gridView reloadSelection];
    [self updateToolbar];
}


-(void)updateToolbar
{
    if([self.selectedItems count] > 0)
    {
        if([self.selectedItems count] > 1)
        {
            [self.toolbarTitle setStringValue:[NSString stringWithFormat:@"%ld %@s selected", (unsigned long)[self.selectedItems count], self.selectedItemsName]];
        }
        
        else
        {
            [self.toolbarTitle setStringValue:[NSString stringWithFormat:@"1 %@ selected", self.selectedItemsName]];
        }
        
        [self showToolbar:YES];
    }
    
    else
    {
        [self hideToolbar:YES];
    }
}

#pragma mark - Leap Methods
- (void)gridView:(CNGridView *)gridView didPointItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [self.selectedItems removeAllObjects];
    [self.selectedItems addObject:[self.items objectAtIndex:index]];
    [self updateToolbar];
    [self.gridView reloadSelection];
}

@end
