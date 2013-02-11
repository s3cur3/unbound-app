//
//  PIXGridViewController.h
//  UnboundApp
//
//  Created by Bob on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXViewController.h"
#import "CNGridView.h"
#import "PIXGradientBarView.h"

@interface PIXGridViewController : PIXViewController <CNGridViewDataSource, CNGridViewDelegate>

@property (strong) IBOutlet CNGridView *gridView;
@property (strong) NSMutableArray *items;

@property (strong) IBOutlet PIXGradientBarView * toolbar;
@property (strong) IBOutlet NSTextField * toolbarTitle;
@property (strong) IBOutlet NSScrollView * scrollView;

-(void)showToolbar:(BOOL)animated;
-(void)hideToolbar:(BOOL)animated;

@end
