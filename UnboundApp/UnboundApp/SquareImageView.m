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
    NSRect cropRect = self.bounds;
    
    
    /*
    [self.image drawAtPoint:NSZeroPoint
              fromRect:cropRect
             operation:NSCompositeCopy
              fraction:1];*/
    
    CGSize imageSize = [self.image size];
    NSRect imageRect = self.bounds;
    
    if(imageSize.width > imageSize.height)
    {
        imageRect.size.width = imageSize.height;
        imageRect.size.height = imageSize.height;
        imageRect.origin.x = (imageSize.width - imageSize.height) /2;
    }
    
    else
    {
        imageRect.size.width = imageSize.width;
        imageRect.size.height = imageSize.width;
        imageRect.origin.y = (imageSize.height - imageSize.width) /2;
    }
    
    
    [self.image drawInRect:cropRect fromRect:imageRect operation:NSCompositeCopy fraction:1.0];
    
}

@end
