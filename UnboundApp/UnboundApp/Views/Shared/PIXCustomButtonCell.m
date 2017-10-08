//
//  PIXGradientBarButtonCell.m
//  UnboundApp
//
//  Created by Scott Sykora on 2/12/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXCustomButtonCell.h"

@implementation PIXCustomButtonCell

- (id)init
{
    self = [super init];
    if (self) {
        [self setupDefaults];
    }
    return self;
}

/*
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDefaults];
    }
    return self;
}
*/
- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupDefaults];
    }
    return self;
}

-(void)setupDefaults
{
    self.upStateBGImage = [NSImage imageNamed:@"btn-roundrect-up"];
    self.downStateBGImage = [NSImage imageNamed:@"btn-roundrect-down"];
    self.capSize = 20;
    
    self.backgroundColor = [NSColor clearColor];
    self.font = [NSFont fontWithName:@"Helvetica" size:12];
    
    [self setBezeled:YES];
}

-(BOOL)isOpaque
{
    return NO;
}

/*
- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
    return frame;
}

- (void)drawImage:(NSImage *)image withFrame:(NSRect)frame inView:(NSView *)controlView
{
   
}*/

// for some reason this was drawing a background color above the bezel. I've overridden it, but maybe there is a better way
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [self drawTitle:self.attributedTitle withFrame:cellFrame inView:controlView];
    [self drawImage:self.image withFrame:cellFrame inView:controlView];
}

- (NSSize)cellSize
{
    NSSize smallSize = [super cellSize];
    
    smallSize.width += 20;
    smallSize.height = 25;
    
    return  smallSize;
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
    
    NSImage * bgImage = self.upStateBGImage;
    
    if([self isHighlighted])
    {
        bgImage = self.downStateBGImage;
    }
    
    CGRect leftRect;
    CGRect middleRect;
    CGRect rightRect;
    
    CGRectDivide(frame, &leftRect, &middleRect, self.capSize, CGRectMinXEdge);
    CGRectDivide(middleRect, &rightRect, &middleRect, self.capSize, CGRectMaxXEdge);
    
    CGSize imageSize = bgImage.size;

    [bgImage drawInRect:leftRect
             fromRect:CGRectMake(0, 0, self.capSize, imageSize.height)
            operation:NSCompositeSourceOver
             fraction:1 respectFlipped:YES hints:nil];
    
    [bgImage drawInRect:middleRect
                           fromRect:CGRectMake(self.capSize, 0, imageSize.width - (self.capSize*2), imageSize.height)
                          operation:NSCompositeSourceOver
                           fraction:1 respectFlipped:YES hints:nil];
    
    [bgImage drawInRect:rightRect
                           fromRect:CGRectMake(imageSize.width - self.capSize, 0, self.capSize, imageSize.height)
                          operation:NSCompositeSourceOver
                           fraction:1 respectFlipped:YES hints:nil];
}


@end
