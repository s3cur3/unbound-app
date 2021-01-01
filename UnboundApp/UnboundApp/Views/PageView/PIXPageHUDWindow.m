//
//  PIXPageHUDWindow.m
//  UnboundApp
//
//  Created by Scott Sykora on 3/17/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXPageHUDWindow.h"
#import "PIXPageHUDView.h"
#import "PIXPhoto.h"

#import "PIXPageViewController.h"
//#import "PIXPageView.h"

@interface  PIXPageHUDWindow ()

@property (assign) NSPoint initialLocation;

@property (weak, nonatomic) NSView * parentView;
@property (weak) IBOutlet PIXPageViewController * pageViewController;
@property (weak) IBOutlet PIXPageHUDView * hudView;

@property NSUInteger position;


@end

@implementation PIXPageHUDWindow

/*
 In Interface Builder, the class for the window is set to this subclass. Overriding the initializer
 provides a mechanism for controlling how objects of this class are created.
 */
- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSWindowStyleMask)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag {
    // Using NSWindowStyleMaskBorderless results in a window without a title bar.
    self = [super initWithContentRect:contentRect styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    if (self != nil) {
        // Start with no transparency for all drawing into the window
        [self setAlphaValue:1.0];
        
        // Turn off opacity so that the parts of the window that are not drawn into are transparent.
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]]; 
        [self setHasShadow:YES];
        
        self.position = [[NSUserDefaults standardUserDefaults] integerForKey:@"PIXPageHudPosition"];
       
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

-(void)findClosestPosition
{
    CGRect viewFrame = [self.parentView.window convertRectToScreen:self.parentView.frame];
    
    
    NSPoint normalizedPosition = NSMakePoint((self.frame.origin.x-viewFrame.origin.x) / (viewFrame.size.width - self.frame.size.width),
                                             (self.frame.origin.y-viewFrame.origin.y) / (viewFrame.size.height - self.frame.size.height));
    
    // top postions
    if(normalizedPosition.y > 0.5)
    {
        self.hudView.captionIsBelow = YES;
        if(normalizedPosition.x < 0.2)
        {
            // top left
            self.position = 2;
        }
        
        else if(normalizedPosition.x > 0.8)
        {
            // top right
            self.position = 4;
        }
        
        else
        {
            // top center
            self.position = 3;
        }
    }
    
    // bottom positions
    else
    {
        self.hudView.captionIsBelow = NO;
        if(normalizedPosition.x < 0.2)
        {
            // bottom left
            self.position = 1;
        }
        
        else if(normalizedPosition.x > 0.8)
        {
            // bottom right
            self.position = 5;
        }
        
        else
        {
            // bottom center
            self.position = 0;
        }
    }

    
    [[NSUserDefaults standardUserDefaults] setInteger:self.position forKey:@"PIXPageHudPosition"];
    [self setPositionAnimated:YES];
    
    
}

-(void)setPositionAnimated:(BOOL)animated
{

    [self positionWindowWithSize:self.frame.size animated:animated];
    
}

-(void)positionWindowWithSize:(NSSize)size animated:(BOOL)animated
{
    CGRect viewFrame = [self.parentView.window convertRectToScreen:self.parentView.frame];
    CGRect selfFrame = self.frame;
    selfFrame.size = size;
    
    //selfFrame.size.height -= self.hudView.heightChange;
    
    CGRect newFrame = CGRectZero;
    
    switch (self.position) {
            
        case 1: // bottom left
            
            self.hudView.captionIsBelow = NO;
            newFrame = CGRectMake(viewFrame.origin.x + 30,
                                  viewFrame.origin.y + 30,
                                  selfFrame.size.width,
                                  selfFrame.size.height);
            
            break;
            
        case 2: // top left
            
            self.hudView.captionIsBelow = YES;
            newFrame = CGRectMake(viewFrame.origin.x + 30,
                                  viewFrame.origin.y + viewFrame.size.height - 30 - selfFrame.size.height,
                                  selfFrame.size.width,
                                  selfFrame.size.height);
            
            break;
            
        case 3: // top center
            
            self.hudView.captionIsBelow = YES;
            newFrame = CGRectMake(viewFrame.origin.x + (viewFrame.size.width /2) - (selfFrame.size.width/2),
                                  viewFrame.origin.y + viewFrame.size.height - 30 - selfFrame.size.height,
                                  selfFrame.size.width,
                                  selfFrame.size.height);
            
            break;
            
        case 4: // top right
            
            self.hudView.captionIsBelow = YES;
            newFrame = CGRectMake(viewFrame.origin.x + viewFrame.size.width - 30 - selfFrame.size.width,
                                  viewFrame.origin.y + viewFrame.size.height - 30 - selfFrame.size.height,
                                  selfFrame.size.width,
                                  selfFrame.size.height);
            
            break;
            
        case 5: // bottom right
            
            self.hudView.captionIsBelow = NO;
            newFrame = CGRectMake(viewFrame.origin.x + viewFrame.size.width - 30 - selfFrame.size.width,
                                  viewFrame.origin.y + 30,
                                  selfFrame.size.width,
                                  selfFrame.size.height);
            
            break;
            
        default: // bottom center
            
            self.hudView.captionIsBelow = NO;
            newFrame = CGRectMake(viewFrame.origin.x + (viewFrame.size.width /2) - (selfFrame.size.width/2),
                                  viewFrame.origin.y + 30,
                                  selfFrame.size.width,
                                  selfFrame.size.height);
            
            break;
    }
    
    
    
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
        //If we've got a viewController, let it decide if window should be visible
        //This is important mainly for not covering controls when a video is playing
        if (self.pageViewController) {
            [self.pageViewController unfadeControls];
        } else {
            [self showAnimated:NO];
        }
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
 Custom windows that use the NSWindowStyleMaskBorderless can't become key by default. Override this method
 so that controls in this window will be enabled.
 */
- (BOOL)canBecomeKeyWindow {
    
    return YES;
    
    //return self.hudView.isTextEditing;
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


// pass keystrokes up to the containing view
-(void)keyDown:(NSEvent *)theEvent
{
    [self.parentView keyDown:theEvent];
}

/*
 Once the user starts dragging the mouse, move the window with it. The window has no title bar for
 the user to drag (so we have to implement dragging ourselves)
 */
- (void)mouseDragged:(NSEvent *)theEvent {
    
    // if the initial point is zero predend this is a mousedown event
    if(self.initialLocation.x == 0 && self.initialLocation.y == 0)
    {
        self.initialLocation = [theEvent locationInWindow];
        self.hasMouse = YES;
        return;
    }
    
    //NSRect screenVisibleFrame = [[NSScreen mainScreen] visibleFrame];
    NSRect windowFrame = [self frame];
    NSPoint newOrigin = windowFrame.origin;
    
    // Get the mouse location in window coordinates.
    NSPoint currentLocation = [theEvent locationInWindow];
    // Update the origin with the difference between the new mouse location and the old mouse location.
    newOrigin.x += (currentLocation.x - self.initialLocation.x);
    newOrigin.y += (currentLocation.y - self.initialLocation.y);
    
    /*
    // Don't let window get dragged up under the menu bar
    if ((newOrigin.y + windowFrame.size.height) > (screenVisibleFrame.origin.y + screenVisibleFrame.size.height)) {
        newOrigin.y = screenVisibleFrame.origin.y + (screenVisibleFrame.size.height - windowFrame.size.height);
    }
    */
    
    // Move the window to the new location
    [self setFrameOrigin:newOrigin];
    
    self.hasMouse = YES;
}


- (void)mouseUp:(NSEvent *)theEvent {
    NSLog(@"PIXPageHUDView.m: mouseUp");
    // animate to the closest snap position
    [self findClosestPosition];
    
    self.initialLocation = NSZeroPoint;
    self.hasMouse = NO;
}

-(void)resignKeyWindow
{
    [self.hudView textDidEndEditing:nil];
}


@end
