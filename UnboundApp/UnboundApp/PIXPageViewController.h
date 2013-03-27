//
//  PIXPageViewController.h
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXViewController.h"

@class Album;
@class PIXAlbum;
@class PIXViewController;

@interface PIXPageViewController : PIXViewController <NSPageControllerDelegate>

@property (nonatomic, strong) IBOutlet PIXAlbum *album;
@property (weak) IBOutlet NSPageController *pageController;
@property (strong) NSMutableArray *pagerData;



@property (weak) id initialSelectedObject;

@property (nonatomic, strong) NSViewController *pageControllerSelectedViewController;

-(IBAction)toggleInfoPanel:(id)sender;

-(IBAction)nextPage:(id)sender;
-(IBAction)lastPage:(id)sender;

-(IBAction)toggleFullScreen:(id)sender;

@end
