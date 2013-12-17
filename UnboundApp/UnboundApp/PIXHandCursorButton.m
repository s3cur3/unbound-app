//
//  PIXHandCursorButton.m
//  UnboundApp
//
//  Created by Scott Sykora on 12/12/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXHandCursorButton.h"

@interface PIXHandCursorButton()
{
}

@end

@implementation PIXHandCursorButton


- (void)resetCursorRects
{
    [super resetCursorRects];
    [self addCursorRect:[self bounds] cursor:[NSCursor pointingHandCursor]];

}

@end
