//
//  PIXPageViewController.h
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXViewController.h"

@class Album;

@interface PIXPageViewController : PIXViewController <NSPageControllerDelegate>

@property (nonatomic, strong) IBOutlet Album *album;
@property (assign) IBOutlet NSPageController *pageController;
@property (strong) NSMutableArray *pagerData;

@property (assign) id initialSelectedObject;

@property (nonatomic, strong) NSViewController *pageControllerSelectedViewController;

@end
