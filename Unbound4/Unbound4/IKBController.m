//
//  IKBController.m
//  IKBrowserViewDND
//
//  Created by David Gohara on 2/26/08.
//  Copyright 2008 SmackFu-Master. All rights reserved.
//  http://smackfumaster.com
//

#import "IKBController.h"
#import "IKBBrowserItem.h"
#import "AppDelegate.h"
#import "MainViewController.h"
#import "MainWindowController.h"
#import <Quartz/Quartz.h>

@implementation IKBController
@synthesize browserData;

- (void)awakeFromNib
{
	//Allocate some space for the data source
    browserData = [[AppDelegate applicationDelegate] imagesArray];
    if (!browserData) {
        browserData = [[NSMutableArray alloc] initWithCapacity:10];
    }
	
	//Browser UI setup (can also be set in IB)
    [_browserView setCellsStyleMask:IKCellsStyleTitled | IKCellsStyleShadowed | IKCellsStyleSubtitled | IKCellsStyleOutlined];
	[_browserView setDelegate:self];
	[_browserView setDataSource:self];
    [_browserView setAllowsReordering:YES];
    [_browserView setAnimates:YES];
    [_browserView setZoomValue:0.498598];
    [_browserView reloadData];
    [_browserView setNeedsDisplay:YES];
	//[browserView setDraggingDestinationDelegate:self];

}

-(void)updateBrowserView;
{
    if (_browserView) {
        [_browserView reloadData];
        [_browserView setNeedsDisplay:YES];
    }
}

#pragma mark -
#pragma mark Browser Data Source Methods

- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *) aBrowser
{	
	return [browserData count];
}

- (id) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index
{
	return [browserData objectAtIndex:index];
}

/* implement some optional methods of the image-browser's datasource protocol to be able to remove and reoder items */

/*	remove
 The user wants to delete images, so remove these entries from our datasource.
 */
- (void)imageBrowser:(IKImageBrowserView *)view removeItemsAtIndexes:(NSIndexSet *)indexes
{
	[browserData removeObjectsAtIndexes:indexes];
    [_browserView reloadData];
}

// reordering:
// The user wants to reorder images, update our datasource and the browser will reflect our changes
- (BOOL)imageBrowser:(IKImageBrowserView *)view moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)destinationIndex
{
    NSUInteger index;
    NSMutableArray *temporaryArray;
    
    temporaryArray = [[NSMutableArray alloc] init];
    
    /* first remove items from the datasource and keep them in a temporary array */
    for (index = [indexes lastIndex]; index != NSNotFound; index = [indexes indexLessThanIndex:index])
    {
        if (index < destinationIndex)
            destinationIndex --;
        
        id obj = [browserData objectAtIndex:index];
        [temporaryArray addObject:obj];
        [browserData removeObjectAtIndex:index];
    }
    
    /* then insert removed items at the good location */
    NSInteger n = [temporaryArray count];
    for (index=0; index < n; index++)
    {
        [browserData insertObject:[temporaryArray objectAtIndex:index] atIndex:destinationIndex];
    }
	[_browserView reloadData];
    return YES;
}

#pragma mark - 
#pragma mark Browser Drag and Drop Methods
- (unsigned int)draggingEntered:(id <NSDraggingInfo>)sender
{
	
	if([sender draggingSource] != self){
		NSPasteboard *pb = [sender draggingPasteboard];
		NSString * type = [pb availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]];
		
		if(type != nil){
			return NSDragOperationEvery;
		}
	}
	return NSDragOperationNone;
}

- (unsigned int)draggingUpdated:(id <NSDraggingInfo>)sender
{
	return NSDragOperationEvery;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	//Get the files from the drop
	NSArray * files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	
	for(id file in files){
		NSImage * image = [[NSWorkspace sharedWorkspace] iconForFile:file];
		NSString * imageID = [file lastPathComponent];
		
		IKBBrowserItem * item = [[IKBBrowserItem alloc] init];//[[IKBBrowserItem alloc] initWithImage:image imageID:imageID];
        item.image = image;
        item.url = [NSURL fileURLWithPath:file];
		[browserData addObject:item];
	}
	
	if([browserData count] > 0) return YES;
	
	return NO;
}

- (void)concludeDragOperation:(id < NSDraggingInfo >)sender
{
	[_browserView reloadData];
}


// -------------------------------------------------------------------------------
//	imageBrowserSelectionDidChange:aBrowser
//
//	User chose a new image from the image browser.
// -------------------------------------------------------------------------------
- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser
{
	/*NSIndexSet *selectionIndexes = [aBrowser selectionIndexes];
     
     if ([selectionIndexes count] > 0)
     {
     NSDictionary *screenOptions = [[NSWorkspace sharedWorkspace] desktopImageOptionsForScreen:curScreen];
     
     MyImageObject *anItem = [images objectAtIndex:[selectionIndexes firstIndex]];
     NSURL *url = [anItem imageRepresentation];
     
     NSNumber *isDirectoryFlag = nil;
     if ([url getResourceValue:&isDirectoryFlag forKey:NSURLIsDirectoryKey error:nil] && ![isDirectoryFlag boolValue])
     {
     /*NSError *error = nil;
     [[NSWorkspace sharedWorkspace] setDesktopImageURL:url
     forScreen:curScreen
     options:screenOptions
     error:&error];
     if (error)
     {
     [NSApp presentError:error];
     }* /
     
     //IKImageEditPanel *editor = [IKImageEditPanel sharedImageEditPanel];
     IKImageView *anImageView = [[IKImageView alloc] init];
     [anImageView setImageWithURL: url];
     //[editor setDataSource: anImageView];
     //[anImageView makeKeyAndOrderFront: nil];
     
     }
     }*/
    
    NSLog(@"imageBrowserSelectionDidChange");
}

// -------------------------------------------------------------------------------
//  imageBrowser:cellWasDoubleClickedAtIndex:index
// -------------------------------------------------------------------------------
- (void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index
{
    //[_imageBrowser setHidden:YES];
    /*MyImageObject *anItem = (MyImageObject *)[_images objectAtIndex:index];
    //NSURL *dirURL = [NSURL fileURLWithPath:@"/Users/inzan/Dropbox/Camera Uploads"];
    //NSURL *url = [NSURL fileURLWithPath:[anItem imageRepresentation]];
    //[_imageView setHidden:NO];
    //NSData *data = UIImageJPEGRepresentation(anItem.image, 1.0);
    NSImage *anImage = anItem.image;
    //CIImage * image = [CIImage imageWithContentsOfURL: anItem.url];
    NSImageView *anImageView = [[NSImageView alloc] initWithFrame:CGRectMake(0,0,400,400)];
    [anImageView setImage:anImage];
    //CGImageRef imageRef = anImage.CGImage;
    //[_imageView setImageWithURL:url];
    
    [anImageView setNeedsDisplay:YES];
    [aBrowser addSubview:anImageView];
    [aBrowser setNeedsDisplay:YES];*/
    
    [[[AppDelegate applicationDelegate] mainWindowController] showPageViewForIndex:index];
    NSLog(@"cellWasDoubleClickedAtIndex");
}




@end
