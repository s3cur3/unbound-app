//
//  PIXGradientView.m
//  UnboundApp
//
//  Created by Scott Sykora on 2/7/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXGradientBarView.h"

@interface PIXGradientBarView () 

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarWidth;

@end

@implementation PIXGradientBarView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyWindowChanged) name:NSWindowDidResignMainNotification object:[self window]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyWindowChanged) name:NSWindowDidBecomeMainNotification object:[self window]];
    }
    
    return self;
}


-(void)setButtons:(NSArray *)buttonArray
{
    // remove all subviews
    NSArray * subviews = self.buttonHolder.subviews.copy;
    for(NSView * subview in subviews) {
        [subview removeFromSuperview];
    }

    for (NSButton *button in buttonArray) {
        [self.buttonHolder addView:button inGravity:NSStackViewGravityTrailing];
    }
}


-(void)keyWindowChanged
{
    [self setNeedsDisplay:YES];
}

-(BOOL)isOpaque
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    
    
    // Fill view with a top-down gradient
    // from startingColor to endingColor
    
    NSGradient* aGradient = nil;
    NSColor *edgeColor = nil;

    if ([[self window] isMainWindow]) {

        aGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.000]
                                                  endingColor:[NSColor colorWithCalibratedWhite:0.85 alpha:1.000]];

        edgeColor = [NSColor colorWithCalibratedWhite:0.6 alpha:1.000];

    }

    else
    {
        aGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.95 alpha:1.000]
                                                  endingColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.000]];

        edgeColor = [NSColor colorWithCalibratedWhite:0.9 alpha:1.000];
    }

    [aGradient drawInRect:[self bounds] angle:270];


    [edgeColor drawSwatchInRect:NSMakeRect(0, 0, self.bounds.size.width, 1)];
    
    
    
    //[NSBezierPath strokeLineFromPoint:NSMakePoint(0, 1) toPoint:NSMakePoint(self.bounds.size.width, 1)];
    
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end
