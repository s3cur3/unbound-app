//
//  PIXHUDMessageController.m
//  UnboundApp
//
//  Created by Scott Sykora on 4/8/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXHUDMessageController.h"

@interface PIXHUDMessageController ()


@property IBOutlet NSTextField * titleFeild;
@property IBOutlet NSImageView * iconView;

@end


@implementation PIXHUDMessageView

-(BOOL)isOpaque
{
    return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    
    
    NSRect innerbounds = CGRectInset(self.bounds, 1.0, 1.0);
    NSBezierPath *selectionRectPath = [NSBezierPath bezierPathWithRoundedRect:innerbounds xRadius:15 yRadius:15];
    
    
    
    // fill the round rect
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.6] setFill];
    [selectionRectPath fill];

}


@end

@implementation PIXHUDMessageWindow

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag {
    // Using NSBorderlessWindowMask results in a window without a title bar.
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    if (self != nil) {
        // Start with no transparency for all drawing into the window
        [self setAlphaValue:0.0];
        
        // Turn off opacity so that the parts of the window that are not drawn into are transparent.
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setHasShadow:NO];
        
        
    }
    return self;
}

@end

@implementation PIXHUDMessageController

+(PIXHUDMessageController *)windowWithTitle:(NSString *)title andIcon:(NSImage *)icon
{
    PIXHUDMessageController * hudWindow = [[PIXHUDMessageController alloc] initWithWindowNibName:@"PIXHUDMessageController"];
    
    [hudWindow setTitle:title];
    [hudWindow setIcon:icon];
    
    
    return hudWindow;
}


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        
        

    }
    
    return self;
}

- (void)windowDidLoad
{
        
    [self.titleFeild setStringValue:self.title];
    [self.iconView setImage:self.icon];
    
    
    
    // Turn off opacity so that the parts of the window that are not drawn into are transparent.
    [self.window setOpaque:NO];
    [self.window setBackgroundColor:[NSColor clearColor]];
    [self.window setHasShadow:NO];
    
    
    
    [super windowDidLoad];

    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(void)presentInParentWindow:(NSWindow *)parentWindow forTimeInterval:(NSTimeInterval)timeInterval
{
    if(parentWindow)
    {        
        [parentWindow addChildWindow:self.window ordered:NSWindowAbove];
        [self.window orderFront:self];
        
        NSPoint centerOrigin = NSMakePoint((parentWindow.frame.size.width/2) - (self.window.frame.size.width/2),
                                           parentWindow.frame.size.height/2);
        
        centerOrigin.x += parentWindow.frame.origin.x;
        centerOrigin.y += parentWindow.frame.origin.y;
        
        // if the window is less than 500 px high then center the view vertically
        if(parentWindow.frame.size.height < 500)
        {
            centerOrigin.y += (self.window.frame.size.height/2);
        }
        
        [self.window setFrameTopLeftPoint:centerOrigin];
        
        [self.window setViewsNeedDisplay:YES];
    }
    
    [self.window setAlphaValue:1.0];
    
    double delayInSeconds = timeInterval;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        // fade the window for 1 second
        //[self.window.animator setDuration:1.0];
        [[NSAnimationContext currentContext] setDuration:1.5];
        [self.window.animator setAlphaValue:0.0];
        
        
        [self performSelector:@selector(close) withObject:nil afterDelay:1.5];
        
    });
}

-(void)rewakeForTimeInterval:(NSTimeInterval)timeInterval
{
    [[NSAnimationContext currentContext] setDuration:0.0];
    [self.window.animator setAlphaValue:1.0];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(close) object:nil];
    
    double delayInSeconds = timeInterval;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        // fade the window for 1 second
        //[self.window.animator setDuration:1.0];
        [[NSAnimationContext currentContext] setDuration:1.5];
        [self.window.animator setAlphaValue:0.0];
        
        [self performSelector:@selector(close) withObject:nil afterDelay:1.5];
        
        
    });
}

-(void)setIcon:(NSImage *)icon
{
    _icon = icon;
    [self.iconView setImage:_icon];
}

-(void)setTitle:(NSString *)title
{
    _title = title;    
    [self.titleFeild setStringValue:_title];
}

@end
