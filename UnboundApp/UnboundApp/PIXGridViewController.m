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

- (IBAction) revealInFinder:(id)inSender
{
    id representedObject = [inSender representedObject];
//    id representedObject = nil;
//    if ([gridViewItem class] == [PIXAlbumGridViewItem class]) {
//        representedObject = [gridViewItem album];
//    } else if ([gridViewItem class] == [PIXPhotoGridViewItem class]) {
//        representedObject = [gridViewItem photo];
//    } else {
//        return;
//    }
    
	NSString* path = [representedObject path];
	NSString* folder = [path stringByDeletingLastPathComponent];
	[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:folder];
}

-(NSMenu *)menuForObject:(id)object
{
    NSMenu*  menu = nil;
    //TODO: see why isKindOfClass is returning NO
    //if ([[object class] isKindOfClass: [PIXGridViewItem class]])
    if ([object class] == [PIXAlbum class] ||
        [object class] == [PIXPhoto class])
    {
        
        menu = [[NSMenu alloc] initWithTitle:@"menu"];
        [menu setAutoenablesItems:NO];
        
        //    [menu addItemWithTitle:[NSString stringWithFormat:@"Open"] action:
        //     @selector(openInApp:) keyEquivalent:@""];
        //    [menu addItemWithTitle:[NSString stringWithFormat:@"Delete"] action:
        //     @selector(deleteItems:) keyEquivalent:@""];
        //    [menu addItemWithTitle:[NSString stringWithFormat:@"Get Info"] action:
        //     @selector(getInfo:) keyEquivalent:@""];
        [menu addItemWithTitle:[NSString stringWithFormat:@"Show In Finder"] action:
         @selector(revealInFinder:) keyEquivalent:@""];
        
        for (NSMenuItem * anItem in [menu itemArray])
        {
            [anItem setRepresentedObject:object];
            [anItem setTarget:self];
        }
        menu.delegate = self;
        
    }
    NSMenu *openWithMenu = [[PIXFileManager sharedInstance] openWithMenuItemForFile:[object path]];
    NSMenuItem *openWithMenuItem = [[NSMenuItem alloc] init];
    [openWithMenuItem setTitle:@"Open With"];
    [openWithMenuItem setSubmenu:openWithMenu];
    [menu addItem:openWithMenuItem];
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




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNGridView Delegate

- (void)gridView:(CNGridView *)gridView didClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    CNLog(@"didClickItemAtIndex: %li", index);
}

- (void)gridView:(CNGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    CNLog(@"didDoubleClickItemAtIndex: %li", index);
}

- (void)gridView:(CNGridView *)gridView rightMouseButtonClickedOnItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event
{
    CNLog(@"rightMouseButtonClickedOnItemAtIndex: %li", index);
}

- (void)gridView:(CNGridView *)gridView didSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    CNLog(@"didSelectItemAtIndex: %li", index);
}

- (void)gridView:(CNGridView *)gridView didDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    CNLog(@"didDeselectItemAtIndex: %li", index);
}

@end
