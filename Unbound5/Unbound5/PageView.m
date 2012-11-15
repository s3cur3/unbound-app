//
//  PageView.m
//  Unbound
//
//  Created by Scott Sykora on 11/14/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PageView.h"

@implementation PageView

-(void)drawRect:(NSRect)dirtyRect
{
    [[NSColor blackColor] setFill];
    NSRectFill(dirtyRect);
}

@end
