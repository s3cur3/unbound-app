//
//  MainViewController.h
//  Unbound4
//
//  Created by Bob on 10/1/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//@class PageViewController;
@class IKBController;

@interface MainViewController : NSViewController <NSOutlineViewDataSource>
{
    NSMutableArray *_tableContents;
    
}

@property (nonatomic, assign) IBOutlet IKBController *imageBrowserController;
@property (nonatomic, assign) IBOutlet NSTableView *tableView;

- (IBAction)zoomSliderDidChange:(id)sender;
- (IBAction)addImageButtonClicked:(id)sender;
@property (weak) IBOutlet NSTextField *pathLabel;
@property (weak) IBOutlet NSButton *choosePathButton;

//-(void)switchToPageView;

//-(void)unhideSubviews;

@end
