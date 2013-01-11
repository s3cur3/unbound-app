//
//  PIXAlbumWindowController.m
//  UnboundCoreDataUtility
//
//  Created by Bob on 1/7/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXAlbumWindowController.h"
#import "PIXAlbumViewController.h"
#import "PIXAppDelegate.h"

@interface PIXAlbumWindowController ()

@end

@implementation PIXAlbumWindowController

-(id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    if (self!=nil)
    {
        self.albumViewController = [[PIXAlbumViewController alloc] initWithNibName:@"PIXAlbumViewController" bundle:nil];
    }
    return self;
}


-(void)awakeFromNib
{
    
    
}


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        /*if (window) {
            [window.contentView addSubview:self.albumViewController.view];
            [self.albumViewController.view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        }*/
        
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    if (self.window) {
        [self.window setContentView:self.albumViewController.view];
        //[self.window.contentView addSubview:self.albumViewController.view];
        //[self.albumViewController.view setFrame:self.window.contentView bounds];
        //[self.albumViewController.view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    }

}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    //return [[self managedObjectContext] undoManager];
    return [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] undoManager];
}

@end
