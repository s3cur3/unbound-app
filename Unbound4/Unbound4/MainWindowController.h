//
//  MainWindowController.h
//  Unbound4
//
//  Created by Bob on 10/2/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PageViewController;
@class MainViewController;

@interface MainWindowController : NSWindowController <NSWindowDelegate>
{
    //IBOutlet MainViewController *_mainViewController;
    //IBOutlet PageViewController *_pageViewController;
}

@property (nonatomic, strong) IBOutlet MainViewController *mainViewController;
- (void)showMainView;

@property (nonatomic, strong) IBOutlet PageViewController *pageViewController;
- (void)showPageViewForIndex:(NSUInteger)index;
- (void)showPageView;

- (BOOL)windowShouldClose:(id)sender;

@end
