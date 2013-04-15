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

-(IBAction)fileNameAction:(id)sender;


@end
