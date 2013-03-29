//
//  PIXImageBrowserViewController.m
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXImageBrowserViewController.h"
#import "PIXAppDelegate.h"
#import "PIXAlbum.h"
#import "PIXDefines.h"
#import "PIXPageViewController.h"
#import "PIXNavigationController.h"

@interface PIXImageBrowserViewController ()

@end

@implementation PIXImageBrowserViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)awakeFromNib
{
    
    if (self.album!=nil)
    {
        [[[PIXAppDelegate sharedAppDelegate] window] setTitle:self.album.title];
    }
    
    if (self.browserView)
    {
        //[self.browserView setDraggingDestinationDelegate:self];
        
        NSColor * color = [NSColor colorWithPatternImage:[NSImage imageNamed:@"dark_bg"]];
        [[self.browserView enclosingScrollView] setBackgroundColor:color];
        //self.browserData = self.album.photos;
        
        [self.browserView setAllowsMultipleSelection:YES];
        [self.browserView reloadData];
    }
}

-(void)setAlbum:(id)album
{
    _album = album;
    if (album) {
        [[[PIXAppDelegate sharedAppDelegate] window] setTitle:[self.album title]];
        self.browserData = [[self.album sortedPhotos] mutableCopy];
        // deselect all items in the view
        [self.browserView setSelectionIndexes:nil byExtendingSelection:NO];
        
        self.browserData = nil;
        [self.browserView reloadData];
    }
}

-(NSMutableArray *)browserData
{
    if (_browserData == nil) {
        _browserData = [self.album.photos mutableCopy];
    }
    return _browserData;
}

-(void)showPageControllerForIndex:(NSUInteger)index
{
    PIXPageViewController *pageViewController = [[PIXPageViewController alloc] initWithNibName:@"PIXPageViewController" bundle:nil];
    pageViewController.album = self.album;
    pageViewController.initialSelectedObject = [self.album.sortedPhotos objectAtIndex:index];
    [self.navigationViewController pushViewController:pageViewController];
}

-(void)dealloc
{
    [[[PIXAppDelegate sharedAppDelegate] window] setTitle:@"Unbound"];
    self.browserView.delegate = nil;
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

    //NSArray *itemsToDelete = [self.browserData objectsAtIndexes:indexes];
    //[self deleteItems:itemsToDelete];
}

/* action called when the zoom slider did change */
- (IBAction)zoomSliderDidChange:(id)sender
{
	/* update the zoom value to scale images */
    [self.browserView setZoomValue:[sender floatValue]];
	
	/* redisplay */
    //[self.imageBrowserController.browserView setNeedsDisplay:YES];
}

// -------------------------------------------------------------------------------
//	imageBrowserSelectionDidChange:aBrowser
//
//	User chose a new image from the image browser.
// -------------------------------------------------------------------------------


- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser
{
    
}


// -------------------------------------------------------------------------------
//  imageBrowser:cellWasDoubleClickedAtIndex:index
// -------------------------------------------------------------------------------
- (void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index
{
    
    DLog(@"cellWasDoubleClickedAtIndex : %ld", index);
    [self showPageControllerForIndex:index];
    
    // deselect all items in the view
    [self.browserView setSelectionIndexes:nil byExtendingSelection:NO];
    
    self.browserData = nil;
    [self.browserView reloadData];
    
}




@end
