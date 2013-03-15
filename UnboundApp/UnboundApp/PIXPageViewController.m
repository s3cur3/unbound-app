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

@interface PIXPageViewController () <leapResponder>

@property NSArray * viewControllers;

@end

@implementation PIXPageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        
        self.viewControllers = [[NSMutableArray alloc] initWithCapacity:3];
        PIXImageViewController *aVC1 =  [[PIXImageViewController alloc] initWithNibName:@"imageview" bundle:nil];
        aVC1.pageViewController = self;
        PIXImageViewController *aVC2 =  [[PIXImageViewController alloc] initWithNibName:@"imageview" bundle:nil];
        aVC2.pageViewController = self;
        PIXImageViewController *aVC3 =  [[PIXImageViewController alloc] initWithNibName:@"imageview" bundle:nil];
        aVC3.pageViewController = self;
        
        self.viewControllers = @[aVC1, aVC2, aVC3];
    }
    
    return self;
}

-(void)awakeFromNib
{
    if (self.album!=nil)
    {
        [self.pageController.view setWantsLayer:YES];
        self.pageController.transitionStyle = NSPageControllerTransitionStyleHorizontalStrip;
        
        [self updateData];
        
        
    }
}
/*
-(void)setupToolbar
{
//    [self.navigationViewController setNavBarHidden:YES];
}
*/


- (void)willShowPIXView
{
    [[PIXLeapInputManager sharedInstance] addResponder:self];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.view.window makeFirstResponder:self];
        
    });
}

- (void)willHidePIXView
{
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

-(void)moveRight:(id)sender
{
    [self.pageController navigateForward:nil];
}

-(void)moveLeft:(id)sender
{
    [self.pageController navigateBack:nil];
}



-(void)multiFingerSwipeLeft
{
    [self.pageController navigateForward:nil];
}

- (void)updateData {
    
    self.pagerData = [[self.album.photos array] mutableCopy];
    
    
    // set the first image in our list to the main magnifying view
    if ([self.pagerData count] > 0) {
        [self.pageController setArrangedObjects:self.pagerData];
        NSInteger index = [self.album.photos indexOfObject:self.initialSelectedObject];
        [self.pageController setSelectedIndex:index];
    }
}

-(void)setAlbum:(PIXAlbum *)album
{
    _album = album;
}

-(void)preloadNextImagesForIndex:(NSUInteger)anIndex
{
    //PIXPhoto *startingPhoto = (PIXPhoto *)self.initialSelectedObject;
    //NSImage *anImage = [[NSImage alloc] initWithContentsOfURL:aPhoto.filePath];
    //[self.cachedImages replaceObjectAtIndex:0 withObject:anImage];
    //[self.cachedImages addObject:anImage];
    
    NSUInteger prevIndex = anIndex -1;
    NSUInteger nextIndex = anIndex+1;
    
    if(prevIndex > 0 && prevIndex < [self.pagerData count])
    {
        id representedObject = [self.pagerData objectAtIndex:prevIndex];
        [(PIXImageViewController *)[self.viewControllers objectAtIndex:prevIndex%3] setRepresentedObject:representedObject];
    }
    
    if(nextIndex < [self.pagerData count])
    {
        id representedObject = [self.pagerData objectAtIndex:nextIndex];
        [(PIXImageViewController *)[self.viewControllers objectAtIndex:nextIndex%3] setRepresentedObject:representedObject];
    }
    
    
    /*
    if (self.pagerData.count > anIndex) {
        for (NSUInteger i = (int)anIndex; i<anIndex + 5; i++)
        {
            if (self.pagerData.count <= i) {
                DLog(@"done loading fullsize images through undex %ld", i);
                return;
            }
            
            PIXPhoto *aPhoto = (PIXPhoto *)[self.album.photos objectAtIndex:i];
            
            // this will call a notification once the image is loaded in the bg
            [aPhoto fullsizeImage];
            
        }
    }*/
}


@end

@implementation PIXPageViewController (NSPageControllerDelegate)
- (NSString *)pageController:(NSPageController *)pageController identifierForObject:(id)object {
    
    int index = [self.pagerData indexOfObject:object] % 3;
    
    return [NSString stringWithFormat:@"%d", index];
    
    /*
    return [(PIXPhoto *)object name];
    
    if (![[object imageRepresentationType] isEqualToString:IKImageBrowserQTMoviePathRepresentationType]) {
        return @"picture";
    }
    return @"video";
     */
}

- (NSViewController *)pageController:(NSPageController *)pageController viewControllerForIdentifier:(NSString *)identifier {
    //NSLog(@"pageController.selectedIndex : %ld", pageController.selectedIndex);
   
    return [self.viewControllers objectAtIndex:[identifier integerValue]];
    
}

-(void)pageController:(NSPageController *)pageController prepareViewController:(NSViewController *)viewController withObject:(id)object {
    
    viewController.representedObject = object;
    // viewControllers may be reused... make sure to reset important stuff like the current magnification factor.
    
    // Normally, we want to reset the magnification value to 1 as the user swipes to other images. However if the user cancels the swipe, we want to leave the original magnificaiton and scroll position alone.
    
    BOOL isRepreparingOriginalView = (self.initialSelectedObject && self.initialSelectedObject == object) ? YES : NO;
    if (!isRepreparingOriginalView) {
        [(NSScrollView*)viewController.view setMagnification:1.0];
        //[self makeSelectedViewFirstResponder];
    }
    
    
    //[self preloadNextImagesForIndex:pageController.selectedIndex];
    
}

- (void)pageControllerWillStartLiveTransition:(NSPageController *)pageController {
    // Remember the initial selected object so we can determine when a cancel occurred.
    self.initialSelectedObject = [pageController.arrangedObjects objectAtIndex:pageController.selectedIndex];
}

-(void)makeSelectedViewFirstResponder
{
    NSWindow *mainWindow = [[NSApplication sharedApplication] mainWindow];
    //[mainWindow setContentView:aViewController.view];
    
    NSView *aView = self.pageController.selectedViewController.view;//
    //aView = [self.pageController.selectedViewController.view enclosingScrollView];
    /*if (aView == nil) {
     aView = aViewController.view;
     }*/
    
    
    [mainWindow makeFirstResponder:aView];
}


- (void)pageController:(NSPageController *)pageController didTransitionToObject:(id)object
{
    NSLog(@"didTransitionToObject : %@", object);
    
    
    [self makeSelectedViewFirstResponder];
    /*dispatch_async(dispatch_get_current_queue(), ^{
     
     NSWindow *mainWindow = [[NSApplication sharedApplication] mainWindow];
     //[mainWindow setContentView:aViewController.view];
     
     NSView *aView = self.pageController.selectedViewController.view;//
     //aView = [self.pageController.selectedViewController.view enclosingScrollView];
     
     
     [mainWindow makeFirstResponder:aView];
     
     });*/
}

- (void)pageControllerDidEndLiveTransition:(NSPageController *)aPageController {
    [aPageController completeTransition];
    [self makeSelectedViewFirstResponder];
}



@end

