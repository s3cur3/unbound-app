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
#import "PIXRoundedProgressIndicator.h"

@interface PIXGridViewController : PIXViewController <CNGridViewDataSource, CNGridViewDelegate>

@property (strong) IBOutlet CNGridView *gridView;

@property (strong) NSMutableArray *items;
@property (nonatomic,strong) NSMutableSet * selectedItems;
@property (strong) NSString * selectedItemsName;

@property (strong) IBOutlet PIXGradientBarView * toolbar;
@property (strong) IBOutlet NSTextField * toolbarTitle;
@property (strong) IBOutlet PIXRoundedProgressIndicator * gridViewProgress;
@property (strong) IBOutlet NSTextField * gridViewTitle;
@property (strong) IBOutlet NSScrollView * scrollView;
@property (strong) IBOutlet NSView * layerBackedView;

@property (strong) IBOutlet NSView * mountDisconnectedView;

@property (strong) IBOutlet NSProgressIndicator * progressIndicator;

-(NSMenu *)menuForObject:(id)object;

-(void)showToolbar:(BOOL)animated;
-(void)hideToolbar:(BOOL)animated;
-(void)updateToolbar;

-(IBAction)selectAll:(id)sender;
-(IBAction)selectNone:(id)sender;
-(IBAction)toggleSelection:(id)sender;

- (IBAction) deleteItems:(id )inSender;

@end
