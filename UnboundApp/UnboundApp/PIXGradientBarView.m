//
//  PIXGradientView.m
//  UnboundApp
//
//  Created by Scott Sykora on 2/7/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXGradientBarView.h"

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
    for(NSView * subview in [self.buttonHolder subviews])
    {
        [subview removeFromSuperview];
    }
    
    
    NSMutableDictionary * views = [NSMutableDictionary new];
    NSMutableString * horizontalConstraints = [@"|-6-" mutableCopy];
    
    
    int i = 0;
    for(NSButton * button in buttonArray)
    {
        [self.buttonHolder addSubview:button];
        
        NSString * buttonName = [NSString stringWithFormat:@"button%d", i];
        [views setObject:button forKey:buttonName];
        
        [horizontalConstraints appendString:[NSString stringWithFormat:@"[%@]-6-", buttonName]];
        
        //[button setAutoresizingMask:NSViewWidthSizable];
        
        i++;
    }
    
    //NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[_buttonHolder]-0-[_contentView]-0-[_buttonHolder]" options:0 metrics:nil views:viewsDictionary];
    
    [horizontalConstraints appendString:@"|"];
    
    //[self.buttonHolder removeConstraints:[self.buttonHolder constraints]];
    [self.buttonHolder addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:horizontalConstraints
                                                                 options:NSLayoutFormatAlignAllCenterY
                                                                 metrics:nil
                                                                   views:views]];
    
    [self layoutSubtreeIfNeeded];
    /*[self.buttonHolder addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[button]-55-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];*/

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
    
    if ([[self window] isMainWindow]) {
        
        aGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.000]
                                                  endingColor:[NSColor colorWithCalibratedWhite:0.80 alpha:1.000]];
    }
    
    else
    {
        aGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.956 alpha:1.000]
                                                  endingColor:[NSColor colorWithCalibratedWhite:0.821 alpha:1.000]];
    }
    
    [aGradient drawInRect:[self bounds] angle:270];
    
    
    [[NSColor colorWithCalibratedWhite:0.3 alpha:1.000] drawSwatchInRect:NSMakeRect(0, 0, self.bounds.size.width, 1)];
    
    
    
    //[NSBezierPath strokeLineFromPoint:NSMakePoint(0, 1) toPoint:NSMakePoint(self.bounds.size.width, 1)];
    
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end
