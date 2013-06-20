//
//  PIXSeperatedSpinnerView.m
//  UnboundApp
//
//  Created by Scott Sykora on 6/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXSeperatedSpinnerView.h"
#import "PIXAppDelegate.h"
#import "PIXMainWindowController.h"

@interface PIXSeperatedSpinnerView()

@property (strong) NSWindow * spinnerwindow;
@property (weak) NSWindow * mainWindow;

@end

@implementation PIXSeperatedSpinnerView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        // create a window where the actuall spinner will be:
        
        self.mainWindow = [[[PIXAppDelegate sharedAppDelegate] mainWindowController] window];
        
        self.spinnerwindow  = [[NSWindow alloc] initWithContentRect:frame
                                                         styleMask:NSBorderlessWindowMask
                                                           backing:NSBackingStoreBuffered
                                                             defer:NO];
        
        [self.spinnerwindow setOpaque:NO];
        [self.spinnerwindow setBackgroundColor:[NSColor clearColor]];
        
        [self.mainWindow addChildWindow:self.spinnerwindow ordered:NSWindowAbove];
        
        [self.spinnerwindow setAlphaValue:0.0];
        
        
        NSView *progressIndicatorHolder = [[NSView alloc] initWithFrame:frame];
        
         self.indicator = [[NSProgressIndicator alloc] initWithFrame:CGRectMake(0, 1, 18, 18)];
         [self.indicator setStyle:NSProgressIndicatorSpinningStyle];
         [self.indicator setIndeterminate:YES];
         
         [self.indicator setControlSize:NSSmallControlSize];
         [self.indicator sizeToFit];
         
         [self.indicator setDisplayedWhenStopped:NO];
         
         [self.indicator setUsesThreadedAnimation:YES];
        
        [progressIndicatorHolder addSubview:self.indicator];
         
        [self.spinnerwindow setContentView:progressIndicatorHolder];
        
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:self.mainWindow];
        
        
    }
    return self;
}

-(void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    
    if(self.superview)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parentFrameChaged:) name:NSViewFrameDidChangeNotification object:self.mainWindow.contentView];
        
        

        
        //self.indicator.frame = self.bounds;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self parentFrameChaged:nil];
        });
        
        
        
    }
}


-(void)parentFrameChaged:(NSNotificationCenter *)note
{
    //NSScreen * currentScreen = self.mainWindow.screen;
    NSRect newRect = [self convertRect:self.bounds toView:nil];
    newRect = [self.mainWindow convertRectToScreen:newRect];
    
    
    //newRect.origin.x += self.mainWindow.frame.origin.x;
    //newRect.origin.y += self.mainWindow.frame.origin.y;
    
    [self.spinnerwindow setFrame:newRect display:YES];
    [self.spinnerwindow setAlphaValue:1.0];
}

-(void)windowWillClose:(NSNotificationCenter *)note
{
    [self.spinnerwindow close];
}



-(void)removeFromSuperview
{
    [super removeFromSuperview];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self.mainWindow.contentView];
    [self.spinnerwindow setAlphaValue:0.0];
}

/*
-(void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath *contentRectPath = [NSBezierPath bezierPathWithRect:dirtyRect];
    [[NSColor redColor] setFill];
    [contentRectPath fill];
}*/

@end
