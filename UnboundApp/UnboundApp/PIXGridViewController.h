//
//  PIXGridViewController.h
//  UnboundApp
//
//  Created by Bob on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXViewController.h"
#import "CNGridView.h"

@interface PIXGridViewController : PIXViewController <CNGridViewDataSource, CNGridViewDelegate>

@property (strong) IBOutlet CNGridView *gridView;
@property (strong) NSMutableArray *items;


/**
 ...
 */
- (void)gridView:(CNGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;

/**
 ...
 */
- (void)gridView:(CNGridView *)gridView rightMouseButtonClickedOnItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;

@end
