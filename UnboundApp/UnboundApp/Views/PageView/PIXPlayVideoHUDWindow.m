//
//  PIXPlayVideoHUDWindow.m
//  UnboundApp
//
//  Created by Bob on 7/18/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXPlayVideoHUDWindow.h"

@interface PIXPlayVideoHUDWindow()

@property (weak, nonatomic) NSView * parentView;

@end

@implementation PIXPlayVideoHUDWindow

/*
 In Interface Builder, the class for the window is set to this subclass. Overriding the initializer
 provides a mechanism for controlling how objects of this class are created.
 */
- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSWindowStyleMask)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag {
    // Using NSBorderlessWindowMask results in a window without a title bar.
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    if (self != nil) {
        // Start with no transparency for all drawing into the window
        [self setAlphaValue:1.0];
        
        // Turn off opacity so that the parts of the window that are not drawn into are transparent.
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setHasShadow:NO];
        [self setReleasedWhenClosed:NO];
        
    }
    return self;
}

-(void)setParentView:(NSView *)view
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:_parentView];
    
    _parentView = view;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parentFrameChaged:) name:NSViewFrameDidChangeNotification object:_parentView];
    
    //[self setPositionAnimated:NO];
    [self positionWindowWithSize:self.frame.size animated:NO];
    
}


-(void)parentFrameChaged:(NSNotificationCenter *)note
{
    DLog(@"%@", note);
    //[self setPositionAnimated:NO];
    [self positionWindowWithSize:self.frame.size animated:NO];
}

-(void)positionWindowWithSize:(NSSize)size animated:(BOOL)animated
{
    NSView *videoPlayerView = [self.parentView.subviews objectAtIndex:0];
    DLog(@"videoPlayerView : %@", videoPlayerView);
    
    CGRect viewFrame = videoPlayerView.bounds;
    
    viewFrame = [self.parentView.window convertRectToScreen:viewFrame];
    CGRect selfFrame = self.frame;
    selfFrame.size = size;
    
    //selfFrame.size.height -= self.hudView.heightChange;
    
    CGRect newFrame = CGRectZero;
    
    newFrame = CGRectMake(viewFrame.origin.x + (viewFrame.size.width /2) - (selfFrame.size.width/2),
                          viewFrame.origin.y + (viewFrame.size.height /2) - (selfFrame.size.height/2) - 33,
                          selfFrame.size.width,
                          selfFrame.size.height);
    
    
    // Move the window to the new location
    if(animated)
    {
        [self setFrame:newFrame display:YES animate:YES];
    }
    
    else
    {
        [self setFrame:newFrame display:YES animate:NO];
    }
}


@end
