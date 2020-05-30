//
//  PIXCollectionViewController.h
//  UnboundApp
//
//  Created by Ditriol Wei on 29/7/16.
//  Copyright © 2016 Pixite Apps LLC. All rights reserved.
//

#import "PIXViewController.h"
#import "PIXRoundedProgressIndicator.h"

@class PIXCollectionToolbar;
@class PIXCollectionView;

@interface PIXCollectionViewController : PIXViewController

@property (strong) IBOutlet PIXCollectionView *collectionView;

@property (strong) NSString * selectedItemsName;

@property (strong) IBOutlet PIXCollectionToolbar * toolbar;
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

- (IBAction)importPhotosButtonPressed:(id)sender;
- (IBAction)chooseFolderButtonPressed:(id)sender;

@end
