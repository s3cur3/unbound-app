//
//  PIXProgressWindowController.h
//  UnboundApp
//
//  Created by Scott Sykora on 5/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PIXProgressWindowController : NSWindowController

@property (nonatomic) NSString * messageText;
@property (nonatomic) float progress;

@property IBOutlet NSProgressIndicator * progressBar;





@end
