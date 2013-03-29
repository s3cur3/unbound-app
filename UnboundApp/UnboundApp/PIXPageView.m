//
//  PIXPageView.m
//  UnboundApp
//
//  Created by Bob on 12/16/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXPageView.h"
#import "PIXPageViewController.h"

@interface PIXPageView ()

@property (strong) NSTrackingArea * boundsTrackingArea;

@end

@implementation PIXPageView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
}

-(void)drawRect:(NSRect)dirtyRect
{
    [[NSColor blackColor] setFill];
    NSRectFill(dirtyRect);
}

-(void)rightMouseDown:(NSEvent *)theEvent {
    DLog(@"rightMouseDown:%@", theEvent);
    [self.viewController rightMouseDown:theEvent];
    //    NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Options"];
    //    [theMenu insertItemWithTitle:@"Set As Desktop Background" action:@selector(setDesktopImage:) keyEquivalent:@""atIndex:0];
    //    [NSMenu popUpContextMenu:theMenu withEvent:theEvent forView:self.imageView];
}

-(void)updateTrackingAreas
{
    
    if(self.boundsTrackingArea != nil) {
        [self removeTrackingArea:self.boundsTrackingArea];
    }
    
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingMouseMoved);
    self.boundsTrackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
                                                 options:opts
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:self.boundsTrackingArea];
}



-(void)mouseEntered:(NSEvent *)theEvent
{
    [self.viewController mouseEntered:theEvent];
}

-(void)mouseMoved:(NSEvent *)theEvent
{
    [self.viewController mouseMoved:theEvent];
}

-(void)mouseExited:(NSEvent *)theEvent
{
    [self.viewController mouseExited:theEvent];
}

-(void)mouseDown:(NSEvent *)theEvent
{
    // grab the first responder on mouse down
    [self.window makeFirstResponder:self.viewController];
    [super mouseDown:theEvent];
}


@end
