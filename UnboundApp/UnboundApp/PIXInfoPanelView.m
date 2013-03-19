//
//  PIXInfoPanelView.m
//  UnboundApp
//
//  Created by Scott Sykora on 3/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXInfoPanelView.h"

@implementation PIXInfoPanelView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    
    // draw the textured background
    NSBezierPath *contentRectPath = [NSBezierPath bezierPathWithRect:dirtyRect];
    NSColor * color = [NSColor colorWithPatternImage:[NSImage imageNamed:@"dark_bg"]];
    [color setFill];
    [contentRectPath fill];
    
    
    // Save the graphics state for shadow
    [NSGraphicsContext saveGraphicsState];
    
    // Set the shown path as the clip
    [contentRectPath setClip];
    
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context setCompositingOperation:NSCompositePlusDarker];
    
    
    [[NSColor whiteColor] setStroke];
    
    
    // Create and stroke the shadow
    NSShadow * shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:.5]];
    [shadow setShadowBlurRadius:12.0];
    [shadow setShadowOffset:NSMakeSize(1, 0)];
    [shadow set];
    
    
    [contentRectPath stroke];
    
    
    // Restore the graphics state
    [NSGraphicsContext restoreGraphicsState];
    
}

@end
