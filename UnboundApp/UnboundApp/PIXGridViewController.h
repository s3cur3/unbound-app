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
@property (nonatomic,strong) NSMutableArray * selectedItems;
@property (strong) NSString * selectedItemsName;

@property (strong) IBOutlet PIXGradientBarView * toolbar;
@property (strong) IBOutlet NSTextField * toolbarTitle;
@property (strong) IBOutlet NSTextField * gridViewTitle;
@property (strong) IBOutlet NSScrollView * scrollView;

-(NSMenu *)menuForObject:(id)object;

-(void)showToolbar:(BOOL)animated;
-(void)hideToolbar:(BOOL)animated;
-(void)updateToolbar;

-(IBAction)selectAll:(id)sender;
-(IBAction)selectNone:(id)sender;
-(IBAction)toggleSelection:(id)sender;

@end
