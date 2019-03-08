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
#import "PIXCollectionToolbar.h"
#import "PIXCollectionView.h"
#import <Quartz/Quartz.h>

static NSString *kContentTitleKey, *kContentImageKey;

@interface PIXCollectionViewController () <NSMenuDelegate, NSCollectionViewDelegate>

@property (strong) IBOutlet NSLayoutConstraint *toolbarPosition;
@property BOOL toolbarIsShowing;

@property NSSet *selectedItems;

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

    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.wantsLayer = true;
    self.collectionView.wantsLayer = true;

//    if (@available(macOS 10.14, *)) {
//        // The collection view actually seems to take it's color from the primary color defined in the
//        // XIB, but I'm leaving this here for funzies.
//        self.collectionView.layer.backgroundColor = NSColor.windowBackgroundColor.CGColor;
//        self.view.layer.backgroundColor = NSColor.windowBackgroundColor.CGColor;
//        self.gridViewTitle.textColor = NSColor.textColor;
//    } else {
//        [self setBGColor];
//    }
}

- (void)awakeFromNib
{
    /*
    [self.collectionView setHeaderSpace:35];
    [self.collectionView setItemSize:CGSizeMake(200, 200)];
    [self.collectionView setAllowsMultipleSelection:YES];
    */

    self.collectionView.allowsEmptySelection = YES;
    self.collectionView.allowsMultipleSelection = YES;

    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_13) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(defaultThemeChanged:)
                                                     name:@"backgroundThemeChanged"
                                                   object:nil];
    }
    
    // make the toolbar animate a little faster than default
    CABasicAnimation * toolBarAnim = [CABasicAnimation animation];
    toolBarAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    toolBarAnim.duration = 0.1;
    self.toolbarPosition.animations = @{@"constant": toolBarAnim};
    
    // make the toolbar animate a little faster than default
    CABasicAnimation * scrollAnim = [CABasicAnimation animation];
    scrollAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    scrollAnim.duration = 0.1;
    self.collectionView.superview.animations = @{@"bounds": scrollAnim};
}

- (void)viewWillLayout
{
    if (@available(macOS 10.14, *)) {
        self.view.layer.backgroundColor = NSColor.windowBackgroundColor.CGColor;
        self.collectionView.layer.backgroundColor = NSColor.windowBackgroundColor.CGColor;
        self.gridViewTitle.textColor = NSColor.textColor;
    } else {
        [self setBGColor];
    }
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
    [self.collectionView setNeedsDisplay:YES];
    
    for(NSView * item in self.collectionView.subviews)
    {
        [item setNeedsDisplay:YES];
    }
}

- (void)setBGColor
{
    if (@available(macOS 10.14, *)) {
        return;
    }
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

    self.collectionView.layer.backgroundColor = color.CGColor;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
        if (defaultAppName!=nil && ![defaultAppName isEqualToString:@"Finder"]) {
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

- (void)reselectItems:(NSArray *)itemsToReselect
{
    // Subclasses should implement this
    
    NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
    [undoManager registerUndoWithTarget:self selector:@selector(gridViewDidDeselectAllItems:) object:self.collectionView];
    [undoManager setActionName:@"Deselect Items"];
    [undoManager setActionIsDiscardable:YES];
}

@end
