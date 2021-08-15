//
//  PIXRoundedProgressIndicator.m
//  UnboundApp
//
//  Created by Scott Sykora on 4/7/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXRoundedProgressIndicator.h"

@implementation PIXRoundedProgressIndicator

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)setProgress:(double)newValue
{
    _progress = newValue;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    
    NSColor * drawColor = [NSColor colorWithCalibratedWhite:0.488 alpha:0.800];
    
    NSRect innerbounds = CGRectInset(self.bounds, 3, 4);
    NSBezierPath *outerPath = [NSBezierPath bezierPathWithRoundedRect:innerbounds xRadius:6 yRadius:6];
    [drawColor setStroke];
    [outerPath setLineWidth:2];
    [outerPath stroke];
    
    NSRect progressBounds = CGRectInset(innerbounds, 3, 3);
    
    progressBounds.size.width = self.progress * progressBounds.size.width;
    
    NSBezierPath *progressPath = [NSBezierPath bezierPathWithRoundedRect:progressBounds xRadius:3 yRadius:3];
    
    [drawColor setFill];
    [progressPath fill];
    
}

@end
