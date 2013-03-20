//
//  PIXRoundRectView.m
//  UnboundApp
//
//  Created by Scott Sykora on 3/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXRoundRectView.h"

@implementation PIXRoundRectView

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
    NSBezierPath * path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:5 yRadius:5];
    
    [[NSColor colorWithCalibratedWhite:0.85 alpha:0.8] setFill];
    
    [path fill];
    
    
}

@end
