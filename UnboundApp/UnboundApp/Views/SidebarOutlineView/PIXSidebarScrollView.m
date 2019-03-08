//
//  PIXSidebarScrollView.m
//  UnboundApp
//
//  Created by Scott Sykora on 2/24/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXSidebarScrollView.h"
#import "PIXSidebarClipView.h"

@implementation PIXSidebarScrollView

/*
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
    // Drawing code here.
}

*/
- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self == nil) return nil;
    
    [self swapClipView];
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    if (![self.contentView isKindOfClass:PIXSidebarClipView.class] ) {
        [self swapClipView];
    }

    self.wantsLayer = YES;
}

- (void)updateLayer {
    self.layer.backgroundColor = NSColor.windowBackgroundColor.CGColor;
}

- (void)swapClipView {
    
    /*
    id documentView = self.documentView;
    PIXSidebarClipView *clipView = [[PIXSidebarClipView alloc] initWithFrame:self.contentView.frame];
    self.contentView = clipView;
    self.documentView = documentView;
    */
}

@end
