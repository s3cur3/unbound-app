//
//  PIXAppDelegate.m
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXAppDelegate.h"
#import "PIXInfoWindowController.h"
#import "PIXMainWindowController.h"
#import "Preferences.h"
#import "PIXFileSystemDataSource.h"

#pragma mark CONSTANTS

NSString* kAppFirstRun = @"appFirstRun";


//----------------------------------------------------------------------------------------------------------------------


#pragma mark

@implementation PIXAppDelegate

+(PIXAppDelegate *) sharedAppDelegate;
{
    return (PIXAppDelegate *)[[NSApplication sharedApplication] delegate];
}

+(void)presentError:(NSError *)error
{
#ifdef DEBUG
    DLog(@"%@", error);
    NSLog(@"%@",[NSThread callStackSymbols]);
#endif
    if([[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        [[NSApplication sharedApplication] presentError:error];
    } else {
        [[NSApplication sharedApplication] performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    Preferences * preferences = [Preferences instance];
    assert(preferences);
    self.dataSource = [PIXFileSystemDataSource sharedInstance]; //[[PIXFileSystemDataSource alloc] init];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kAppFirstRun]==YES)
    {
        [self showIntroWindow:self];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kAppFirstRun];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [self.dataSource loadAllAlbums];
        [self showMainWindow:self];
    }
}

// -------------------------------------------------------------------------------
//	showIntroWindow:sender
// -------------------------------------------------------------------------------
- (IBAction)showIntroWindow:(id)sender
{
    if (showIntroWindow == nil)
        showIntroWindow = [[PIXInfoWindowController alloc] initWithWindowNibName:@"PIXInfoWindowController"];
    [showIntroWindow showWindow:self];
}

// -------------------------------------------------------------------------------
//	showMainWindow:sender
// -------------------------------------------------------------------------------
- (IBAction)showMainWindow:(id)sender
{
    if (mainWindowController == nil) {
        mainWindowController = [[PIXMainWindowController alloc] initWithWindowNibName:@"PIXMainWindow"];
        //mainWindowController = (PIXMainWindowController *)[self.window windowController];
    }
    [mainWindowController showWindow:self];
}

@end
