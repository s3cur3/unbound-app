//
//  PIXPageControlView.m
//  UnboundApp
//
//  Created by Scott Sykora on 3/17/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXPageHUDView.h"
#import "PIXPageHUDWindow.h"

@interface PIXPageHUDView ()

@property (strong) NSTrackingArea * boundsTrackingArea;

@end

@implementation PIXPageHUDView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)mouseEntered:(NSEvent *)theEvent
{
    [(PIXPageHUDWindow *)[self window] setHasMouse:YES];
}


-(void)mouseExited:(NSEvent *)theEvent
{
    [(PIXPageHUDWindow *)[self window] setHasMouse:NO];
}

-(void)updateTrackingAreas
{
    
    if(self.boundsTrackingArea != nil) {
        [self removeTrackingArea:self.boundsTrackingArea];
    }
    
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways);
    self.boundsTrackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
                                                            options:opts
                                                              owner:self
                                                           userInfo:nil];
    [self addTrackingArea:self.boundsTrackingArea];
}


- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    
    
    NSRect innerbounds = CGRectInset(self.bounds, 6.5, 6.5);
    NSBezierPath *selectionRectPath = [NSBezierPath bezierPathWithRoundedRect:innerbounds xRadius:10 yRadius:10];
    
    
    // draw a shadow under the round rect
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetShadowWithColor(context, CGSizeMake(0, -1), 6.0, [[NSColor colorWithGenericGamma22White:0.0 alpha:.6] CGColor]);
    
    // fill the round rect
    [[NSColor colorWithCalibratedWhite:0.0 alpha:.5] setFill];
    [selectionRectPath fill];
    
    // turn off the shadow
    CGContextSetShadowWithColor(context, CGSizeZero, 0, NULL);
    
    // stroke the outside
    [[NSColor colorWithCalibratedWhite:1.0 alpha:.4] setStroke];
    [selectionRectPath stroke];
    
    
}

@end
