//
//  PIXPhotoGridViewItem.m
//  UnboundApp
//
//  Created by Scott Sykora on 1/30/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXPhotoGridViewItem.h"

@implementation PIXPhotoGridViewItem

-(BOOL)isOpaque
{
    return YES;
}

- (void)drawRect:(NSRect)rect
{
    
    NSBezierPath *contentRectPath = [NSBezierPath bezierPathWithRect:rect];
    [[NSColor colorWithCalibratedWhite:0.912 alpha:1.000] setFill];
    [contentRectPath fill];
    
    /// draw selection ring
    if (self.selected) {
        
        NSRect innerbounds = CGRectInset(self.bounds, 6, 6);
        NSBezierPath *selectionRectPath = [NSBezierPath bezierPathWithRoundedRect:innerbounds xRadius:10 yRadius:10];
        [[NSColor colorWithCalibratedRed:0.189 green:0.657 blue:0.859 alpha:1.000] setStroke];
        [selectionRectPath setLineWidth:4];
        [selectionRectPath stroke];
    }
    
    
    
    
    CGRect albumFrame = CGRectInset(self.bounds, 15, 15);

    // draw the  image
    CGRect photoFrame = [self drawBorderedPhoto:self.itemImage inRect:albumFrame];
    self.contentFrame = photoFrame;
    
}

@end
