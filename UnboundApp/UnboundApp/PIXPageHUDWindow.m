//
//  PIXPageHUDWindow.m
//  UnboundApp
//
//  Created by Scott Sykora on 3/17/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXPageHUDWindow.h"

@interface  PIXPageHUDWindow ()

@property (assign) NSPoint initialLocation;

@property (weak, nonatomic) NSView * parentView;


@end

@implementation PIXPageHUDWindow

/*
 In Interface Builder, the class for the window is set to this subclass. Overriding the initializer
 provides a mechanism for controlling how objects of this class are created.
 */
- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle
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
        [self setHasShadow:YES];
       
    }
    return self;
}


-(void)setParentView:(NSView *)view
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:_parentView];
    
    _parentView = view;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parentFrameChaged:) name:NSViewFrameDidChangeNotification object:_parentView];
    
    [self setPositionAnimated:NO];
    
}


-(void)parentFrameChaged:(NSNotificationCenter *)note
{
    [self setPositionAnimated:NO];

}

-(void)setPositionAnimated:(BOOL)animated
{
    CGRect viewFrame = [self.parentView.window convertRectToScreen:self.parentView.frame];
    
    CGRect newFrame = CGRectMake(viewFrame.origin.x + (viewFrame.size.width /2) - (self.frame.size.width/2),
                                 viewFrame.origin.y + 30,
                                 self.frame.size.width,
                                 self.frame.size.height);
    
    // Move the window to the new location
    if(animated)
    {
        [self setFrame:newFrame display:YES animate:YES];
    }
    
    else
    {
        [self setFrame:newFrame display:YES];
    }
    
}

-(void)showAnimated:(BOOL)animated
{
    if(animated)
    {
        [self.animator setAlphaValue:1.0];
    }
    
    else
    {
        [self setAlphaValue:1.0];
    }
}

-(void)setHasMouse:(BOOL)hasMouse
{
    _hasMouse = hasMouse;
    
    if(_hasMouse)
    {
        [self showAnimated:NO];
    }
}

-(void)hideAnimated:(BOOL)animated
{
    // dont hide if the mouse is over the view
    if(self.hasMouse) return;
    
    if(animated)
    {
        [self.animator setAlphaValue:0.0];
    }
    
    else
    {
        [self setAlphaValue:0.0];
    }
}









/*
 Custom windows that use the NSBorderlessWindowMask can't become key by default. Override this method
 so that controls in this window will be enabled.
 */
- (BOOL)canBecomeKeyWindow {
    return NO;
}

/*
 Start tracking a potential drag operation here when the user first clicks the mouse, to establish
 the initial location.
 */
- (void)mouseDown:(NSEvent *)theEvent {
    // Get the mouse location in window coordinates.
    self.initialLocation = [theEvent locationInWindow];
    self.hasMouse = YES;
}

/*
 Once the user starts dragging the mouse, move the window with it. The window has no title bar for
 the user to drag (so we have to implement dragging ourselves)
 */
- (void)mouseDragged:(NSEvent *)theEvent {
    NSRect screenVisibleFrame = [[NSScreen mainScreen] visibleFrame];
    NSRect windowFrame = [self frame];
    NSPoint newOrigin = windowFrame.origin;
    
    // Get the mouse location in window coordinates.
    NSPoint currentLocation = [theEvent locationInWindow];
    // Update the origin with the difference between the new mouse location and the old mouse location.
    newOrigin.x += (currentLocation.x - self.initialLocation.x);
    newOrigin.y += (currentLocation.y - self.initialLocation.y);
    
    // Don't let window get dragged up under the menu bar
    if ((newOrigin.y + windowFrame.size.height) > (screenVisibleFrame.origin.y + screenVisibleFrame.size.height)) {
        newOrigin.y = screenVisibleFrame.origin.y + (screenVisibleFrame.size.height - windowFrame.size.height);
    }
    
    // Move the window to the new location
    [self setFrameOrigin:newOrigin];
    
    self.hasMouse = YES;
}


- (void)mouseUp:(NSEvent *)theEvent {
    // Get the mouse location in window coordinates.
    [self setPositionAnimated:YES];
}


@end
