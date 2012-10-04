//
//  MainWindowController.m
//  Unbound4
//
//  Created by Bob on 10/2/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "MainWindowController.h"
#import "MainViewController.h"
#import "PageViewController.h"
#import "IKBController.h"
#import <Quartz/Quartz.h>

@interface MainWindowController ()

@end

@implementation MainWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        _mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
        
        [self.window.contentView setAutoresizesSubviews:YES];
        [_mainViewController.view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        
        // 2. Add the view controller to the Window's content view
        [self.window.contentView addSubview:_mainViewController.view];
        _mainViewController.view.frame = ((NSView*)self.window.contentView).bounds;
        
        [self pageViewController];
    }
    
    return self;
}

-(PageViewController *)pageViewController
{
    if (_pageViewController == nil) {
        _pageViewController = [[PageViewController alloc] initWithNibName:@"PageViewController" bundle:nil];
        [_pageViewController.view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    }
    return _pageViewController;
}

-(MainViewController *)mainViewController
{
    if (_mainViewController == nil) {
        _mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    }
    return _mainViewController;
}

- (void)showMainView;
{
    
    //pageViewController.parentViewController = self;
    //[self.pageViewController.view removeFromSuperview];
    [(NSView *)[[self window] contentView] replaceSubview:self.pageViewController.view with:self.mainViewController.view];
    //[self.window.contentView addSubview:self.mainViewController.view];
    self.mainViewController.view.frame = ((NSView*)self.window.contentView).bounds;
    [self.mainViewController.view setNeedsDisplay:YES];
    [self.mainViewController.imageBrowserController updateBrowserView];
    //[self.window.contentView setNeedsDisplay:YES];
}

- (void)showPageViewForIndex:(NSUInteger)index;
{
    //self.pageViewController = [[PageViewController alloc] initWithNibName:@"PageViewController" bundle:nil];
    //pageViewController.parentViewController = self;
    self.pageViewController.pageController.selectedIndex = index;
    [(NSView *)[[self window] contentView] replaceSubview:self.mainViewController.view with:self.pageViewController.view];
    //[self.mainViewController.view addSubview:self.pageViewController.view];
    self.pageViewController.view.frame = ((NSView*)self.window.contentView).bounds;
    //self.pageViewController.view.frame = ((NSView*)self.window.contentView).bounds;
    [self.pageViewController.view setNeedsDisplay:YES];
}

- (void)showPageView;
{
    [self showPageViewForIndex:0];
}

/*- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}*/


- (BOOL)windowShouldClose:(id)sender;
{
    return YES;
}

@end
