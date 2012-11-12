//
//  ImageBrowserViewController.m
//  Unbound
//
//  Created by Bob on 11/7/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "ImageBrowserViewController.h"
#import "PageViewController.h"
#import "PINavigationViewController.h"

@interface ImageBrowserViewController ()

@end

@implementation ImageBrowserViewController

- (id)initWithCoder:(NSCoder *)aDecoder;
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil album:(Album *)anAlbum
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        if (anAlbum!=nil)
        {
            self.album = anAlbum;
        }
    }
    
    return self;
}

-(void)awakeFromNib
{
    if (self.browserView)
    {
        [self.browserView setDraggingDestinationDelegate:self];
        
        NSColor * color = [NSColor colorWithPatternImage:[NSImage imageNamed:@"dark_bg"]];
        [[self.browserView enclosingScrollView] setBackgroundColor:color];
        self.browserData = self.album.photos;
        [self.browserView reloadData];
    }
}


-(void)setAlbum:(Album *)album
{
    _album = album;
    if (self.browserView)
    {
        self.browserData = self.album.photos;
        [self.browserView reloadData];
    }
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
	[self.browserData removeObjectsAtIndexes:indexes];
    [self.browserView reloadData];
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
    
    NSLog(@"imageBrowserSelectionDidChange");
}

// -------------------------------------------------------------------------------
//  imageBrowser:cellWasDoubleClickedAtIndex:index
// -------------------------------------------------------------------------------
- (void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index
{
    
    NSLog(@"cellWasDoubleClickedAtIndex");
    PageViewController *pageViewController = [[PageViewController alloc] initWithNibName:@"PageViewController" bundle:nil];
    pageViewController.album = self.album;
    pageViewController.initialSelectedItem = [self.album.photos objectAtIndex:index];
    [self.navigationViewController pushViewController:pageViewController];
}

//
#pragma mark Browser Drag and Drop Methods

-(BOOL) optionKeyIsPressed
{
    if(( [NSEvent modifierFlags] & NSAlternateKeyMask ) != 0 ) {
        return YES;
    } else {
        return NO;
    }
    
}
- (unsigned int)draggingEntered:(id <NSDraggingInfo>)sender
{
    
	if([sender draggingSource] != self){
		NSPasteboard *pb = [sender draggingPasteboard];
		NSString * type = [pb availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]];
		
		if(type != nil){
            if ([self optionKeyIsPressed])
            {
                return NSDragOperationMove;
            } else {
                return NSDragOperationCopy;
            }
		}
	}
	return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	if([sender draggingSource] != self){
        if ([self optionKeyIsPressed])
        {
            return NSDragOperationMove;
        } else {
            return NSDragOperationCopy;
        }
	}
	return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    //[self.browserView setAnimates:YES];
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSFileManager * fileManager = [NSFileManager defaultManager];
	//Get the files from the drop
	NSArray * files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	
	/*for(id file in files){
     NSImage * image = [[NSWorkspace sharedWorkspace] iconForFile:file];
     NSString * imageID = [file lastPathComponent];
     DLog(@"File dragged abd dropped onto browser : %@", imageID);
     //IKBBrowserItem * item = [[IKBBrowserItem alloc] initWithImage:image imageID:imageID];
     //[self.browserData addObject:item];
     
     
     }*/
    
    // handle copied files
    NSError *anError = nil;
    for (NSString * url in files)
    {
        // check if the destination folder is different from the source folder
        if ([self.album.filePath isEqualToString:[  url stringByDeletingLastPathComponent]])
            continue;
        
        NSURL * destinationURL = [NSURL fileURLWithPath:self.album.filePath];
        
        NSURL *srcURL = [NSURL fileURLWithPath:url];
        destinationURL = [destinationURL URLByAppendingPathComponent:[url lastPathComponent]];
        
        //if ([sender draggingSourceOperationMask]!=NSDragOperationCopy)
        if ([self optionKeyIsPressed])
        {
            [fileManager moveItemAtURL:srcURL toURL:destinationURL error:&anError];
        } else {
            [fileManager copyItemAtURL:srcURL toURL:destinationURL error:&anError];
        }
        
    }
    if (anError!=nil)
    {
        DLog(@"error copying dragged files : %@", anError);
    }
	
	if([self.browserData count] > 0) {
        [self.album updatePhotosFromFileSystem];
        self.browserData = self.album.photos;
        [self.browserView reloadData];
        return YES;
    }
	
	return NO;
}

- (void)concludeDragOperation:(id < NSDraggingInfo >)sender
{
    //[self.browserView setAnimates:NO];
	//[self.browserView reloadData];
}

@end
