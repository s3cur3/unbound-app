//
//  PIXSidebarClipView.m
//  UnboundApp
//
//  Created by Scott Sykora on 2/24/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXSidebarClipView.h"
#import <Quartz/Quartz.h>

@implementation PIXSidebarClipView

/*
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}*/

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    self.layer = [CAScrollLayer layer];
    self.wantsLayer = YES;
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;
    
    return self;
}

/*
- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}*/

@end
