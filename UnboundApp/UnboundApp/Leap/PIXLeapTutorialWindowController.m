//
//  PIXLeapTutorialWindowController.m
//  UnboundApp
//
//  Created by Scott Sykora on 4/9/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <QTKit/QTKit.h>
#import "PIXLeapTutorialWindowController.h"
#import "PIXLeapInputManager.h"
#import "PIXHUDMessageController.h"
#import <AppKit/AppKit.h>

@interface PIXLeapTutorialWindowController () <PIXLeapResponder>

@property (weak) IBOutlet QTMovieView * movieView;
@property (weak) IBOutlet NSProgressIndicator * spinner;
@property int currentSlide;

@property (weak) IBOutlet NSButton * skipButton;
@property (weak) IBOutlet NSButton * nextButton;
@property (weak) IBOutlet NSButton * lastButton;

@property (weak) IBOutlet NSTextField * textField;
@property (weak) IBOutlet NSTextField * actionField;
@property (weak) IBOutlet NSTextField * titleField;

@property (weak) PIXHUDMessageController * hudMessage;

@property NSPoint windowStartPosition;

@end

@implementation PIXLeapTutorialWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [self.spinner startAnimation:nil];
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    [self configureSlide];
    
    [[PIXLeapInputManager sharedInstance] addResponder:self];
}

- (void)restartTutorial
{
    if(self.currentSlide != 0)
    {
        self.currentSlide = 0;
        [self configureSlide];
    }
    
    [[PIXLeapInputManager sharedInstance] addResponder:self];
}

-(void)configureSlide
{
    NSString * movieName = [NSString stringWithFormat:@"LeapTutorial%d.mov", self.currentSlide];
    
    NSError * movieLoadError = nil;
    QTMovie * introMovie = [QTMovie movieNamed:movieName error:&movieLoadError];
    [introMovie setAttribute:[NSNumber numberWithBool:YES] forKey:@"QTMovieLoopsAttribute"];
    
    [self.movieView setMovie:introMovie];
    
    [self.movieView play:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // stop the animation if it's still going
        [self.spinner stopAnimation:nil];
        
        // set the text feild
        
        switch (self.currentSlide) {
            case 0:
                self.titleField.stringValue = @"A Quick Tutorial";
                self.textField.stringValue = @"The Leap Motion Controller\rlets you browse your photos with simple hand motions.";
                self.actionField.stringValue = @"Swipe left or right to navigate.";
                
                
                [self.nextButton setTitle:@"Next"];
                [self.lastButton setHidden:YES];
                break;
                
            case 1:
                
                self.titleField.stringValue = @"Key Tap to Select";
                self.textField.stringValue = @"Point at an item you want to open. Make a quick Key Tap gesture to select.";
                self.actionField.stringValue = @"Try the Key Tap now.";
                
                [self.lastButton setHidden:NO];
                break;
                
            case 2:
                
                self.titleField.stringValue = @"Swipe Up to Go Back";
                self.textField.stringValue = @"Swipe Up with an open hand to go back from any screen.";
                self.actionField.stringValue = @"Try the Swipe Up now.";
                
                break;
                
            case 3:
                
                self.titleField.stringValue = @"Tap to Navigate";
                self.textField.stringValue = @"Move back and forth through photos by doing the Key Tap to the right or left of the screen.";
                self.actionField.stringValue = @"Try tapping forward and back now.";
                [self.nextButton setTitle:@"Next"];
                
                break;
                
            case 4:
                self.titleField.stringValue = @"Grab to Pan and Zoom";
                self.textField.stringValue = @"Grab with a closed fist to pan and zoom fullscreen photos.";
                self.actionField.stringValue = @"Try the Grab now. Swipe left to finish.";
                
                [self.nextButton setTitle:@"Done"];
                break;
                
            default:
                break;
        }
        
        [self.textField setNeedsLayout:YES];        
        
    });
    
}

- (IBAction)skipTutorial:(id)sender
{
    [self.window close];
}

- (IBAction)nextSlide:(id)sender
{
    if(self.currentSlide < 4)
    {
        // animate the transition
        CATransition *animation = [CATransition animation];
        [animation setDuration:0.5];
        
        [animation setType:kCATransitionPush];
        [animation setSubtype:kCATransitionFromRight];
        
        [self.movieView.layer addAnimation:animation forKey:@"slideShowFade"];

        
        self.currentSlide++;
        [self configureSlide];
    }
    
    else
    {
        [self.window close];
    }

}

- (IBAction)lastSlide:(id)sender
{
    if(self.currentSlide > 0)
    {
        // animate the transition
        CATransition *animation = [CATransition animation];
        [animation setDuration:0.5];
        
        [animation setType:kCATransitionPush];
        [animation setSubtype:kCATransitionFromLeft];
        
        [self.movieView.layer addAnimation:animation forKey:@"slideShowFade"];
        
        self.currentSlide--;
        [self configureSlide];
    }
    
    else
    {
        NSBeep();
    }
}

-(void)leapSwipeLeft
{
    if(![self.window isKeyWindow]) return;
    
    
    [self nextSlide:nil];
    
}

-(void)leapSwipeUp
{
    if(![self.window isKeyWindow]) return;
    
    if(self.currentSlide == 2)
    {
        
        if(!self.hudMessage)
        {
            // present the hud message that the leap connected
            PIXHUDMessageController * messageHUD = [PIXHUDMessageController windowWithTitle:@"You Swiped Up!" andIcon:[NSImage imageNamed:@"success"]];
            [messageHUD presentInParentWindow:self.window forTimeInterval:0.7];
            self.hudMessage = messageHUD;
        }
        
        else
        {
            [self.hudMessage rewakeForTimeInterval:0.7];
        }
        
        [(NSSound *)[NSSound soundNamed:@"Pop"] play];
        
        
        
    }
}

-(void)leapPointerSelect:(NSPoint)normalizedPosition
{
    if(![self.window isKeyWindow]) return;
    
    if(self.currentSlide == 1)
    {
        
        if(!self.hudMessage)
        {
            // present the hud message that the leap connected
            PIXHUDMessageController * messageHUD = [PIXHUDMessageController windowWithTitle:@"You Tapped!" andIcon:[NSImage imageNamed:@"success"]];
            [messageHUD presentInParentWindow:self.window forTimeInterval:0.7];
            self.hudMessage = messageHUD;
        }
        
        else
        {
            [self.hudMessage rewakeForTimeInterval:0.7];
        }
            
        [(NSSound *)[NSSound soundNamed:@"click"] play];
        
    }
    
    if(self.currentSlide == 3)
    {
        
        if(normalizedPosition.x > 0.5)
        {
            if(!self.hudMessage)
            {
                // present the hud message that the leap connected
                PIXHUDMessageController * messageHUD = [PIXHUDMessageController windowWithTitle:@"You Tapped Forward!" andIcon:[NSImage imageNamed:@"success-forward"]];
                [messageHUD presentInParentWindow:self.window forTimeInterval:0.7];
                self.hudMessage = messageHUD;
            }
            
            else
            {
                [self.hudMessage setTitle:@"You Tapped Forward!"];
                [self.hudMessage setIcon:[NSImage imageNamed:@"success-forward"]];
                [self.hudMessage rewakeForTimeInterval:0.7];
            }
        }
        
        else
        {
            if(!self.hudMessage)
            {
                // present the hud message that the leap connected
                PIXHUDMessageController * messageHUD = [PIXHUDMessageController windowWithTitle:@"You Tapped Back!" andIcon:[NSImage imageNamed:@"success-backward"]];
                [messageHUD presentInParentWindow:self.window forTimeInterval:0.7];
                self.hudMessage = messageHUD;
            }
            
            else
            {
                [self.hudMessage setTitle:@"You Tapped Back!"];
                [self.hudMessage setIcon:[NSImage imageNamed:@"success-backward"]];
                [self.hudMessage rewakeForTimeInterval:0.7];
            }
        }
        
        [(NSSound *)[NSSound soundNamed:@"click"] play];
        
    }
}


-(void)leapSwipeRight
{
    if(![self.window isKeyWindow]) return;
    
    [self lastSlide:self];
}

-(void)leapPanZoomStart
{
    if(![self.window isKeyWindow]) return;
    
    if(self.currentSlide == 4)
    {
        self.windowStartPosition = self.window.frame.origin;
        
        if(!self.hudMessage)
        {
            // present the hud message that the leap connected
            PIXHUDMessageController * messageHUD = [PIXHUDMessageController windowWithTitle:@"Grab Started! Now pan with your fist." andIcon:[NSImage imageNamed:@"success"]];
            [messageHUD presentInParentWindow:self.window forTimeInterval:1.5];
            self.hudMessage = messageHUD;
        }
        
        else
        {
            [self.hudMessage rewakeForTimeInterval:0.7];
        }
        
    }
}

-(void)leapPanZoomPosition:(NSPoint)position andScale:(CGFloat)scale
{
    if(![self.window isKeyWindow]) return;
    
    if(self.currentSlide == 4)
    {
        NSRect screenFrame = self.window.screen.frame;
        
        NSPoint newOrigin = self.windowStartPosition;
        newOrigin.x += position.x * screenFrame.size.width;
        newOrigin.y += position.y * screenFrame.size.height;;
        
        if(newOrigin.y < screenFrame.origin.y) newOrigin.y = screenFrame.origin.y;
        if(newOrigin.x < screenFrame.origin.x) newOrigin.x = screenFrame.origin.x;
        
        float maxx = screenFrame.size.width - self.window.frame.size.width + screenFrame.origin.x;
        
        if(newOrigin.x > maxx) newOrigin.x = maxx;
        
        [self.window setFrameOrigin:newOrigin];
        
        if(scale < 1.0)
        {
            
            //[self.movieView.layer setTransform:CATransform3DScale(CATransform3DIdentity, scale, scale, 1.0)];
        }
        
        
    }
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[PIXLeapInputManager sharedInstance] removeResponder:self];
}

@end
