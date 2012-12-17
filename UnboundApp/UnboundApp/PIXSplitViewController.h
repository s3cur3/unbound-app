//
//  PIXSplitViewController.h
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXViewController.h"

@class Album;

@interface PIXSplitViewController : PIXViewController

@property (nonatomic,weak) IBOutlet NSSplitView *splitView;
@property (nonatomic,weak) IBOutlet NSView *leftPane;
@property (nonatomic,weak) IBOutlet NSView *rightPane;

@property (nonatomic, strong) Album* selectedAlbum;

@end
