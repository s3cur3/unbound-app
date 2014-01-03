//
//  PIXMainWindowController.m
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXMainWindowController.h"
#import "PIXNavigationController.h"
#import "PIXAlbumGridViewController.h"
#import "PIXDefines.h"
#import "PIXAppDelegate.h"


@interface PIXMainWindowController ()

@property (weak) IBOutlet NSView * trialExpireView;
@property (weak) IBOutlet NSTextField * trialExpireText;
@property int trialSecondsLeft;

@end

@implementation PIXMainWindowController

-(id)initWithWindowNibName:(NSString *)nibName
{
    self = [super initWithWindowNibName:nibName];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

//- (void)windowDidLoad
//{
//    [super windowDidLoad];
//    
//    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
//    self.albumViewController = [[PIXAlbumViewController alloc] initWithNibName:@"PIXAlbumViewController" bundle:nil];
//    [self.navigationViewController pushViewController:self.albumViewController];
//}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    //        [self openAlert:@"Root Folder Unavailable"
    //            withMessage:@"The folder specified for your photos is unavailable. Would you like to change the root folder in your preferences?"];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kAppObservedDirectoryUnavailable] &&
        ![[NSUserDefaults standardUserDefaults] boolForKey:kAppObservedDirectoryUnavailableSupressAlert] &&
        ![[NSUserDefaults standardUserDefaults] boolForKey:kAppFirstRun])
    {
        __weak id weakDelegate = [PIXAppDelegate sharedAppDelegate];
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [(PIXAppDelegate *)weakDelegate openAlert:kRootFolderUnavailableTitle
                    withMessage:kRootFolderUnavailableDetailMessage];
        });
        
    }
    
    [self.navigationViewController.view setWantsLayer:YES];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    self.albumViewController = [[PIXAlbumGridViewController alloc] initWithNibName:@"PIXGridViewController" bundle:nil];
    
    [self.albumViewController view];

    [self.navigationViewController pushViewController:self.albumViewController];
    
#ifdef TRIAL_MODE
    
    NSDate * today = [NSDate date];
    
    // set the target date to June 30
    NSDate * targetDate = [NSDate dateWithString:@"2013-12-15 00:00:00 -0000"];
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:kTrialExpirationDate] == nil)
    {
        // this will only be run the first launch
        // 10 days from now:
        NSDate * tenDaysFromNow = [NSDate dateWithTimeIntervalSinceNow:60*60*24*11];
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithDouble:[tenDaysFromNow timeIntervalSince1970]] forKey:kTrialExpirationDate];
    }
    
    
    double trialInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:kTrialExpirationDate];
    
    NSDate * installTargetDate = [NSDate dateWithTimeIntervalSince1970:trialInterval];
    
    // rewrite this so it stays the same (in case it was in the initial values level of defaults)
    [[NSUserDefaults standardUserDefaults] setDouble:trialInterval forKey:kTrialExpirationDate];
    
    // in case they installed near the end of the beta period, always give at least 10 days;
    if([installTargetDate compare:targetDate] == NSOrderedDescending)
    {
        targetDate = installTargetDate;
    }
    
    // find the difference in days
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents * difference = [calendar components:NSDayCalendarUnit
                                               fromDate:today toDate:targetDate options:0];
    
    // add the text view to the title bar
    self.trialExpireText.stringValue = [NSString stringWithFormat:@"Unbound Trial expires in %ld days", (long)difference.day];
    
    NSView *frameView = [[self.window contentView] superview];
    NSRect frame = [frameView frame];
    
    NSRect otherFrame = [self.trialExpireView frame];
    otherFrame.origin.x = NSMaxX( frame ) - NSWidth( otherFrame )-25;
    otherFrame.origin.y = NSMaxY( frame ) - NSHeight( otherFrame )-4;
    [self.trialExpireView setFrame: otherFrame];
    
    [frameView addSubview: self.trialExpireView];
    
    [self.trialExpireView setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    
    [self.window invalidateCursorRectsForView:self.trialExpireView];
    
    
    // present an alert and quit the app if this as expired (with a 5 minute gracec period
    if (![[today laterDate:targetDate] isEqualToDate:targetDate])
    {
        self.trialExpireText.stringValue = @"This Trial has expired. 10:00 remaining";

        if(NSRunAlertPanel(@"This trial has expired.", @"This app will run for 10 minutes before quiting.", @"Learn More", @"OK", nil))
        {
            NSURL * url = [NSURL URLWithString:@"http://www.unboundformac.com"];
            [[NSWorkspace sharedWorkspace] openURL:url];
        }
        
        
        self.trialSecondsLeft = 10 * 60; // 10 minute grace period
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(advanceTrialExpiredTimer:) userInfo:nil repeats:YES];
        
        double delayInSeconds = (double)self.trialSecondsLeft;
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            if(NSRunAlertPanel(@"This trial has expired.", @"Please download a new version.", @"Learn More", @"OK", nil))
            {
                NSURL * url = [NSURL URLWithString:@"http://www.unboundformac.com"];
                [[NSWorkspace sharedWorkspace] openURL:url];
            }
            
            [[NSApplication sharedApplication] terminate:self];
            
        });        
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullscreenEntered:) name:NSWindowDidEnterFullScreenNotification object:self.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullscreenExited:) name:NSWindowDidExitFullScreenNotification object:self.window];
    
    

    
#endif
    
    
}

-(void)fullscreenEntered:(id)sender
{
    [self.trialExpireView setHidden:YES];
}

-(void)fullscreenExited:(id)sender
{
    [self.trialExpireView setHidden:NO];
}

- (void)advanceTrialExpiredTimer:(NSTimer *)timer
{
    self.trialSecondsLeft--;
    
    if(self.trialSecondsLeft >= 0)
    {
        self.trialExpireText.stringValue = [NSString stringWithFormat:@"This Trial has expired. %d:%02d remaining",
                                            self.trialSecondsLeft/60,
                                            self.trialSecondsLeft % 60];
    }
    
    else
    {
        self.trialExpireText.stringValue = @"This Trial has expired.";
    }
}

-(IBAction)trailButtonPressed:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"http://www.unboundformac.com"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (void)keyDown:(NSEvent *)theEvent {
    
    //intercept cmd-w
    
    if(([theEvent modifierFlags] & NSCommandKeyMask) && [[theEvent characters] isEqualToString:@"w"])
    {
        [self close];
        return;
    }
    
    [super keyDown:theEvent];
}




//- (void)windowDidLoad
//{
//    [super windowDidLoad];
//    
//    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
//    self.albumViewController = [[PIXBCAlbumViewController alloc] initWithNibName:@"PIXBCAlbumViewController" bundle:nil];
//    [self.navigationViewController pushViewController:self.albumViewController];
//}

@end
