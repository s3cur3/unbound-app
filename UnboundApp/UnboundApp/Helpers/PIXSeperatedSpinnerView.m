//
//  PIXSeperatedSpinnerView.m
//  UnboundApp
//
//  Created by Scott Sykora on 6/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXSeperatedSpinnerView.h"
#import "PIXAppDelegate.h"
#import "Unbound-Swift.h"

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
                                                         styleMask:NSWindowStyleMaskBorderless
                                                           backing:NSBackingStoreBuffered
                                                             defer:NO];
        
        [self.spinnerwindow setOpaque:NO];
        [self.spinnerwindow setBackgroundColor:[NSColor clearColor]];
        
        [self.mainWindow addChildWindow:self.spinnerwindow ordered:NSWindowAbove];
        
        [self.spinnerwindow setAlphaValue:0.0];
        
        
        NSView *progressIndicatorHolder = [[NSView alloc] initWithFrame:frame];
        
         self.indicator = [[NSProgressIndicator alloc] initWithFrame:CGRectMake(0, 1, 18, 18)];
         [self.indicator setStyle:NSProgressIndicatorStyleSpinning];
         [self.indicator setIndeterminate:YES];
         
         [self.indicator setControlSize:NSControlSizeSmall];
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parentFrameChaged:) name:NSWindowDidEnterFullScreenNotification object:self.window];
        
        

        
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
    
    if([self.mainWindow styleMask] & NSWindowStyleMaskFullScreen)
    {
        newRect.origin.y = self.mainWindow.frame.size.height - newRect.origin.y;
    }
    
    //newRect.origin.x += self.mainWindow.frame.origin.x;
    //newRect.origin.y += self.mainWindow.frame.origin.y;

    if (self.spinnerwindow != nil) {
        [self.spinnerwindow setFrame:newRect display:YES];
        [self.spinnerwindow setAlphaValue:1.0];
    }
    
    //DLog(@"New Spinner Position: %f, %f", newRect.origin.x, newRect.origin.y);
}

-(void)windowWillClose:(NSNotificationCenter *)note
{
    [self.spinnerwindow close];
}



-(void)removeFromSuperview
{
    [super removeFromSuperview];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self.mainWindow.contentView];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidEnterFullScreenNotification object:self.window];
    
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
