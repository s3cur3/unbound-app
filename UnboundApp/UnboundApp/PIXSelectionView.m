//
//  PIXSelectionView.m
//  UnboundApp
//
//  Created by Scott Sykora on 3/16/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXSelectionView.h"

@implementation PIXSelectionView

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
    NSRect innerbounds = CGRectInset(self.bounds, 6, 6);
    NSBezierPath *selectionRectPath = [NSBezierPath bezierPathWithRoundedRect:innerbounds xRadius:10 yRadius:10];
    [[NSColor colorWithCalibratedRed:0.189 green:0.657 blue:0.859 alpha:1.000] setStroke];
    [selectionRectPath setLineWidth:4];
    [selectionRectPath stroke];
}

@end
