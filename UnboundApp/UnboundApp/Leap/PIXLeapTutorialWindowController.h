//
//  PIXLeapTutorialWindowController.h
//  UnboundApp
//
//  Created by Scott Sykora on 4/9/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PIXLeapTutorialWindowController : NSWindowController

- (void)restartTutorial;

- (IBAction)skipTutorial:(id)sender;
- (IBAction)nextSlide:(id)sender;
- (IBAction)lastSlide:(id)sender;

@end
