#import <Quartz/Quartz.h>
#import "ImageBrowserDelegate.h"
#import "ImageBrowser.h"
//#import "../DataSources/ImageDataSource.h"
//#import "../DataSources/ImageItem.h"
//#import "../Utils/Utils.h"


@implementation ImageBrowserDelegate


-(id)init
{
	self = [super init];
	if (self != nil)
	{
		mSelectedImage			= nil;
		mIgnoreSelectionChanges	= NO;
	}
	return self;
}

/*-(void)dealloc
{
	if (mSelectedImage != nil)
	{
		[mSelectedImage release];
		mSelectedImage = nil;
	}
	[super dealloc];	
}*/

-(NSString *)selectedImage
{
	return mSelectedImage;
}

-(void)setSelectedImage:(NSString *)image
{
	if (mSelectedImage != image)
	{
		// NOTE: here, we check if the image if different from the current one.
		//		 This means that if we reach this point, the selected image was
		//		 set by an external source (by binding or whatever)
		//		 This is also why we need to scroll the view to show the new
		//		 selected image.
		if (mSelectedImage != nil)
			[mSelectedImage release];
		mSelectedImage = [image copy];

		// update the selected image of the view
		ImageDataSource * dataSource = (ImageDataSource *)[mImageBrowser dataSource];
		
		// get the index corresponding to the image
		NSInteger imageIndex = [dataSource indexOfImage:image];
		NSIndexSet * indices = [NSIndexSet indexSetWithIndex:imageIndex];
		[mImageBrowser setSelectionIndexes:indices byExtendingSelection:NO];
		
		// scroll to selected image
		[mImageBrowser scrollIndexToVisible:imageIndex];
	}
}

-(void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser
{
	if (mIgnoreSelectionChanges == YES)
		return;

	// get the selection indexes
	NSIndexSet * selectionIndexes = [mImageBrowser selectionIndexes];

	// set the first selected image, so that any other view bound to
	// selectedImage will be notified
	if ([selectionIndexes count] == 0)
	{
		[self setSelectedImage:nil];
	}
	else
	{
		NSUInteger index = [selectionIndexes firstIndex];
		ImageItem * item = [[mImageBrowser dataSource] imageBrowser:nil
													   itemAtIndex:index];
		[mSelectedImage release];
		mSelectedImage = [[item path] copy];
		[self setSelectedImage:[item path]];
	}
}

-(void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index
{
	// NOTE: the fullscreen property of this instance is bound to the fullscreen
	//		 property of the image view, so this will automatically toggle
	//		 fullscreen without having a direct reference to ImageView
	[self setFullscreen:![self fullscreen]];
}

-(NSUInteger)imageBrowser:(IKImageBrowserView *)aBrowser
			 writeItemsAtIndexes:(NSIndexSet *)itemIndexes
			 toPasteboard:(NSPasteboard *)pasteboard
{
	NSArray * selectedImages = [mImageBrowser selectedImagesAsURLArray];
	[pasteboard clearContents];
	[pasteboard writeObjects:selectedImages];
	return [selectedImages count];
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
    //
}

@end
