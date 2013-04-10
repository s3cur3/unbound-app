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

@interface PIXLeapTutorialWindowController () <PIXLeapResponder>

@property (weak) IBOutlet QTMovieView * movieView;
@property (weak) IBOutlet NSProgressIndicator * spinner;
@property int currentSlide;

@property (weak) IBOutlet NSButton * skipButton;
@property (weak) IBOutlet NSButton * nextButton;
@property (weak) IBOutlet NSButton * lastButton;

@property (weak) IBOutlet NSTextField * textField;

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
                self.textField.stringValue = @"The Leap Controller lets you browse\ryour photos with simple hand motions.\r\rSwipe left or click 'next' to learn more.";
                
                
                [self.lastButton setHidden:YES];
                break;
                
            case 1:
                self.textField.stringValue = @"Point at an item you want to open.\rTap into the screen or make a small circle to select.";
                
                [self.lastButton setHidden:NO];
                break;
                
            case 2:
                self.textField.stringValue = @"Swipe upwards with an open hand to go 'back' from any screen.";
                [self.nextButton setTitle:@"Next"];
                break;
                
            case 3:
                self.textField.stringValue = @"Swipe right and left to navigate photos.\r'Grab' to pan and zoom.";
                
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
    if(self.currentSlide < 3)
    {
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
        self.currentSlide--;
        [self configureSlide];
    }
}

-(void)leapSwipeLeft
{
    // animate the transition    
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.5];
    
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFromRight];
    
    [self.movieView.layer addAnimation:animation forKey:@"slideShowFade"];
    
    [self nextSlide:nil];

}

-(void)leapSwipeRight
{
    // animate the transition
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.5];
    
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFromLeft];
    
    [self.movieView.layer addAnimation:animation forKey:@"slideShowFade"];
    
    [self lastSlide:nil];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[PIXLeapInputManager sharedInstance] removeResponder:self];
}

@end
