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
#import "PIXDefines.h"

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
        //TODO: maybe show a loading/splash/progress window while data is loading?
        [[NSNotificationCenter defaultCenter] addObserverForName:kUB_PHOTOS_LOADED_FROM_FILESYSTEM object:self.dataSource queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kUB_PHOTOS_LOADED_FROM_FILESYSTEM object:self.dataSource];

            //start observing the file system
            [self.dataSource performSelector:@selector(startObserving) withObject:nil afterDelay:2.0];
            
        }];
        
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


- (NSError *)application:(NSApplication *)application willPresentError:(NSError *)error;
{
    DLog(@"willPresentError :  %@", error);
    return error;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender;
{
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification;
{
    [self.dataSource stopObserving];
}


@end
