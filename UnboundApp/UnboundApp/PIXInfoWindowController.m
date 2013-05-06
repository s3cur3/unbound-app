//
//  PIXInfoWindowController.m
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXInfoWindowController.h"
#import "PIXDefines.h"

#import "PIXAppDelegate.h"
#import "PIXFileParser.h"

#import "PIXLeapTutorialWindowController.h"
#import "PIXLeapInputManager.h"

@interface PIXInfoWindowController () <NSOpenSavePanelDelegate>

@property IBOutlet NSButton * dbFolderButton;
@property IBOutlet NSButton * anotherFolderButton;

@property (strong) NSURL * pickerStartURL;

@end

@implementation PIXInfoWindowController

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
    [super windowDidLoad];
    
    // check to see if the dropbox folder exits
    NSURL * dropboxPhotosFolder = [[PIXFileParser sharedFileParser] defaultDBFolder];
    
    NSNumber * isDirectory;
    [dropboxPhotosFolder getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
    
    // if there is no dropbox photos folder then remove that option
    if(![isDirectory boolValue])
    {
        [self.dbFolderButton setHidden:YES];
        [self.anotherFolderButton setTitle:@"Choose a Folder"];
        self.pickerStartURL = [NSURL fileURLWithPath:@"~/"];
    }
    
    else
    {
        self.pickerStartURL = [NSURL fileURLWithPath:@"~/Dropbox/"];
    }
}

- (IBAction)useDBDefaults:(id)sender
{
    // use this flag so the deep scan will restart if the app crashes half way through
    [[PIXFileParser sharedFileParser] userChoseDropboxPhotosFolder];
    
    [self close];
}

- (IBAction)chooseFolder:(id)sender
{
    if([[PIXFileParser sharedFileParser] userChooseFolderDialog])
    {
        [[PIXAppDelegate sharedAppDelegate] showMainWindow:nil];
        [self close];
    }
}

-(void)close
{
    [super close];
    
    if([[PIXLeapInputManager sharedInstance] isConnected] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"LeapTutorialHasShown"])
    {
            
            PIXLeapTutorialWindowController * tutorial = [[PIXLeapTutorialWindowController alloc] initWithWindowNibName:@"PIXLeapTutorialWindowController"];
            [tutorial showWindow:self];
            
            // only show this tutorial once. It's also accessible from the preferences window
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"LeapTutorialHasShown"];
    }
}

/*
- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError
{
    NSNumber * isDirectory;
    [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
    
    return [isDirectory boolValue];
}*/

@end
