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
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath * path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:4 yRadius:4];
    [[NSColor colorWithCalibratedWhite:0.15 alpha:0.8] setFill];
    [path fill];
}

@end
