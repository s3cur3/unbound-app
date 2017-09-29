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
#import "PIXDefines.h"
#import "PIXMainWindowController.h"
#import "PIXAlbum.h"
#import "PIXPhoto.h"
#import "PIXImageViewController.h"
#import "PIXVideoViewController.h"
#import "PIXNavigationController.h"

#import "PIXPageHUDWindow.h"
#import "PIXPageHUDView.h"

#import "PIXCustomShareSheetViewController.h"
#import "PIXShareManager.h"

#import "PIXInfoPanelViewController.h"

#import "PIXSlideshowOptonsViewController.h"

#import "PIXViewController.h"

#import "PIXFileManager.h"

#import "PIXPageView.h"

#import "PIXPlayVideoHUDWindow.h"

@interface PIXPageViewController () <PIXSlideshowOptonsDelegate, NSMenuDelegate>

@property NSArray * viewControllers;

@property (weak) IBOutlet PIXPageHUDView * controlView;
@property (strong) IBOutlet PIXPageHUDWindow * controlWindow;
@property (weak) IBOutlet NSLayoutConstraint *infoPanelSpacer;

@property (weak) IBOutlet NSButton * rightArrowButton;
@property (weak) IBOutlet NSButton * leftArrowButton;

@property (weak) IBOutlet NSButton * fullscreenButton;

@property (weak) IBOutlet PIXInfoPanelViewController * infoPanelVC;

@property BOOL infoPanelShowing;

@property (nonatomic, strong) NSToolbarItem * deleteItem;
@property (nonatomic, strong) NSToolbarItem * shareItem;
@property (nonatomic, strong) NSToolbarItem * infoItem;
@property (nonatomic, strong) NSButton * infoButton;

@property (nonatomic, strong) PIXImageViewController * currentImageVC;
@property (weak) PIXSlideshowOptonsViewController *slideshowOptionsVC;

@property BOOL hasMouse;

// slideshow properties
@property BOOL isPlayingSlideshow;
@property NSArray * slideshowPhotoIndexes;
@property NSInteger currentSlide;
@property (weak) IBOutlet NSButton * startSlideshowButton;

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
        [self.view setWantsLayer:YES];
        [self.view.layer setBackgroundColor:[NSColor blackColor].CGColor];
        self.pageController.transitionStyle = NSPageControllerTransitionStyleHorizontalStrip;
        
        [self.infoPanelSpacer setConstant:0.0];
        self.infoPanelShowing = NO;
        
        //[self.view setNeedsUpdateConstraints:YES];
    }
    
    if (self.preLoadPhotosSet == nil) {
        self.preLoadPhotosSet = [[NSMutableSet alloc] initWithCapacity:4];
    }
}

// this is called when photo changes
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(self.pageController.selectedIndex+1 >= [self.pagerData count])
    {
        [self.rightArrowButton setAlphaValue:0.2];
    }
    
    else
    {
        [self.rightArrowButton setAlphaValue:1.0];
    }
    
    if(self.pageController.selectedIndex == 0)
    {
        [self.leftArrowButton setAlphaValue:0.2];
    }
    
    else
    {
        [self.leftArrowButton setAlphaValue:1.0];
    }
    
    PIXPhoto * thisPhoto = [self.pagerData objectAtIndex:self.pageController.selectedIndex];
    
    // update the info panel if it's visible
    if(self.infoPanelShowing)
    {
        [self.infoPanelVC setPhoto:thisPhoto];
        
    }
    
    //DLog(@"New Photo Index = %ld", self.pageController.selectedIndex);
    
    // update the HUD (caption view)
    [self.controlView setPhoto:thisPhoto];
    
    [self updateTitle];
    
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.delegate pagerDidMoveToPhotoWithPath:thisPhoto.path atIndex:self.pageController.selectedIndex];
    });
    
    
    [self.currentImageVC setIsCurrentView:NO];
    
    self.currentImageVC = (PIXImageViewController *)[self.pageController selectedViewController];
    if (thisPhoto.videoFile==nil) {
        [self.currentImageVC setIsCurrentView:YES];
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
        
        // update the panel info
        [self.infoPanelVC setPhoto:[self.pagerData objectAtIndex:self.pageController.selectedIndex]];
        
        [self.infoPanelVC updateMap];
    }
    
    self.infoPanelShowing = !self.infoPanelShowing;
    
    
}

-(void)toggleFullScreen:(id)sender
{
    [self.view.window toggleFullScreen:sender];
}

-(IBAction)playButtonPressed:(id)sender
{
    // if we're already playing the slideshow then stop it
    if(self.isPlayingSlideshow)
    {
        [self stopSlideShow:nil];
        return;
    }
    
    // otherwise present the options
    PIXSlideshowOptonsViewController *controller = [[PIXSlideshowOptonsViewController alloc]
                                                    initWithNibName:@"PIXSlideshowOptonsViewController" bundle:nil];
    controller.delegate = self;
    
    
    NSPopover *popover = [[NSPopover alloc] init];
    [popover setContentViewController:controller];
    
    controller.myPopover = popover;
    
    self.slideshowOptionsVC = controller;
    
    [popover setAnimates:YES];
    [popover setBehavior:NSPopoverBehaviorTransient];
    [popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
    
}

-(IBAction)startSlideShow:(id)sender
{
    self.isPlayingSlideshow = YES;
    self.startSlideshowButton.image = [NSImage imageNamed:@"pause"];
    
    if([self.pageController.view respondsToSelector:@selector(setLayerUsesCoreImageFilters:)])
    {
        [self.pageController.view setLayerUsesCoreImageFilters:YES];
    }
    
    // set up an array of integers for the slideshowPhotoIndexes array (we use this to handle shuffle)
    NSMutableArray *photoIndexes = [[NSMutableArray alloc] initWithCapacity:self.pagerData.count];
    
    NSUInteger numPhotos = self.pagerData.count;
    
    for (NSInteger i = 0; i < numPhotos; i++)
    {
        [photoIndexes addObject:[NSNumber numberWithInteger:i]];
    }
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"slideshowShouldShuffle"])
    {
        // if we're shuffling, then shuffle the indexes
        // randomize the order
        NSUInteger count = [photoIndexes count];
        for (NSUInteger i = 0; i < count; ++i) {
            // Select a random element between i and end of array to swap with.
            NSInteger nElements = count - i;
            NSInteger n = (arc4random() % nElements) + i;
            [photoIndexes exchangeObjectAtIndex:i withObjectAtIndex:n];
        }
        
        self.slideshowPhotoIndexes = photoIndexes;
        self.currentSlide = -1; // start at the begining of the random list (this will be incremented immediatley)
        
        // go to next slide righ away, No need for a delay if it's random
        [self nextSlide];
    }
    
    else
    {
        self.slideshowPhotoIndexes = photoIndexes;
        self.currentSlide = [self.pageController selectedIndex];
        
        CGFloat interval = [[NSUserDefaults standardUserDefaults] floatForKey:kSlideshowTimeInterval];
        [self performSelector:@selector(nextSlide) withObject:nil afterDelay:interval];
    }

}

-(IBAction)stopSlideShow:(id)sender
{
    self.isPlayingSlideshow = NO;
    self.startSlideshowButton.image = [NSImage imageNamed:@"play"];
    
    // cancel any timers that are running
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(nextSlide) object:nil];
    
}

-(void)restartNextSlideIfNeeded
{
    // don't do anything unless we're playing a slideshow
    if(!self.isPlayingSlideshow) return;
    
    // cancel any timers that are running
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(nextSlide) object:nil];
    
    // if we need to go to the current slide (not shuffle) then set that
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"slideshowShouldShuffle"])
    {
        self.currentSlide = self.pageController.selectedIndex;
    }
    
    CGFloat interval = [[NSUserDefaults standardUserDefaults] floatForKey:kSlideshowTimeInterval];
    [self performSelector:@selector(nextSlide) withObject:nil afterDelay:interval];
}

-(void)nextSlide
{
    self.currentSlide++;
    
    if(self.currentSlide < self.slideshowPhotoIndexes.count)
    {
        CGFloat interval = [[NSUserDefaults standardUserDefaults] floatForKey:kSlideshowTimeInterval];
        NSNumber * nextIndex = [self.slideshowPhotoIndexes objectAtIndex:self.currentSlide];
        
        
        //
        
        /*
        [self.pageController setTransitionStyle:NSPageControllerTransitionStyleStackBook];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [self.pageController.animator setSelectedIndex:[nextIndex intValue]];
        } completionHandler:^{
            [self.pageController completeTransition];
        }];*/
        
        
        // animate the transition
        NSString *type = nil;
        CIFilter *coreImageFilter = nil;
        PIXPageView *aPageView = (PIXPageView *)self.pageController.view;
        
        NSInteger transition = [[NSUserDefaults standardUserDefaults] integerForKey:@"slideshowTransitionStyle"];
        if (transition ==7) {
            NSUInteger fiterCount = aPageView.transitions.count+3;
            NSUInteger filterIndex = self.currentSlide % fiterCount;
            transition = filterIndex;
        }
        switch (transition)
        {
            case 0:
                type = kCATransitionFade;
                break;
            case 1:
                type = kCATransitionPush;
                break;
            case 2:
                type = kCATransitionReveal;
                break;
                
            case 3:
            case 4:
            case 5:
            case 6:
                coreImageFilter = [aPageView filterForTransitionNamed:(NSString *)[aPageView.coreImageTransitionNames objectAtIndex:transition-3]];
                break;
            
            default:
                DLog(@"Undexpected value for transition index : '%ld', Using Fade as a fallback.", transition);
#ifdef DEBUG
                NSCParameterAssert(transition!=7);
#endif
                type = kCATransitionFade;
                break;
        }
        
        
        CATransition *animation = [CATransition animation];
        
        
        if (type==nil) {
            [animation setFilter:coreImageFilter];
            [animation setDuration:0.5+(interval/4.0)];
//            NSUInteger fiterCount = aPageView.transitions.count;
//            NSUInteger filterIndex = self.currentSlide % fiterCount;
//            DLog(@"Using filter at index : %ld", filterIndex);
//            CIFilter *aFilter = [aPageView.transitions objectAtIndex:filterIndex];
//            [animation setFilter:aFilter];
//            [animation setDuration:2.0+(interval/10.0)];
        } else {
            [animation setType:type];
            [animation setSubtype:kCATransitionFromRight];
            [animation setDuration:0.5+(interval/10.0)];
        }
        

        
        // dispatch the transition so it goes a little smoother
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if([self.pageController.view respondsToSelector:@selector(setLayerUsesCoreImageFilters:)])
            {
                [self.pageController.view setLayerUsesCoreImageFilters:YES];
            }
            
            [self.pageController.view.layer addAnimation:animation forKey:@" "];
            [self.pageController setSelectedIndex:[nextIndex intValue]];
        });
        
        
        
        [self performSelector:@selector(nextSlide) withObject:nil afterDelay:interval];
         
    }
    
    // if we're at the end of the loop
    else
    {
        // if we should keep looping then start at the begining
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"slideshowShouldLoop"])
        {
            self.currentSlide = -1; // start at -1 because it will increment immediatley
            [self nextSlide];
        }
        
        // otherwise stop
        else
        {
            [self stopSlideShow:nil];
        }
    }
}

- (void)willShowPIXView
{
    [self.pageController addObserver:self forKeyPath:@"selectedIndex" options:NSKeyValueObservingOptionNew context:nil];

    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self updateData];
        
        [self.view.window makeFirstResponder:self];
//        self.nextResponder = self.view;
        
        [self.view.window addChildWindow:self.controlWindow ordered:NSWindowAbove];        
        [self.controlWindow orderFront:self];
        
        [self.controlView setNeedsDisplay:YES];
        
        
        
        [self.controlWindow setParentView:self.pageController.view];
        
        
        [self.pageController.view layoutSubtreeIfNeeded];
        
        PIXPhoto * thisPhoto = [self.pagerData objectAtIndex:self.pageController.selectedIndex];
        
        [self.infoPanelVC setPhoto:thisPhoto];
        [self.controlView setPhoto:thisPhoto];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullscreenChanged:) name:NSWindowDidEnterFullScreenNotification object:self.view.window];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullscreenChanged:) name:NSWindowDidExitFullScreenNotification object:self.view.window];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoThumbChanged:) name:@"PhotoThumbDidChangeNotification" object:nil];
        
        [self fullscreenChanged:nil];
        
        
        // stop any current timed control fades
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tryFadeControls) object:nil];
        
        // start another timer
        [self performSelector:@selector(tryFadeControls) withObject:nil afterDelay:3];
        
        [self.currentImageVC setIsCurrentView:NO];
        
        self.currentImageVC = (PIXImageViewController *)[self.pageController selectedViewController];
        
        [self.currentImageVC setIsCurrentView:YES];
        
    });
}


-(void)updateTitle
{
    NSString * title = [NSString stringWithFormat:@"%@ - %ld of %ld", self.album.title, self.pageController.selectedIndex+1, [self.pagerData count]];
    
    [[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] setTitle:title];
}

-(void)fullscreenChanged:(id)sender
{
    // set the right icon on the expand/contract button
    if([self.view.window styleMask] & NSFullScreenWindowMask)
    {
        self.fullscreenButton.image = [NSImage imageNamed:@"contract"];
        [self.controlWindow setHasMouse:NO]; // the window loses the m
    }
    
    else
    {
        self.fullscreenButton.image = [NSImage imageNamed:@"expand"];
    }

}

-(void)photoThumbChanged:(NSNotification *)note
{
    PIXPhoto * thisPhoto = [self.pagerData objectAtIndex:self.pageController.selectedIndex];
    
    
    if(thisPhoto == note.object)
    {
        // update the info panel if it's visible
        if(self.infoPanelShowing)
        {
            [self.infoPanelVC setPhoto:nil];
            [self.infoPanelVC setPhoto:thisPhoto];
            
        }
        
        // update the HUD (caption view)
        [self.controlView setPhoto:nil];
        [self.controlView setPhoto:thisPhoto];
    }
}

-(void)setupToolbar
{
    NSArray * items = @[self.navigationViewController.backButton, self.navigationViewController.middleSpacer, self.deleteItem, self.shareItem, self.infoItem];
    
    [self.navigationViewController setNavBarHidden:NO];
    [self.navigationViewController setToolbarItems:items];
    
}

- (NSToolbarItem *)deleteItem
{
    if(_deleteItem != nil) return _deleteItem;
    
    _deleteItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"deletePhotoButton"];
    //_settingsButton.image = [NSImage imageNamed:NSImageNameSmartBadgeTemplate];
    
    NSButton * buttonView = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 60, 25)];
    
    [buttonView setImagePosition:NSNoImage];
    [buttonView setBordered:YES];
    [buttonView setBezelStyle:NSTexturedSquareBezelStyle];
    [buttonView setTitle:@"Delete"];
    
    _deleteItem.view = buttonView;
    
    [_deleteItem setLabel:@"Delete Photo"];
    [_deleteItem setPaletteLabel:@"Delete Photo"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_deleteItem setToolTip:@"Delete a Photo"];
    
    // Tell the item what message to send when it is clicked
    [buttonView setTarget:self];
    [buttonView setAction:@selector(deleteItems:)];
    
    return _deleteItem;
    
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

- (void)scrollWheel:(NSEvent *)theEvent {
    DLog(@"%@", theEvent);
}



- (void)willHidePIXView
{
    //[self.view.window removeChildWindow:self.controlWindow];
    [self.controlWindow close];
    
    id currentPageController = self.pageController.selectedViewController;
    if ([currentPageController respondsToSelector:@selector(dismissOverlay)]) {
        [currentPageController dismissOverlay];
    }
    //self.controlWindow = nil;
    //self.controlView = nil;
    
    if (self.isPlayingSlideshow) {
        [self stopSlideShow:nil];
    }

    [self.pageController removeObserver:self forKeyPath:@"selectedIndex"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.delegate = nil;
}

-(void)leapSwipeUp
{
    if(![self.view.window isKeyWindow]) return;
    
    [(NSSound *)[NSSound soundNamed:@"Pop"] play];
    
    [self.navigationViewController popViewController];
}

-(void)leapSwipeRight
{
    if(![self.view.window isKeyWindow]) return;
    
    if(self.pageController.selectedIndex-1 < [self.pagerData count])
    {
        [self.pageController navigateBack:nil];
    }
    
    else
    {
        NSBeep();
    }
    
    
    [self restartNextSlideIfNeeded];
     [self.currentImageVC setIsCurrentView:YES];
}

-(void)leapSwipeLeft
{
    if(![self.view.window isKeyWindow]) return;
    
    if(self.pageController.selectedIndex+1 < [self.pagerData count])
    {
        [self.pageController navigateForward:nil];
    }
    
    else
    {
        NSBeep();
    }
    
    [self restartNextSlideIfNeeded];
     [self.currentImageVC setIsCurrentView:YES];
}

-(void)leapPointerSelect:(NSPoint)normalizedPosition
{
    if(![self.view.window isKeyWindow]) return;
    
    if(normalizedPosition.x < 0.4)
    {
        if(self.pageController.selectedIndex-1 < [self.pagerData count])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                    [self.pageController navigateBack:nil];
                
            });
            
            [[NSSound soundNamed:@"click"] play];
        }
        
        else
        {
            NSBeep();
        }
    }
    
    else
    {
        if(self.pageController.selectedIndex+1 < [self.pagerData count])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                [self.pageController navigateForward:nil];
                
            });
            
            [[NSSound soundNamed:@"click"] play];
        }
        
        else
        {
            NSBeep();
        }
    }
    
    
    
    [self restartNextSlideIfNeeded];
}

-(void)keyDown:(NSEvent *)theEvent
{
    
    if ([theEvent type] == NSKeyDown)
    {
        NSString* pressedChars = [theEvent characters];
        if ([pressedChars length] == 1)
        {
            unichar pressedUnichar = [pressedChars characterAtIndex:0];
            if(pressedUnichar == ' ') // space is the same as cancle
            {
                [self cancelOperation:theEvent];
                return;
            }
            
            if(pressedUnichar == 'f') // f should togge fullscreen
            {
                [self.view.window toggleFullScreen:theEvent];
                return;
            }
            
            if(pressedUnichar == '') // delete shoudl delete items
            {
                [self deleteItems:nil];
                return;
            }
            
            if(pressedUnichar == '\r') // return should play if it's a video
            {
                if ([self.pageController.selectedViewController isKindOfClass:[PIXVideoViewController class]]) {
                    PIXVideoViewController *videoVC = (PIXVideoViewController *)self.pageController.selectedViewController;
                    
                        
                    [videoVC playMoviePressed:nil];
                    
                    return;
                    
                }
            }
        }
    }
    
    
    [super keyDown:theEvent];
    
    
}

-(void)cancelOperation:(id)sender
{
    [self.navigationViewController popViewController];
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
    NSUInteger currentIndex = [self.pageController selectedIndex];
    currentIndex++;
    
    if(currentIndex < [self.pagerData count])
    {
        [self.pageController setSelectedIndex:currentIndex];
    }
    
    else
    {
        NSBeep();
        //[[NSSound soundNamed:@"Morse"] play];
    }
    //[self.pageController navigateForward:nil];
    
    [self restartNextSlideIfNeeded];
    
     [self.currentImageVC setIsCurrentView:YES];
}

-(IBAction)lastPage:(id)sender
{
    NSUInteger currentIndex = [self.pageController selectedIndex];
    currentIndex--;
    
    if(currentIndex < [self.pagerData count])
    {        
        [self.pageController setSelectedIndex:currentIndex];
    }
    
    else
    {
        NSBeep();
        //[[NSSound soundNamed:@"Morse"] play];
    }
    
    //[self.pageController navigateBack:nil];
    
    [self restartNextSlideIfNeeded];
    
     [self.currentImageVC setIsCurrentView:YES];
}


-(void)rightMouseDown:(NSEvent *)theEvent {
    DLog(@"rightMouseDown:%@", theEvent);
    PIXPhoto *aPhoto = [self.pagerData objectAtIndex:self.pageController.selectedIndex];
    NSMenu *contextMenu = [self menuForObject:aPhoto];
    contextMenu.delegate = self;
    NSMenuItem *desktopBackgroundMenuItem = [[NSMenuItem alloc] initWithTitle:@"Set As Desktop Background" action:@selector(setDesktopImage:) keyEquivalent:@""];
    desktopBackgroundMenuItem.target = self;
    [contextMenu addItem:desktopBackgroundMenuItem];
    //[contextMenu addItemWithTitle:@"Set As Desktop Background" action:@selector(setDesktopImage:) keyEquivalent:@""];
    //[contextMenu insertItemWithTitle:@"Set As Desktop Background" action:@selector(setDesktopImage:) keyEquivalent:@""atIndex:0];
    [NSMenu popUpContextMenu:contextMenu withEvent:theEvent forView:self.pageController.selectedViewController.view];
}

- (IBAction) openInApp:(id)sender
{
    NSArray *itemsToOpen = [NSArray arrayWithObject:[self.pagerData objectAtIndex:self.pageController.selectedIndex]];

    for (id obj in itemsToOpen) {
        
        NSString* path = [obj path];
        [[NSWorkspace sharedWorkspace] openFile:path];
        
    }
}

- (IBAction) revealInFinder:(id)inSender
{
    NSSet *aSet = [NSSet setWithObject:[self.pagerData objectAtIndex:self.pageController.selectedIndex]];
    [aSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        NSString* path = [obj path];
        NSString* folder = [path stringByDeletingLastPathComponent];
        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:folder];
        
    }];
}

-(IBAction)getInfo:(id)sender;
{
    NSSet *aSet = [NSSet setWithObject:[self.pagerData objectAtIndex:self.pageController.selectedIndex]];
    [aSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        
        NSPasteboard *pboard = [NSPasteboard pasteboardWithUniqueName];
        [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [pboard setString:[obj path]  forType:NSStringPboardType];
        NSPerformService(@"Finder/Show Info", pboard);
        
    }];
    
}


- (IBAction) deleteItems:(id )inSender
{
    PIXPhoto *aPhoto = [self.pagerData objectAtIndex:self.pageController.selectedIndex];
     NSSet *itemsToDelete = [NSSet setWithObject:aPhoto];
    
     NSUInteger currentIndex = [self.pageController selectedIndex];
    
    [[PIXFileManager sharedInstance] deleteItemsWorkflow:itemsToDelete];
    
    if(currentIndex < [self.pagerData count])
    {
        [self.pageController setSelectedIndex:currentIndex];
    }

}

-(void)setDesktopImage:(id)sender
{
    PIXPhoto *aPhoto = [self.pagerData objectAtIndex:self.pageController.selectedIndex];
    [[PIXFileManager sharedInstance] setDesktopImage:aPhoto];
}

#pragma mark -
#pragma mark mouse movement methods (for hiding and showing the hud)



-(void)mouseEntered:(NSEvent *)theEvent
{
    
    if(self.hasMouse == NO)
    {
        [self unfadeControls];
        
        // stop any current timed control fades
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tryFadeControls) object:nil];
        
        // start another timer
        [self performSelector:@selector(tryFadeControls) withObject:nil afterDelay:3];
        
        self.hasMouse = YES;
        
        //[self.view.window makeFirstResponder:self];
    }
}

-(void)mouseMoved:(NSEvent *)theEvent
{
    [self unfadeControls];
    
    // stop any current timed control fades
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tryFadeControls) object:nil];
    
    // start another timer
    [self performSelector:@selector(tryFadeControls) withObject:nil afterDelay:3];
    
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
    if ([self.pageController.selectedViewController respondsToSelector:@selector(movieView)]) {
        //DLog(@"Don't unfadeControls if page view is movie and it is playing.");
        PIXVideoViewController *aVideoViewController = (PIXVideoViewController *)self.pageController.selectedViewController;
        if (aVideoViewController.overlayWindow!=nil ||
            [aVideoViewController movieIsPlaying]==NO) {
            [self.controlWindow showAnimated:NO];
        }
    } else {
        [self.controlWindow showAnimated:NO];
    }
    [self.navigationViewController setNavBarHidden:NO];
}

-(void)tryFadeControls
{
    if(!([self.controlWindow hasMouse] || [self.controlView isTextEditing] || self.slideshowOptionsVC))
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

    
    self.pagerData = [[self.album sortedPhotos] mutableCopy];
    
    // set the first image in our list to the main magnifying view
    if ([self.pagerData count] > 0) {
        [self.pageController setArrangedObjects:self.pagerData];
        NSInteger index = [self.album.sortedPhotos indexOfObject:self.initialSelectedObject];
        
        if(index >= 0 && index < [self.pagerData count])
        {
            [self.pageController setSelectedIndex:index];
        }
    
        
        [self performSelector:@selector(startPreloadForController:) withObject:self.pageController afterDelay:0.0f];
    }
}

-(void)setAlbum:(PIXAlbum *)album
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AlbumDidChangeNotification object:_album];
    _album = album;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAlbum:) name:AlbumDidChangeNotification object:_album];
}

-(void)updateAlbum:(NSNotification *)note

{
    if([self.album.photos count] == 0)
   {
       [self.navigationViewController popViewController];
       return;
   }
    
    self.initialSelectedObject = [self.pagerData objectAtIndex:self.pageController.selectedIndex];
    
    [self updateData];
    [self updateTitle];
    
    if(self.isPlayingSlideshow)
    {
        [self stopSlideShow:nil];
        [self startSlideShow:nil];
    }
    
}

-(void)preloadNextImagesForShuffledSlideshowAtIndex:(NSUInteger)anIndex
{
    //NSCParameterAssert(self.currentSlide==anIndex);
    NSCParameterAssert(self.isPlayingSlideshow);
    NSCParameterAssert([[NSUserDefaults standardUserDefaults] boolForKey:@"slideshowShouldShuffle"]);
    
    DLog(@"Current selected photo index : %d", [[self.slideshowPhotoIndexes objectAtIndex:self.currentSlide] intValue]);
    for (int i = (int)self.currentSlide; i<self.slideshowPhotoIndexes.count; i++)
    {
        PIXPhoto *aNewPhoto = [self.pagerData objectAtIndex:i];
        [(PIXPhoto *)aNewPhoto fullsizeImageStartLoadingIfNeeded:YES];
        DLog(@"Pre-loading photo at shuffled index %d", i);
        if (i-(int)self.currentSlide >= 5) {
            DLog(@"Started loading 5 images.");
            break;
        }
    }
    
    
//    PIXPhoto *aPhoto = (PIXPhoto *)[self.pagerData objectAtIndex:anIndex];
//    [(PIXPhoto *)aPhoto fullsizeImageStartLoadingIfNeeded:YES];
    
//    NSUInteger pagerDataCount = [self.pagerData count];
//    NSUInteger startIndex = anIndex>=1 ? anIndex-1 : 0;
//    
//    NSUInteger rangeLength = 5;
//    if (startIndex+5 > pagerDataCount) {
//        rangeLength = pagerDataCount-startIndex;
//    }
//    
//    NSRange nearbyItemsRange = NSMakeRange(startIndex, rangeLength);
    //NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
   


//    int rangeLength = (int)self.slideshowPhotoIndexes.count-(currentSelectedIndex+1);
//    if (rangeLength > 5) {
//        rangeLength = 5;
//    }
    //NSArray *subArray = [self.slideshowPhotoIndexes subarrayWithRange:NSMakeRange(currentSelectedIndex, rangeLength)];
    

//    for (id aShuffledPhotoIndex in subArray)
//    {
//        [indexSet addIndex:[aShuffledPhotoIndex intValue]];
//    }
//    DLog(@"indexSet : %@", indexSet);
//    NSSet *newPhotosToPreload = [NSSet setWithArray:[self.pagerData objectsAtIndexes:indexSet]];
////    for (id aPreloadPhoto in newPhotosToPreload) {
////        [(PIXPhoto *)aPreloadPhoto fullsizeImageStartLoadingIfNeeded:YES];
////    }
//    
//    [newPhotosToPreload enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
//        //
//        [(PIXPhoto *)obj fullsizeImageStartLoadingIfNeeded:YES];
//    }];
    


    
}

-(void)preloadNextImagesForIndex:(NSUInteger)anIndex
{
    PIXPhoto *aPhoto = (PIXPhoto *)[self.pagerData objectAtIndex:anIndex];
    [(PIXPhoto *)aPhoto fullsizeImageStartLoadingIfNeeded:YES];
    
    NSUInteger pagerDataCount = [self.pagerData count];
    NSUInteger startIndex = anIndex>=1 ? anIndex-1 : 0;
    
    NSUInteger rangeLength = 5;
    if (startIndex+5 > pagerDataCount) {
        rangeLength = pagerDataCount-startIndex;
    }
    
    NSRange nearbyItemsRange = NSMakeRange(startIndex, rangeLength);
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSetWithIndexesInRange:nearbyItemsRange];
    //DLog(@"indexSet : %@", indexSet);
    
//    // if we're playing a slideshow and we're in shuffle, then also preload the next two shuffle photos
//    if(self.isPlayingSlideshow && [[NSUserDefaults standardUserDefaults] boolForKey:@"slideshowShouldShuffle"])
//    {
//        [indexSet removeAllIndexes];
//        
//        int slideToLoad = (int)self.currentSlide+1;
//        
//        if(slideToLoad < self.slideshowPhotoIndexes.count)
//        {
//            [indexSet addIndex:[[self.slideshowPhotoIndexes objectAtIndex:slideToLoad] intValue]];
//        }
//        DLog(@"Slideshow shuffled indexSet : %@", indexSet);
//    } else if (self.isPlayingSlideshow) {
//        DLog(@"Slideshow not shuffled indexSet : %@", indexSet);
//    }
    
    NSSet *newPhotosToPreload = [NSSet setWithArray:[self.pagerData objectsAtIndexes:indexSet]];
    
    
    
    NSMutableSet *photosToCancel = [self.preLoadPhotosSet mutableCopy];
    [photosToCancel minusSet:newPhotosToPreload];
    
    self.preLoadPhotosSet = [newPhotosToPreload mutableCopy];
    
    [photosToCancel enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        //
        [(PIXPhoto *)obj setCancelFullsizeLoadOperation:YES];
        [(PIXPhoto *)obj setFullsizeImage:nil];
    }];
    
    [newPhotosToPreload enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        //
        [(PIXPhoto *)obj fullsizeImageStartLoadingIfNeeded:YES];
    }];
    
    NSRange previousFarItemsRange = NSMakeRange(0, startIndex); 
    NSIndexSet *previndexSet = [NSIndexSet indexSetWithIndexesInRange:previousFarItemsRange];
    NSSet *prevItemsToRelease = [NSSet setWithArray:[self.pagerData objectsAtIndexes:previndexSet]];
    [prevItemsToRelease enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        //
        //[(PIXPhoto *)obj setCancelFullsizeLoadOperation:YES];
        PIXPhoto *aPhoto = (PIXPhoto *)obj;
        if ([aPhoto isReallyDeleted]==NO) {
            [aPhoto setFullsizeImage:nil];
        }
    }];
    
    NSUInteger farIndexStart = startIndex+rangeLength;
    NSUInteger farIndexLength = pagerDataCount-farIndexStart;
    NSRange nextFarItemsRange = NSMakeRange(farIndexStart, farIndexLength);
    NSIndexSet *nextFarIndexSet = [NSIndexSet indexSetWithIndexesInRange:nextFarItemsRange];
    NSSet *nextItemsToRelease = [NSSet setWithArray:[self.pagerData objectsAtIndexes:nextFarIndexSet]];
    [nextItemsToRelease enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        //
        //[(PIXPhoto *)obj setCancelFullsizeLoadOperation:YES];
        PIXPhoto *aPhoto = (PIXPhoto *)obj;
        if ([aPhoto isReallyDeleted]==NO) {
            [aPhoto setFullsizeImage:nil];
        }
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
    if (self.isPlayingSlideshow && [[NSUserDefaults standardUserDefaults] boolForKey:@"slideshowShouldShuffle"]) {
        [self preloadNextImagesForShuffledSlideshowAtIndex:pageController.selectedIndex];
    } else {
        [self preloadNextImagesForIndex:pageController.selectedIndex];
    }
//    double delayInSeconds = 0.1;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        [self preloadNextImagesForIndex:pageController.selectedIndex];
//    });
}

-(BOOL)isPlayingVideo;
{
    BOOL isPlaying = NO;
    if ([self.pageController.selectedViewController isKindOfClass:[PIXVideoViewController class]]) {
        PIXVideoViewController *videoVC = (PIXVideoViewController *)self.pageController.selectedViewController;
        if ([videoVC movieIsPlaying]) {
            isPlaying = YES;
        }
    }
    return isPlaying;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tryFadeControls) object:nil];
}

@end

@implementation PIXPageViewController (NSPageControllerDelegate)
- (NSString *)pageController:(NSPageController *)pageController identifierForObject:(id)object {
//    if (object==nil) {
//        DLog(@"identifierForObject has nil object");
//    }
    //return @"picture";
    
    if (![[object imageRepresentationType] isEqualToString:IKImageBrowserQTMoviePathRepresentationType]) {
        return @"picture";
    }
    return @"video";
}

- (NSViewController *)pageController:(NSPageController *)pageController viewControllerForIdentifier:(NSString *)identifier {
    if (![identifier isEqualToString:@"video"])
    {
        PIXImageViewController *aVC =  [[PIXImageViewController alloc] initWithNibName:@"AutoSizingImageView" bundle:nil];
        [aVC.view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        aVC.pageViewController = self;
        return aVC;
    } else {
        PIXVideoViewController *aVC = [[PIXVideoViewController alloc] initWithNibName:@"videoview" bundle:nil];
        aVC.pageViewController = self;
        return aVC;
    }
}

-(void)pageController:(NSPageController *)pageController prepareViewController:(NSViewController *)viewController withObject:(id)object {
    
//    if(object == nil) {
//        return;
//    }
    
    if ([viewController isKindOfClass:[PIXVideoViewController class]]) {
        PIXVideoViewController *videoVC = (PIXVideoViewController *)viewController;
        [videoVC.overlayWindow close];
    }
    
    viewController.representedObject = object;
    // viewControllers may be reused... make sure to reset important stuff like the current magnification factor.
    
    // Normally, we want to reset the magnification value to 1 as the user swipes to other images. However if the user cancels the swipe, we want to leave the original magnificaiton and scroll position alone.
    
    BOOL isRepreparingOriginalView = (self.initialSelectedObject && self.initialSelectedObject == object) ? YES : NO;
    if (!isRepreparingOriginalView) {
        if ([viewController.view respondsToSelector:@selector(setMagnification:)]) {
            [(NSScrollView*)viewController.view setMagnification:1.0];
        }
        //[self makeSelectedViewFirstResponder];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startPreloadForController:) object:pageController];
    }
//    else {
//        
//    }
}

- (void)pageControllerWillStartLiveTransition:(NSPageController *)pageController {
    
    if ([pageController.selectedViewController isKindOfClass:[PIXVideoViewController class]]) {
        PIXVideoViewController *videoVC = (PIXVideoViewController *)pageController.selectedViewController;
        [videoVC dismissOverlay];
        [videoVC.overlayWindow close];
    }
    if ([self.pageController.selectedViewController isKindOfClass:[PIXVideoViewController class]]) {
        PIXVideoViewController *videoVC = (PIXVideoViewController *)self.pageController.selectedViewController;
        [videoVC dismissOverlay];
        [videoVC.overlayWindow close];
    }
    
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
    if ([pageController.selectedViewController isKindOfClass:[PIXVideoViewController class]]) {
        PIXVideoViewController *videoVC = (PIXVideoViewController *)pageController.selectedViewController;
        [videoVC dismissOverlay];
        [videoVC.overlayWindow close];
    }
    if ([self.pageController.selectedViewController isKindOfClass:[PIXVideoViewController class]]) {
        PIXVideoViewController *videoVC = (PIXVideoViewController *)self.pageController.selectedViewController;
        [videoVC.overlayWindow close];
    }


    
    [self performSelector:@selector(startPreloadForController:) withObject:pageController afterDelay:0.0f];
    //[self preloadNextImagesForIndex:pageController.selectedIndex];
    

}

- (void)pageControllerDidEndLiveTransition:(NSPageController *)aPageController {
//    PIXPhoto *aPhoto = (PIXPhoto *)pageController.representedObject;
//    if (aPhoto.fullsizeImage == nil) {
//        DLog(@"pageControllerDidEndLiveTransition fullsizeImage not loaded : %@", aPhoto);
//    }
    if ([aPageController.selectedViewController isKindOfClass:[PIXVideoViewController class]]) {
        PIXVideoViewController *videoVC = (PIXVideoViewController *)aPageController.selectedViewController;
        [videoVC dismissOverlay];
        [videoVC.overlayWindow close];
    }

    if ([self.pageController.selectedViewController isKindOfClass:[PIXVideoViewController class]]) {
        PIXVideoViewController *videoVC = (PIXVideoViewController *)self.pageController.selectedViewController;
        [videoVC.overlayWindow close];
        
    }
    
    [aPageController completeTransition];

    [self.currentImageVC setIsCurrentView:NO];
    
    self.currentImageVC = (PIXImageViewController *)[self.pageController selectedViewController];
    
    [self.currentImageVC setIsCurrentView:YES];
    

    [self restartNextSlideIfNeeded];
    
    //[self makeSelectedViewFirstResponder];
}



@end

