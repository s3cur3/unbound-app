//
//  SquareImageView.m
//  Unbound
//
//  Created by Scott Sykora on 11/2/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "SquareImageView.h"

@implementation SquareImageView

- (void)drawRect:(NSRect)rect
{
    //[super drawRect:rect];
    NSRect cropRect = self.frame;
    [self.image drawAtPoint:NSZeroPoint
              fromRect:cropRect
             operation:NSCompositeCopy
              fraction:1];
}

@end
