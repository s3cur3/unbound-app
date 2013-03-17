//
//  PIXSelectionLayer.m
//  UnboundApp
//
//  Created by Scott Sykora on 3/16/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXSelectionLayer.h"
#import "NSBezierPath+pathUtilities.h"

@implementation PIXSelectionLayer

-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setNeedsDisplay];
}

-(void)drawInContext:(CGContextRef)ctx
{
    NSRect innerbounds = CGRectInset(self.bounds, 6, 6);
    NSBezierPath *selectionRectPath = [NSBezierPath bezierPathWithRoundedRect:innerbounds xRadius:10 yRadius:10];
    
    CGContextAddPath(ctx, [selectionRectPath quartzPath]);
    CGContextSetStrokeColorWithColor(ctx, [NSColor colorWithCalibratedRed:0.189 green:0.657 blue:0.859 alpha:1.000].CGColor);
    CGContextSetLineWidth(ctx, 4.0);
    CGContextStrokePath(ctx);
}

@end
