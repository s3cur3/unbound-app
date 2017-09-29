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
    
    self.pickerStartURL = [NSURL fileURLWithPath:@"~/"];
}

- (IBAction)chooseFolder:(id)sender
{
    if([[PIXFileParser sharedFileParser] userChooseFolderDialog])
    {
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
