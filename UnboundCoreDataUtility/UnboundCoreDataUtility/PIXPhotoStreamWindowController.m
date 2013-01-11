//
//  PIIXPhotoStreamWindowController.m
//  UnboundMacOS
//
//  Created by Robert Edmonston on 12/31/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXPhotoStreamWindowController.h"
#import "PIXAppDelegate+CoreDataUtils.h"
#import "PIXAppDelegate.h"

extern NSString *kCreateThumbDidFinish;

@interface PIXPhotoStreamWindowController ()

@end

@implementation PIXPhotoStreamWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        self.zoomValue = [NSNumber numberWithFloat:0.4f];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refreshNotification:)
                                                     name:kCreateThumbDidFinish
                                                   object:nil];
        
        self.browserData = [[(PIXAppDelegate *)[[NSApplication sharedApplication] delegate] fetchAllPhotos] mutableCopy];
        
        

    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self.browserView reloadData];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark Browser Data Source Methods

- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *) aBrowser
{
	return [self.browserData count];
}

- (id) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index
{
	return [self.browserData objectAtIndex:index];
}

/* implement some optional methods of the image-browser's datasource protocol to be able to remove and reoder items */

/*	remove
 The user wants to delete images, so remove these entries from our datasource.
 */
- (void)imageBrowser:(IKImageBrowserView *)view removeItemsAtIndexes:(NSIndexSet *)indexes
{

	
}

-(void)refreshNotification:(NSNotification *)note
{
    [self.browserView reloadData];
}

- (IBAction)refreshAction:(id)sender;
{
    [self.browserView reloadData];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
