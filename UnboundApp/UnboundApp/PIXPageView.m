//
//  PIXPageView.m
//  UnboundApp
//
//  Created by Bob on 12/16/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXPageView.h"
#import "PIXPageViewController.h"

@implementation PIXPageView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)drawRect:(NSRect)dirtyRect
{
    [[NSColor blackColor] setFill];
    NSRectFill(dirtyRect);
}

-(void)cancelOperation:(id)sender
{
    [self.viewController cancelOperation:sender];
}

-(void)mouseDown:(NSEvent *)theEvent
{
    [self.window mouseDown:theEvent];
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    [self.window mouseDragged:theEvent];
}



@end
