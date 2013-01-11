//
//  PIIXPhotoStreamWindowController.h
//  UnboundMacOS
//
//  Created by Robert Edmonston on 12/31/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface PIXPhotoStreamWindowController : NSWindowController

@property (nonatomic, readwrite, strong) NSNumber * zoomValue;
@property (nonatomic, readwrite, strong) NSMutableArray * browserData;
@property (weak) IBOutlet IKImageBrowserView *browserView;
@property (weak) IBOutlet NSButton *refreshButton;
@property (weak) IBOutlet NSSlider *zoomSlider;

- (IBAction)refreshAction:(id)sender;

@end
