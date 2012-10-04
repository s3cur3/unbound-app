//
//  PageViewController.m
//  Unbound4
//
//  Created by Bob on 10/1/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PageViewController.h"
#import "AppDelegate.h"
#import "IKBBrowserItem.h"
#import "MainViewController.h"
#import "MainWindowController.h"

@interface PageViewController ()
@property (strong) NSMutableArray *pagerData;
@property (assign) id initialSelectedObject;
@end


@implementation PageViewController

- (IBAction)goBack:sender;
{
    //[self.view removeFromSuperview];
    //[self.parentViewController unhideSubviews];
    [(MainWindowController *)self.view.window.windowController showMainView];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateData) name:@"UB_PATH_CHANGED" object:nil];
    }
    
    return self;
}

-(void) updateData
{
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:350];
    for (IKBBrowserItem *item in [[AppDelegate applicationDelegate]
                                  imagesArray])
    {
        [tmp addObject:item.image];
    }
	//Allocate some space for the data source
    self.pagerData = tmp;
    if (!self.pagerData) {
        self.pagerData = [[NSMutableArray alloc] initWithCapacity:10];
    }
	
    [self.pageController setArrangedObjects:self.pagerData];
    [self.view setNeedsDisplay:YES];
}


- (void)awakeFromNib
{
    [self updateData];
    self.pageController.transitionStyle = NSPageControllerTransitionStyleHorizontalStrip;
}

- (NSString *)pageController:(NSPageController *)pageController identifierForObject:(id)object {
    return @"picture";
}

- (NSViewController *)pageController:(NSPageController *)pageController viewControllerForIdentifier:(NSString *)identifier {
    return [[NSViewController alloc] initWithNibName:@"imageview" bundle:nil];
}

-(void)pageController:(NSPageController *)pageController prepareViewController:(NSViewController *)viewController withObject:(id)object {
    // viewControllers may be reused... make sure to reset important stuff like the current magnification factor.
    
    // Normally, we want to reset the magnification value to 1 as the user swipes to other images. However if the user cancels the swipe, we want to leave the original magnificaiton and scroll position alone.
    
    BOOL isRepreparingOriginalView = (self.initialSelectedObject && self.initialSelectedObject == object) ? YES : NO;
    if (!isRepreparingOriginalView) {
        [(NSScrollView*)viewController.view setMagnification:1.0];
    }
    
    // Since we implement this delegate method, we are reponsible for setting the representedObject.
    viewController.representedObject = object;
}

- (void)pageControllerWillStartLiveTransition:(NSPageController *)aPageController {
    // Remember the initial selected object so we can determine when a cancel occurred.
    self.initialSelectedObject = [aPageController.arrangedObjects objectAtIndex:aPageController.selectedIndex];
}

- (void)pageControllerDidEndLiveTransition:(NSPageController *)aPageController {
    [aPageController completeTransition];
}


@end
