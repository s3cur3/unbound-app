//
//  PIXCollectionViewController.m
//  UnboundApp
//
//  Created by Ditriol Wei on 29/7/16.
//  Copyright © 2016 Pixite Apps LLC. All rights reserved.
//

#import "PIXCollectionViewController.h"

#import "PIXAppDelegate.h"
#import "PIXDefines.h"
#import "PIXMiniExifViewController.h"
#import "PIXFileManager.h"
#import "PIXFileParser.h"
#import "PIXPhoto.h"
#import "PIXAlbum.h"
#import <Quartz/Quartz.h>

static NSString *kContentTitleKey, *kContentImageKey;

@interface PIXCollectionViewController () <NSMenuDelegate>

@property (strong) IBOutlet NSLayoutConstraint *toolbarPosition;
@property BOOL toolbarIsShowing;

@end

@implementation PIXCollectionViewController

+ (void)initialize
{
    kContentTitleKey = @"title";
    kContentImageKey = @"thumbnailImage";
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if( self != nil )
    {
        self.items = [NSMutableArray array];
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
    /*
    [self.gridView setHeaderSpace:35];
    [self.gridView setItemSize:CGSizeMake(200, 200)];
    [self.gridView setAllowsMultipleSelection:YES];
    */
    
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

-(void)willShowPIXView
{
    [super willShowPIXView];
    
    [self.gridViewTitle setHidden:NO];
    
    
    // make sure the toolbar is on the top
    [self.toolbar.layer setZPosition:1000];
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
    
    [_gridView  setBackgroundColor:color];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Show/Hide Toolbar
- (void)showToolbar:(BOOL)animated
{
    if(!self.toolbarIsShowing)
    {
        
        CGPoint origin = self.scrollView.bounds.origin;
        origin.y += 35;
        
        
        //NSClipView *clipView = (NSClipView *)[self.gridView superview];
        
        
        [NSAnimationContext beginGrouping];
        [self.toolbarPosition.animator setConstant:0];
        //[[clipView animator] setBoundsOrigin:origin];
        [NSAnimationContext endGrouping];
        
        self.toolbarIsShowing = YES;
    }
    
}

- (void)hideToolbar:(BOOL)animated
{
    if(self.toolbarIsShowing)
    {
        [self.toolbarPosition.animator setConstant:-self.toolbar.frame.size.height];
        //[self.view updateConstraintsForSubtreeIfNeeded];
        self.toolbarIsShowing = NO;
    }
}

- (void)updateToolbar
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
        
        double delayInSeconds = 0.25;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self showToolbar:YES];
        });
        
    }
    
    else
    {
        double delayInSeconds = 0.25;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self hideToolbar:YES];
        });
        
    }
}

#pragma mark - Menu
- (NSMenu *)menuForObject:(id)object
{
    NSMenu*  menu = nil;
    
    menu = [[NSMenu alloc] initWithTitle:@"menu"];
    [menu setAutoenablesItems:NO];
    
    
    // only show the mini exif view on photos
    if([object isKindOfClass:[PIXPhoto class]])
    {
        NSMenuItem * miniExifDisplay = [[NSMenuItem alloc] init];
        
        self.miniExifViewController.photo = object;
        
        miniExifDisplay.view = self.miniExifViewController.view;
        
        [miniExifDisplay.view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        
        [menu addItem:miniExifDisplay];
    }
    
    // Get Info
    //TODO: pop up message if multiple items selected for these actions
    [menu addItemWithTitle:[NSString stringWithFormat:@"Get Info"] action:
     @selector(getInfo:) keyEquivalent:@""];
    
    // Show in Finder
    [menu addItemWithTitle:[NSString stringWithFormat:@"Show in Finder"] action:
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
        [openWithMenuItem setTitle:@"Open with"];
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

- (BOOL)verifyActionForItemsWithTitle:(NSString *)aTitle message:(NSString *)warningMessage
{
    if (NSRunAlertPanel(aTitle, warningMessage, @"OK", @"Cancel", nil) == NSAlertDefaultReturn) {
        return YES;
    } else {
        return NO;
    }
}

- (void)getInfo:(id)sender;
{
    NSUInteger fileCount = self.selectedItems.count;
    if (fileCount>6) {
        NSString *msg = [NSString stringWithFormat:@"Are you sure you want to open multiple Info windows for the %ld selected %@s?", fileCount, self.selectedItemsName];
        NSString *aTitle = [NSString stringWithFormat:@"Get Info for %ld %@s", fileCount, [self.selectedItemsName capitalizedString]];
        if (![self verifyActionForItemsWithTitle:aTitle message:msg]) {
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

- (void)revealInFinder:(id)inSender
{
    id incomingItem = [inSender representedObject];
    //Do a check for albums as they can open many finder windows (photos are usually in the same directory)
    if ([incomingItem isKindOfClass:[PIXAlbum class]])
    {
        NSUInteger fileCount = self.selectedItems.count;
        if (fileCount>6) {
            NSString *msg = [NSString stringWithFormat:@"Are you sure you want to open multiple finder windows for the %ld selected albums?", fileCount];
            NSString *aTitle = [NSString stringWithFormat:@"Show %ld Albums", fileCount];
            if (![self verifyActionForItemsWithTitle:aTitle message:msg]) {
                return;
            }
        }
    }
    
    NSSet *aSet = [self.selectedItems copy];
    [aSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        NSString* path = [obj path];
        NSString* folder = [path stringByDeletingLastPathComponent];
        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:folder];
        
    }];
}

- (IBAction)openInApp:(id)sender
{
    id representedObj = [sender representedObject];
    NSUInteger fileCount = self.selectedItems.count;
    if (fileCount>9 &&
        ([representedObj isKindOfClass:[PIXPhoto class]])) {
        NSString *msg = [NSString stringWithFormat:@"Are you sure you want to open %ld selected photos?", fileCount];
        NSString *aTitle = [NSString stringWithFormat:@"Open %ld Photos", fileCount];
        if (![self verifyActionForItemsWithTitle:aTitle message:msg]) {
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

- (IBAction)chooseFolderButtonPressed:(id)sender
{
    [[PIXFileParser sharedFileParser] userChooseFolderDialog];
}

- (IBAction)importPhotosButtonPressed:(id)sender
{
    [[PIXFileManager sharedInstance] importPhotosToAlbum:nil allowDirectories:YES];
}

#pragma mark - Item Selection
- (NSMutableSet *)selectedItems
{
    if(_selectedItems != nil) return _selectedItems;
    
    _selectedItems = [NSMutableSet new];
    
    return _selectedItems;
}

- (IBAction)selectAll:(id)sender
{
    self.selectedItems = [NSMutableSet setWithArray:self.items];
    
    //[self.gridView reloadSelection];
    [self updateToolbar];
}

- (IBAction)selectNone:(id)sender
{
    [self.selectedItems removeAllObjects];
    //[self.gridView reloadSelection];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateToolbar];
    });
}

- (IBAction)toggleSelection:(id)sender
{
    NSMutableSet * mutableItems = [NSMutableSet setWithArray:self.items];
    
    // now remove items from the list that are already selected
    [mutableItems minusSet:self.selectedItems];
    
    self.selectedItems = mutableItems;
    
    //[self.gridView reloadSelection];
    [self updateToolbar];
}

- (IBAction)deleteItems:(id )inSender
{
    // if we have nothing to delete then do nothing
    if([self.selectedItems count] == 0) return;
    
    [[PIXFileManager sharedInstance] deleteItemsWorkflow:self.selectedItems];
    
}

- (void)reselectItems:(NSArray *)itemsToReselect
{
    [self.selectedItems removeAllObjects];
    
    for(NSObject * item in itemsToReselect)
    {
        if([self.items containsObject:item])
        {
            [self.selectedItems addObject:item];
        }
    }
    
    [self updateToolbar];
    //[self.gridView reloadSelection];
    
    NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
    [undoManager registerUndoWithTarget:self selector:@selector(gridViewDidDeselectAllItems:) object:self.gridView];
    [undoManager setActionName:@"Deselect Items"];
    [undoManager setActionIsDiscardable:YES];
}

@end
