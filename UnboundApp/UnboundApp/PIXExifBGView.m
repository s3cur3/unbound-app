//
//  PIXMiniExifView.m
//  UnboundApp
//
//  Created by Scott Sykora on 2/25/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXExifBGView.h"

@implementation PIXExifBGView

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
    
    // inset the rect by half a pixel so the 1px stroke at the end lines up with the pixels correctly
    NSRect greenRect = NSInsetRect([self bounds], 0.5, 0.5);
    
    
    // Create and fill the shown path
    NSBezierPath * path = [NSBezierPath bezierPathWithRoundedRect:greenRect xRadius:3 yRadius:3];
    
    
    NSGradient * gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.883 green:0.890 blue:0.807 alpha:1.000]
                                                          endingColor:[NSColor colorWithCalibratedRed:0.734 green:0.766 blue:0.608 alpha:1.000]];
    [gradient drawInBezierPath:path angle:90];
    
    // Save the graphics state for shadow
    [NSGraphicsContext saveGraphicsState];
    
    // Set the shown path as the clip
    [path setClip];

    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context setCompositingOperation:NSCompositePlusDarker];
    
    
    [[NSColor whiteColor] setStroke];
    
    // Create and stroke the shadow
    NSShadow * shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:.7]];
    [shadow setShadowBlurRadius:4.0];
    [shadow setShadowOffset:NSMakeSize(0, -1)];
    [shadow set];
    
    
    [path stroke];
    
    // Restore the graphics state
    [NSGraphicsContext restoreGraphicsState];
    
    // Add a nice stroke for a border
    [path setLineWidth:1.0];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:.5] setStroke];
    [path stroke];
    
}

@end
