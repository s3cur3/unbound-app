//
//  PIXCollectionViewController.h
//  UnboundApp
//
//  Created by Ditriol Wei on 29/7/16.
//  Copyright © 2016 Pixite Apps LLC. All rights reserved.
//

#import "PIXViewController.h"
#import "PIXGridView.h"
#import "PIXGradientBarView.h"
#import "PIXRoundedProgressIndicator.h"

@interface PIXCollectionViewController : PIXViewController

@property (strong) IBOutlet PIXGridView *gridView;

@property (strong) NSMutableArray *items;
@property (strong) IBOutlet NSArrayController * arrayController;

@property (nonatomic,strong) NSMutableSet * selectedItems;
@property (strong) NSString * selectedItemsName;

@property (strong) IBOutlet PIXGradientBarView * toolbar;
@property (strong) IBOutlet NSTextField * toolbarTitle;
@property (strong) IBOutlet PIXRoundedProgressIndicator * gridViewProgress;
@property (strong) IBOutlet NSTextField * gridViewTitle;
@property (strong) IBOutlet NSScrollView * scrollView;
@property (strong) IBOutlet NSView * layerBackedView;

@property (strong) IBOutlet NSView * centerStatusView;
@property (strong) IBOutlet NSTextField * centerStatusViewTextField;
@property (strong) IBOutlet NSTextField * centerStatusViewSubTextField;

@property (strong) IBOutlet NSProgressIndicator * progressIndicator;

- (NSMenu *)menuForObject:(id)object;

- (void)showToolbar:(BOOL)animated;
- (void)hideToolbar:(BOOL)animated;
- (void)updateToolbar;

- (IBAction)selectAll:(id)sender;
- (IBAction)selectNone:(id)sender;
- (IBAction)toggleSelection:(id)sender;
- (IBAction)deleteItems:(id )inSender;

- (IBAction)importPhotosButtonPressed:(id)sender;
- (IBAction)chooseFolderButtonPressed:(id)sender;

@end
