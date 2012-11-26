//
//  AlbumiViewController.m
//  Unbound
//
//  Created by Bob on 11/5/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "AlbumViewController.h"
#import "Album.h"
#import "ImageBrowserViewController.h"
#import "PINavigationViewController.h"
#import "SplitViewController.h"

@interface AlbumViewController ()

@end

@implementation IconViewBox

// -------------------------------------------------------------------------------
//	hitTest:aPoint
// -------------------------------------------------------------------------------
- (NSView *)hitTest:(NSPoint)aPoint
{
    // don't allow any mouse clicks for subviews in this NSBox
    if(NSPointInRect(aPoint,[self convertRect:[self bounds] toView:[self superview]])) {
		return self;
	} else {
		return nil;
	}
}

-(void)mouseDown:(NSEvent *)theEvent {
	[super mouseDown:theEvent];
    
	// check for click count above one, which we assume means it's a double click
	if([theEvent clickCount] > 1) {
		NSLog(@"double click!");
		if(delegate && [delegate respondsToSelector:@selector(doubleClick:)]) {
            [delegate performSelector:@selector(doubleClick:) withObject:theEvent];
        }
	}
    
    if(( [NSEvent modifierFlags] & NSCommandKeyMask ) != 0 ) {
        DLog(@"mouseDown with command pressed");
        if(delegate && [delegate respondsToSelector:@selector(rightMouseDown:)]) {
            [delegate performSelector:@selector(rightMouseDown:) withObject:theEvent];
        }
    } else {
        DLog(@"mouseDown");
    }
}

-(void)rightMouseDown:(NSEvent *)theEvent {
    DLog(@"rightMouseDown:%@", theEvent);
    
    if(delegate && [delegate respondsToSelector:@selector(rightMouseDown:)]) {
        [delegate performSelector:@selector(rightMouseDown:) withObject:theEvent];
    }
}

-(IBAction)deleteItem:(id)sender
{
    DLog(@"Delete Item");
    Album *anAlbum = (Album *)[delegate representedObject];
    if (NSRunCriticalAlertPanel(
                                [NSString stringWithFormat:@"The album \"%@\" " @"will be deleted immediately.\nAre you sure you want to continue?", [anAlbum title]], @"You cannot undo this action.", @"Delete", @"Cancel", nil) == NSAlertDefaultReturn) {
        
        NSCollectionView *collectionView = [delegate collectionView];
        id collectionViewDelegate = [collectionView delegate];
        if(collectionViewDelegate && [collectionViewDelegate respondsToSelector:@selector(deleteAlbum:)]) {
            [collectionViewDelegate performSelector:@selector(deleteAlbum:) withObject:anAlbum];
        }
        
        //return [self removeFileAtPath:standardizedSource handler:nil];
    } else { // User clicked cancel, they obviously do not want to delete the file. return NO;
    }

}

@end


/*@implementation MyScrollView

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
    // set up the background gradient for this custom scrollView
    //backgroundGradient = [[NSGradient alloc] initWithStartingColor:
                          //[NSColor colorWithDeviceRed:0.349f green:0.6f blue:0.898f alpha:0.0f]
                                                       //endingColor:[NSColor colorWithDeviceRed:0.349f green:0.6f blue:.898f alpha:0.6f]];
}

// -------------------------------------------------------------------------------
//	drawRect:rect
// -------------------------------------------------------------------------------
- (void)drawRect:(NSRect)rect
{
    // draw our special background as a gradient
    //[backgroundGradient drawInRect:[self documentVisibleRect] angle:90.0f];
}

// -------------------------------------------------------------------------------
//	dealloc
// -------------------------------------------------------------------------------
- (void)dealloc
{
    backgroundGradient = nil;
}

@end*/


@implementation AlbumViewController


//#define KEY_IMAGE	@"icon"
//#define KEY_NAME	@"name"

#define KEY_IMAGE	@"thumbnailImage"
#define KEY_NAME	@"title"

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{

    [self setSortingMode:0];		// icon collection in ascending sort order
    
    self.images = self.albums;
    
    
    [self.collectionView setMaxItemSize:NSSizeFromCGSize(CGSizeMake(300, 200))];
    [self.collectionView setMinItemSize:NSSizeFromCGSize(CGSizeMake(200, 200))];
    
    [self.collectionView setWantsLayer:YES];
    
    return;

    
    
}

-(IBAction)deleteAlbum:(Album *)anAlbum
{
    DLog(@"deleteItem");
    //[self.albums removeObject:anAlbum];
    [anAlbum removeMetadataAndImageFiles];
    [arrayController removeObject:anAlbum];
}

-(IBAction)createNewAlbum:(id)sender;
{
    DLog(@"createNewAlbum");
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //[dateFormatter setDateFormat:@"yy-MM-dd HH:mm:ss"];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    Album *newAlbum = [Album createAlbumWithName:[NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:[NSDate date]]]];
    //[newAlbum updatePhotosFromFileSystem];
    //[self.images addObject:newAlbum];
    
    [arrayController addObject:newAlbum];
    
    //[self updateContent:self.images];
    //[collectionView setNeedsDisplay:YES];
}

-(void)updateAlbumInfo:(NSNotification *)notification
{
    DLog(@"Album was updated : %@", notification);
}

// -------------------------------------------------------------------------------
//	dealloc
// -------------------------------------------------------------------------------
- (void)dealloc
{
    savedAlternateColors = nil;
}

// -------------------------------------------------------------------------------
//	setSortingMode:newMode
// -------------------------------------------------------------------------------
- (void)setSortingMode:(NSUInteger)newMode
{
    _sortingMode = newMode;
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                               initWithKey:KEY_NAME
                               ascending:(_sortingMode == 0)
                               selector:@selector(caseInsensitiveCompare:)];
    [arrayController setSortDescriptors:[NSArray arrayWithObject:sort]];
}

// -------------------------------------------------------------------------------
//	collectionView:writeItemsAtIndexes:indexes:pasteboard
//
//	Collection view drag and drop
//  User must click and hold the item(s) to perform a drag.
// -------------------------------------------------------------------------------
- (BOOL)collectionView:(NSCollectionView *)cv writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
{
    NSMutableArray *urls = [NSMutableArray array];
    NSURL *temporaryDirectoryURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
     {
         NSDictionary *dictionary = [[cv content] objectAtIndex:idx];
         NSImage *image = [dictionary valueForKey:KEY_IMAGE];
         NSString *name = [dictionary valueForKey:KEY_NAME];
         if (image && name)
         {
             NSURL *url = [temporaryDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.tiff", name]];
             [urls addObject:url];
             [[image TIFFRepresentation] writeToURL:url atomically:YES];
         }
     }];
    if ([urls count] > 0)
    {
        [pasteboard clearContents];
        return [pasteboard writeObjects:urls];
    }
    return NO;
}


- (NSCollectionViewItem *)newItemForRepresentedObject:(id)object;
{
    NSCollectionViewItem *anItem = [[NSCollectionViewItem alloc] init];
    return anItem;
}

-(void)showPhotosForAlbum:(Album *)anAlbum
{
    //ImageBrowserViewController *anImageBrowserViewController  = [[ImageBrowserViewController alloc] initWithNibName:@"Collections" bundle:nil album:anAlbum];
    
    SplitViewController *aSplitViewController  = [[SplitViewController alloc] initWithNibName:@"SplitViewController" bundle:nil albums:self.albums selectedAlbum:anAlbum];
    [aSplitViewController.view setFrame:self.view.bounds];
    [self.navigationViewController pushViewController:aSplitViewController];
}

- (void)doubleClick:(id)sender {
	NSLog(@"Double clicked on icon: %@", [[sender representedObject] valueForKey:@"title"]);
    Album *anAlbum = [sender representedObject];
    [self showPhotosForAlbum:anAlbum];
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"ShowPhotos" object:[sender representedObject]];
}

-(void)updateContent:(NSMutableArray *)newContent;
{
    self.albums = newContent;
    [self.collectionView setContent:newContent];
}

@end
