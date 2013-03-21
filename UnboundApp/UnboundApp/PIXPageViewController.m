//
//  PIXPageViewController.m
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//
#import <Quartz/Quartz.h>

#import "PIXPageViewController.h"
#import "PIXAppDelegate.h"
#import "Album.h"
#import "PIXAlbum.h"
#import "PIXPhoto.h"
#import "PIXImageViewController.h"
#import "PIXLeapInputManager.h"
#import "PIXNavigationController.h"

#import "PIXPageHUDWindow.h"

#import "PIXCustomShareSheetViewController.h"
#import "PIXShareManager.h"

#import "PIXInfoPanelViewController.h"

@interface PIXPageViewController () <leapResponder>

@property NSArray * viewControllers;

@property (assign) IBOutlet NSView * controlView;
@property (assign) IBOutlet PIXPageHUDWindow * controlWindow;
@property (assign) IBOutlet NSLayoutConstraint *infoPanelSpacer;

@property (assign) IBOutlet PIXInfoPanelViewController * infoPanelVC;

@property BOOL infoPanelShowing;

@property (nonatomic, strong) NSToolbarItem * shareItem;
@property (nonatomic, strong) NSToolbarItem * infoItem;
@property (nonatomic, strong) NSButton * infoButton;

@property (nonatomic, strong) PIXImageViewController * currentImageVC;

@property BOOL hasMouse;

@property (nonatomic, strong) NSMutableSet *preLoadPhotosSet;

@end

@implementation PIXPageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        
    }
    
    return self;
}

-(void)awakeFromNib
{
    if (self.album!=nil)
    {
        [self.pageController.view setWantsLayer:YES];
        self.pageController.transitionStyle = NSPageControllerTransitionStyleHorizontalStrip;
        
        [self.infoPanelSpacer setConstant:0.0];
        self.infoPanelShowing = NO;
        
        [self.view setNeedsUpdateConstraints:YES];
        
    }
    
    if (self.preLoadPhotosSet == nil) {
        self.preLoadPhotosSet = [[NSMutableSet alloc] initWithCapacity:4];
    }
}
/*
-(void)setupToolbar
{
//    [self.navigationViewController setNavBarHidden:YES];
 
 [NSAnimationContext beginGrouping];
 [self.toolbarPosition.animator setConstant:0];
 //[[clipView animator] setBoundsOrigin:origin];
 [NSAnimationContext endGrouping];
}
*/


-(IBAction)toggleInfoPanel:(id)sender;
{
    if(self.infoPanelShowing)
    {
        [NSAnimationContext beginGrouping];
        [self.infoPanelSpacer.animator setConstant:0];
        [NSAnimationContext endGrouping];
        
        [self.infoButton highlight:NO];
    }
    
    
    else
    {
        [NSAnimationContext beginGrouping];
        [self.infoPanelSpacer.animator setConstant:240];
        [NSAnimationContext endGrouping];
        
        [self.infoButton highlight:YES];
    }
    
    self.infoPanelShowing = !self.infoPanelShowing;
    
    
}

- (void)willShowPIXView
{
    [[PIXLeapInputManager sharedInstance] addResponder:self];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self updateData];
        
        [self.view.window makeFirstResponder:self];
        self.nextResponder = self.view;
        
        [self.view.window addChildWindow:self.controlWindow ordered:NSWindowAbove];        
        [self.controlWindow orderFront:self];
        
        [self.controlView setNeedsDisplay:YES];
        
        [self.controlWindow setParentView:self.pageController.view];
        
        
        [self.pageController.view layoutSubtreeIfNeeded];
        
        [self.infoPanelVC setPhoto:[self.pagerData objectAtIndex:self.pageController.selectedIndex]];
        

        
    });
}

-(void)setupToolbar
{
    NSArray * items = @[self.navigationViewController.backButton, self.navigationViewController.middleSpacer, self.shareItem, self.infoItem];
    
    [self.navigationViewController setNavBarHidden:NO];
    [self.navigationViewController setToolbarItems:items];
    
}

- (NSToolbarItem *)shareItem
{
    if(_shareItem != nil) return _shareItem;
    
    _shareItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"sharePhotoButton"];
    //_settingsButton.image = [NSImage imageNamed:NSImageNameSmartBadgeTemplate];
    
    NSButton * buttonView = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 60, 25)];
    
    [buttonView setImagePosition:NSNoImage];
    [buttonView setBordered:YES];
    [buttonView setBezelStyle:NSTexturedSquareBezelStyle];
    [buttonView setTitle:@"Share"];
    
    _shareItem.view = buttonView;
    
    [_shareItem setLabel:@"Share Photo"];
    [_shareItem setPaletteLabel:@"Share Photo"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_shareItem setToolTip:@"Share a Photo"];
    
    // Tell the item what message to send when it is clicked
    [buttonView setTarget:self];
    [buttonView setAction:@selector(shareButtonPressed:)];
    
    return _shareItem;
    
}

-(IBAction)shareButtonPressed:(id)sender
{
    PIXPhoto * currentPhoto = (PIXPhoto *)[self.pagerData objectAtIndex:self.pageController.selectedIndex];
    
    [[PIXShareManager defaultShareManager] showShareSheetForItems:@[currentPhoto]
                                                   relativeToRect:[sender bounds]
                                                           ofView:sender
                                                    preferredEdge:NSMaxXEdge];
    
    /*
    PIXCustomShareSheetViewController *controller = [[PIXCustomShareSheetViewController alloc] initWithNibName:@"PIXCustomShareSheetViewController"     bundle:nil];
    
    PIXPhoto * thisPhoto = [self.pagerData objectAtIndex:self.pageController.selectedIndex];
    
    [controller setPhotosToShare:@[thisPhoto]];
    
    NSPopover *popover = [[NSPopover alloc] init];
    [popover setContentViewController:controller];
    [popover setAnimates:YES];
    [popover setBehavior:NSPopoverBehaviorTransient];
    [popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
     */
}

- (NSToolbarItem *)infoItem
{
    if(_infoItem != nil) return _infoItem;
    
    _infoItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"infoButton"];
    //_settingsButton.image = [NSImage imageNamed:NSImageNameSmartBadgeTemplate];
    
    
    
    _infoItem.view = self.infoButton;
    
    [_infoItem setLabel:@"Photo Info"];
    [_infoItem setPaletteLabel:@"Photo Info"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_infoItem setToolTip:@"Photo Info"];

    
    return _infoItem;
    
}

-(NSButton *)infoButton
{
    if(_infoButton != nil) return _infoButton;
    
    _infoButton = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 60, 25)];
    
    [_infoButton setImagePosition:NSNoImage];
    [_infoButton setBordered:YES];
    [_infoButton setBezelStyle:NSTexturedSquareBezelStyle];
    [_infoButton setTitle:@"Info"];
    
    // Tell the item what message to send when it is clicked
    [_infoButton setTarget:self];
    [_infoButton setAction:@selector(toggleInfoPanel:)];
    
    return _infoButton;
}

-(BOOL)becomeFirstResponder
{
    return YES;
}

-(BOOL)acceptsFirstResponder
{
    return YES;
}


- (void)willHidePIXView
{
    [self.view.window removeChildWindow:self.controlWindow];
    
    [[PIXLeapInputManager sharedInstance] removeResponder:self];
    
    
}

-(void)multiFingerSwipeUp
{
    [self.navigationViewController popViewController];
}

-(void)multiFingerSwipeRight
{
    [self.pageController navigateBack:nil];
}

-(void)keyDown:(NSEvent *)theEvent
{
    [self interpretKeyEvents:@[theEvent]];
    
}

-(void)moveForward:(id)sender
{
    [self nextPage:sender];
}

-(void)moveBackward:(id)sender
{
    [self lastPage:sender];
}

-(void)moveRight:(id)sender
{
    [self nextPage:sender];
}

-(void)moveLeft:(id)sender
{
    [self lastPage:sender];
}

-(void)moveDown:(id)sender
{
    [self nextPage:sender];
}

-(void)moveUp:(id)sender
{
    [self lastPage:sender];
}

-(IBAction)nextPage:(id)sender
{
    [self.pageController navigateForward:nil];
}

-(IBAction)lastPage:(id)sender
{
    [self.pageController navigateBack:nil];
}



-(void)multiFingerSwipeLeft
{
    [self.pageController navigateForward:nil];
}

#pragma mark - 
#pragma mark mouse movement methods (for hiding and showing the hud)

-(void)mouseEntered:(NSEvent *)theEvent
{
    [self unfadeControls];
    
    // stop any current timed control fades
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tryFadeControls) object:nil];
    
    // start another timer
    [self performSelector:@selector(tryFadeControls) withObject:nil afterDelay:2.5];
    
    self.hasMouse = YES;
    
    [self.view.window makeFirstResponder:self];
}

-(void)mouseMoved:(NSEvent *)theEvent
{
    [self unfadeControls];
    
    // stop any current timed control fades
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tryFadeControls) object:nil];
    
    // start another timer
    [self performSelector:@selector(tryFadeControls) withObject:nil afterDelay:2.5];
    
    self.hasMouse = YES;
}

-(void)mouseExited:(NSEvent *)theEvent
{
    // stop any current timed control fades
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tryFadeControls) object:nil];
    
    
    NSPoint location = [theEvent locationInWindow];
    
    
    // if we're above the view in fullscreen don't fade (user is activating the toolbar)
    if(([self.view.window styleMask] & NSFullScreenWindowMask) &&
       location.x > self.view.bounds.origin.x &&
       location.x < self.view.frame.origin.x + self.view.bounds.size.width)
    {
        return;
    }
        
    // start another timer (this one shorter than normal)
    [self performSelector:@selector(tryFadeControls) withObject:nil afterDelay:0.5];
    
    self.hasMouse = NO;
}

-(void)unfadeControls
{
    [self.controlWindow showAnimated:NO];
    [self.navigationViewController setNavBarHidden:NO];
}

-(void)tryFadeControls
{
    if(![self.controlWindow hasMouse])
    {
        [self.controlWindow hideAnimated:YES];
        
        
        // if we're in fullscreen mode then also fade the top toolbar
        if([self.view.window styleMask] & NSFullScreenWindowMask && !self.infoPanelShowing)
        {
            [self.navigationViewController setNavBarHidden:YES];
        }
        
        // hide the cursor until it moves
        if(self.hasMouse)
        {
            [NSCursor setHiddenUntilMouseMoves:YES];
        }
    }
}

- (void)updateData {
    
    self.pagerData = [[self.album.photos array] mutableCopy];
    
    
    // set the first image in our list to the main magnifying view
    if ([self.pagerData count] > 0) {
        [self.pageController setArrangedObjects:self.pagerData];
        NSInteger index = [self.album.photos indexOfObject:self.initialSelectedObject];
        [self.pageController setSelectedIndex:index];
        [self performSelector:@selector(startPreloadForController:) withObject:self.pageController afterDelay:0.0f];
    }
}

-(void)setAlbum:(PIXAlbum *)album
{
    _album = album;
}

-(void)preloadNextImagesForIndex:(NSUInteger)anIndex
{
    PIXPhoto *aPhoto = (PIXPhoto *)[self.pagerData objectAtIndex:anIndex];
    [(PIXPhoto *)aPhoto fullsizeImageStartLoadingIfNeeded:YES];
    
    NSUInteger pagerDataCount = [self.pagerData count];
    NSUInteger startIndex = anIndex>=2 ? anIndex-2 : 0;
    
    NSUInteger rangeLength = 4;
    if (startIndex+4 > pagerDataCount) {
        rangeLength = pagerDataCount-startIndex;
    }
    NSRange nearbyItemsRange = NSMakeRange(startIndex, rangeLength);
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:nearbyItemsRange];
    NSSet *newPhotosToPreload = [NSSet setWithArray:[self.pagerData objectsAtIndexes:indexSet]];
    NSMutableSet *photosToCancel = [self.preLoadPhotosSet mutableCopy];
    [photosToCancel minusSet:newPhotosToPreload];
    
    self.preLoadPhotosSet = [newPhotosToPreload mutableCopy];
    
    [photosToCancel enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        //
        [(PIXPhoto *)obj setCancelFullsizeLoadOperation:YES];
    }];
    
    [newPhotosToPreload enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        //
        [(PIXPhoto *)obj fullsizeImageStartLoadingIfNeeded:YES];
    }];
    
//    for(NSUInteger i = anIndex -2; i <= anIndex+2; i++)
//    {
//        if(i < [self.pagerData count])
//        {
//            // this will cause the image to preload
//            [(PIXPhoto *)[self.pagerData objectAtIndex:i] fullsizeImageStartLoadingIfNeeded:YES];
//        }
//    }
    
}

-(void)startPreloadForController:(NSPageController *)pageController
{
    //[self preloadNextImagesForIndex:pageController.selectedIndex];
    [self preloadNextImagesForIndex:pageController.selectedIndex];
//    double delayInSeconds = 0.1;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        [self preloadNextImagesForIndex:pageController.selectedIndex];
//    });
}



@end

@implementation PIXPageViewController (NSPageControllerDelegate)
- (NSString *)pageController:(NSPageController *)pageController identifierForObject:(id)object {
    if (object==nil) {
        DLog(@"identifierForObject has nil object");
    }
    return @"picture";
    
//    if (![[object imageRepresentationType] isEqualToString:IKImageBrowserQTMoviePathRepresentationType]) {
//        return @"picture";
//    }
//    return @"video";
}

- (NSViewController *)pageController:(NSPageController *)pageController viewControllerForIdentifier:(NSString *)identifier {
    //NSLog(@"pageController.selectedIndex : %ld", pageController.selectedIndex);
    PIXImageViewController *aVC =  [[PIXImageViewController alloc] initWithNibName:@"AutoSizingImageView" bundle:nil];
    [aVC.view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    aVC.pageViewController = self;
    return aVC;
    
    //TODO: add video support
//    if (![identifier isEqualToString:@"video"])
//    {
//        PIXImageViewController *aVC =  [[PIXImageViewController alloc] initWithNibName:@"AutoSizingImageView" bundle:nil];
//        [aVC.view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
//        aVC.pageViewController = self;
//        return aVC;
//    } else {
//        NSViewController *videoView = [[NSViewController alloc] initWithNibName:@"videoview" bundle:nil];
//        return videoView;
//    }
}

-(void)pageController:(NSPageController *)pageController prepareViewController:(NSViewController *)viewController withObject:(id)object {
    
//    if(object == nil) {
//        return;
//    }
    
    viewController.representedObject = object;
    // viewControllers may be reused... make sure to reset important stuff like the current magnification factor.
    
    // Normally, we want to reset the magnification value to 1 as the user swipes to other images. However if the user cancels the swipe, we want to leave the original magnificaiton and scroll position alone.
    
    BOOL isRepreparingOriginalView = (self.initialSelectedObject && self.initialSelectedObject == object) ? YES : NO;
    if (!isRepreparingOriginalView) {
        [(NSScrollView*)viewController.view setMagnification:1.0];
        //[self makeSelectedViewFirstResponder];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startPreloadForController:) object:pageController];
    }
//    else {
//        
//    }
}

- (void)pageControllerWillStartLiveTransition:(NSPageController *)pageController {
    // Remember the initial selected object so we can determine when a cancel occurred.
    self.initialSelectedObject = [pageController.arrangedObjects objectAtIndex:pageController.selectedIndex];
}

/*
-(void)makeSelectedViewFirstResponder
{
    NSWindow *mainWindow = [[NSApplication sharedApplication] mainWindow];
    //[mainWindow setContentView:aViewController.view];
    
    NSView *aView = self.pageController.selectedViewController.view;//
    //aView = [self.pageController.selectedViewController.view enclosingScrollView];

    
    
    //[mainWindow makeFirstResponder:self];
}*/


- (void)pageController:(NSPageController *)pageController didTransitionToObject:(id)object
{
    //NSLog(@"didTransitionToObject : %@", object);
    
    
 //   [self makeSelectedViewFirstResponder];
    /*dispatch_async(dispatch_get_current_queue(), ^{
     
     NSWindow *mainWindow = [[NSApplication sharedApplication] mainWindow];
     //[mainWindow setContentView:aViewController.view];
     
     NSView *aView = self.pageController.selectedViewController.view;//
     //aView = [self.pageController.selectedViewController.view enclosingScrollView];
     
     
     [mainWindow makeFirstResponder:aView];
     
     });*/
    
    [self.currentImageVC setIsCurrentView:NO];
    
    self.currentImageVC = (PIXImageViewController *)[pageController selectedViewController];
    
    [self.infoPanelVC setPhoto:[self.pagerData objectAtIndex:pageController.selectedIndex]];
    
    [self.currentImageVC setIsCurrentView:YES];
    
    
    [self performSelector:@selector(startPreloadForController:) withObject:pageController afterDelay:0.0f];

}

- (void)pageControllerDidEndLiveTransition:(NSPageController *)aPageController {
    [aPageController completeTransition];
    

    
    
    //[self makeSelectedViewFirstResponder];
}



@end

