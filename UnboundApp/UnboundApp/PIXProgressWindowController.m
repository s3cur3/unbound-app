//
//  PIXProgressWindowController.m
//  UnboundApp
//
//  Created by Scott Sykora on 5/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXProgressWindowController.h"

@interface PIXProgressWindowController ()

@property IBOutlet NSTextField * message;


@end

@implementation PIXProgressWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.progressBar.doubleValue = self.progress * 100;
    self.message.stringValue = self.messageText;
    
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(void)setProgress:(float)progress
{
    _progress = progress;
    self.progressBar.doubleValue = self.progress * 100;
}

-(void)setMessageText:(NSString *)messageText
{
    _messageText = messageText;
    self.message.stringValue = self.messageText;
}




@end
