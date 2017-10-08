//
//  PIXCustomButton.m
//  UnboundApp
//
//  Created by Scott Sykora on 2/14/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXCustomButton.h"
#import "PIXCustomButtonCell.h"

@implementation PIXCustomButton

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        //[[self class] setCellClass:[PIXCustomButtonCell class]];
        [self setButtonType:NSTexturedRoundedBezelStyle];
    }
    
    return self;
}

+(Class)cellClass
{
    return [PIXCustomButtonCell class];
}


- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    [super drawRect:dirtyRect];
}

@end
