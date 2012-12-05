//
//  SidebarViewController.h
//  Unbound
//
//  Created by Bob on 11/8/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIViewController.h"
@class MainWindowController;
@class Album;
@class SplitViewController;

@interface SidebarViewController : PIViewController <NSOutlineViewDataSource,
                                                    NSOutlineViewDelegate,
                                                    NSTextFieldDelegate>

@property (nonatomic, assign) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, assign) IBOutlet MainWindowController *mainWindow;
@property (nonatomic, assign) SplitViewController *splitViewController;

@property (nonatomic, strong) NSMutableArray *directoryArray;
@property (nonatomic, strong) Album *selectedAlbum;
@property (nonatomic, strong) Album *dragDropDestination;

@end
