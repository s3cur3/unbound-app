//
//  PIXInfoPanelViewController.h
//  UnboundApp
//
//  Created by Scott Sykora on 3/21/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PIXPhoto;
@class PIXPageViewController;

@interface PIXInfoPanelViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, strong) PIXPhoto * photo;
@property (weak) IBOutlet PIXPageViewController * pageView;
@property (weak) IBOutlet NSButton * moreExifButton;
@property (weak) IBOutlet NSView * exifHolder;

@property (weak) IBOutlet NSScrollView * exifScrollView;
@property (weak) IBOutlet NSTableView * exifTableView;

-(IBAction)fileNameAction:(id)sender;

-(IBAction)moreExifAction:(id)sender;


@end
