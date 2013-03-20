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
    [[PIXFileParser sharedFileParser] stopObserving];
    
    NSURL * dropboxPhotosFolder = [[PIXFileParser sharedFileParser] defaultDBFolder];
    NSURL * dropboxCUFolder = [[PIXFileParser sharedFileParser] defaultDBCameraUploadsFolder];
    
    
    [[PIXFileParser sharedFileParser] setObservedURLs:@[dropboxPhotosFolder, dropboxCUFolder]];
    
    [[PIXFileParser sharedFileParser] scanFullDirectory];
    
    [[PIXFileParser sharedFileParser] startObserving];
    
    
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kAppFirstRun];
    
    [[PIXAppDelegate sharedAppDelegate] showMainWindow:nil];
    
    [self close];
}

- (IBAction)chooseFolder:(id)sender
{
    // Create the File Open Dialog class.
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    
    [openPanel setCanCreateDirectories:YES];
    [openPanel setDirectoryURL:self.pickerStartURL];
    
    [openPanel setDelegate:self];
    
    [openPanel runModal];
    
    if([[openPanel URLs] count] == 1)
    {
        [[PIXFileParser sharedFileParser] stopObserving];
        
        [[PIXFileParser sharedFileParser] setObservedURLs:[openPanel URLs]];
        
        [[PIXFileParser sharedFileParser] scanFullDirectory];
        
        [[PIXFileParser sharedFileParser] startObserving];
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kAppFirstRun];
        
        [[PIXAppDelegate sharedAppDelegate] showMainWindow:nil];
        [self close];
        
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
