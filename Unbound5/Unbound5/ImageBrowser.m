#import "ImageBrowser.h"
#import "ImageBrowserDelegate.h"
#import "../DataSources/ImageItem.h"
#import "../DataSources/ImageDataSource.h"
#import "../Preferences/Preferences.h"
#import "../Utils/FileUtils.h"
#import "../Utils/Utils.h"
//#import "../Utils/SlideShow.h"


@implementation ImageBrowser

-(void)awakeFromNib
{
	// cell spacing
	[self setIntercellSpacing:NSMakeSize(5.0f, 5.0f)];

	// forground color for the cell's titles
	NSMutableDictionary * options = [[NSMutableDictionary alloc] init];
	[options setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	[self setValue:options forKey:IKImageBrowserCellsTitleAttributesKey];
	[options release];
}

-(void)dealloc
{
	[super dealloc];
}

/**
	This method is used to seemlessly reload data. Since the selected image is
	bound to the current image of the image view, when we do the usual
	reloadData, the selection is lost. If we're in fullscreen, it'll break it.
	So this method reloads data and select the next available image just after
	that.
*/
-(void)reloadDataAndKeepSelection
{
	// remember the first selected image
	int selectedIndex = (int)[[self selectionIndexes] firstIndex];

	// reload the data
	[(ImageBrowserDelegate *)[self delegate] setIgnoreSelectionChanges:YES];
	[super reloadData];
	[(ImageBrowserDelegate *)[self delegate] setIgnoreSelectionChanges:NO];

	// restore the selection, taking care of out of bound indexes	
	int numImages = (int)[[self dataSource] numberOfItemsInImageBrowser:self];
	if (numImages != 0)
	{
		if (selectedIndex >= numImages)
			selectedIndex = numImages - 1;
		[self setSelectionIndexes:[NSIndexSet indexSetWithIndex:selectedIndex]
			  byExtendingSelection:NO];
	}
	else
	{
		// if there is no more images, we need to explicitely set the image
		// property of the delegate to nil.
		// This is because [super reloadData] set the current selection to
		// nothing, so setting it again to nothing will NOT call the selection
		// changed delegate, thus the need to explicitely call setSelectedImage.
		[(ImageBrowserDelegate *)[self delegate] setSelectedImage:nil];
	}
}

-(void)reloadData
{
	[super reloadData];
	[self scrollPoint:NSMakePoint(0, [self frame].size.height)];
}

-(void)selectNextImage:(NSTimer *)timer
{
	// get the index of the first selected image
	/*int selectedImage = -1;
	if ([self selectionIndexes] != nil || [[self selectionIndexes] count] != 0)
		selectedImage = (int)[[self selectionIndexes] firstIndex];

	// increment it, and check for bound, and loop
	++selectedImage;
	int numImages = (int)[[self dataSource] numberOfItemsInImageBrowser:nil];
	if (selectedImage >= numImages)
	{
		if ([[timer userInfo] boolValue] == YES)
		{
			selectedImage = 0;
		}
		else
		{
			selectedImage = (int)numImages - 1;
			
			// also stop the slide show
			[SlideShow stopSlideShow];
		}
	}

	// finally, set the new image
	[self setSelectionIndexes:[NSIndexSet indexSetWithIndex:selectedImage]
		  byExtendingSelection:NO];*/
}

-(BOOL)showTitles
{
	return [self cellsStyleMask] & IKCellsStyleTitled;
}

-(void)setShowTitles:(BOOL)showTitles
{
	if (showTitles == YES)
		[self setCellsStyleMask:[self cellsStyleMask] | IKCellsStyleTitled];
	else
		[self setCellsStyleMask:[self cellsStyleMask] & ~IKCellsStyleTitled];
}

-(float)thumbnailMargin
{
	return [self intercellSpacing].width;
}

-(void)setThumbnailMargin:(BOOL)margin
{
	[self setIntercellSpacing:NSMakeSize(margin, margin)];
}

-(BOOL)setFullscreen
{
	// if still nothing's selected, it means we don't have any image
	// in the image browser, so simply break (launching a slideshow
	// on an empty folder has no meaning :)
	if ([self selectionIndexes] == nil ||
		[[self selectionIndexes] count] == 0)
		return NO;

	// select only the first one
	[self setSelectionIndexes:[NSIndexSet indexSetWithIndex:[[self selectionIndexes] firstIndex]]
		  byExtendingSelection:NO];

	// set the fullscreen property of the delegate (which is binded to the
	// image view)
	[(ImageBrowserDelegate *)[self delegate] setFullscreen:YES];
	
	return YES;
}

-(ImageItem *)itemAtIndex:(NSUInteger)index
{
	return [[self dataSource] imageBrowser:self itemAtIndex:index];
}

-(NSArray *)selectedImagesAsURLArray
{
	NSIndexSet * indexes = [self selectionIndexes];
	NSUInteger index = [indexes firstIndex];
	NSMutableArray * files = [NSMutableArray arrayWithCapacity:[indexes count]];
	while (index != NSNotFound)
	{
		[files addObject:[NSURL fileURLWithPath:[[self itemAtIndex:index] path]]];
		index = [indexes indexGreaterThanIndex:index];
	}
	return files;
}

-(void)deleteSelectedImages
{
	// remove files from the disk
	NSArray * files = [self selectedImagesAsURLArray];
	for (NSURL * file in files)
		[[FileUtils instance] removeItemAtPath:[file path]];
}

-(void)cutSelectedImages
{
	[[FileUtils instance] cutItems:[self selectedImagesAsURLArray]];
}

-(void)copySelectedImages
{
	[[FileUtils instance] copyItems:[self selectedImagesAsURLArray]];
}

-(void)setSelectedImage:(NSString *)image
{
	[(ImageBrowserDelegate *)[self delegate] setSelectedImage:image];
}

-(IBAction)selectAll:(id)sender
{
	// check if we're not in fullscreen
	if ([(ImageBrowserDelegate *)[self delegate] fullscreen] == YES)
		return;

	int numImages = (int)[[self dataSource] numberOfItemsInImageBrowser:self];
	if (numImages == 0)
		return;

	// ensure the image browser is the first responder when it selects all
	[[self window] makeFirstResponder:self];

	NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numImages)];
	[self setSelectionIndexes:indexSet byExtendingSelection:NO];
}

-(IBAction)deselectAll:(id)sender
{
	// check if we're not in fullscreen
	if ([(ImageBrowserDelegate *)[self delegate] fullscreen] == YES)
		return;

	[self setSelectionIndexes:nil byExtendingSelection:NO];
}

-(void)keyDown:(NSEvent *)theEvent
{
	// get the event and the modifiers
	/*NSString * characters = [theEvent charactersIgnoringModifiers];
	unichar event = [characters characterAtIndex:0];

	switch (event)
	{
		// space & p : play / pause slideshow
		case ' ':
		case 'p':
			if ([SlideShow isRunning] == YES)
			{
				[SlideShow stopSlideShow];
			}
			else
			{
				if ([self setFullscreen] == YES)
					[SlideShow startSlideShow:self callback:@"selectNextImage:"];
			}
			break;

		// enter & escape : leave fullscreen
		case 13:
		case 27:
			[self setFullscreen];
			break;

		default:
			[super keyDown:theEvent];
	}*/
}

-(void)otherMouseDown:(NSEvent *)theEvent
{
	if ([theEvent clickCount] == 1)
		[self setFullscreen];
}

@end
