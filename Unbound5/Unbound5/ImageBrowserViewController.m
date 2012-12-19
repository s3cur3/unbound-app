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
#import "Photo.h"
#import "AppDelegate.h"
#import "PIFileManager.h"

@interface ImageBrowserViewController ()

@property BOOL justChangedSelection;

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

-(NSArray *)browserData
{
    if (_browserData == nil) {
        _browserData = self.album.photos;
    }
    return _browserData;
}

-(void)awakeFromNib
{
    if (self.browserView)
    {
        [self.view addSubview:self.selectionToolbar];
        
        [self.browserView setDraggingDestinationDelegate:self];
        
        NSColor * color = [NSColor colorWithPatternImage:[NSImage imageNamed:@"dark_bg"]];
        [[self.browserView enclosingScrollView] setBackgroundColor:color];
        //self.browserData = self.album.photos;
        
        [self.browserView setAllowsMultipleSelection:YES];
        [self.browserView reloadData];
        
        
        self.selectionToolbarHidden = YES;
    }
}

-(NSView *)selectionToolbar
{
    if(_selectionToolbar != nil) return _selectionToolbar;
    
    _selectionToolbar = [[NSView alloc] initWithFrame:NSMakeRect(0, self.view.frame.size.height, self.view.frame.size.width, 44)];
    
    [_selectionToolbar setLayer:[CALayer layer]];
    [_selectionToolbar setWantsLayer:YES];
    
    [_selectionToolbar.layer setBackgroundColor:CGColorCreateGenericRGB(0.791, 0.933, 0.997, 1.000)];
    [_selectionToolbar.layer setBorderColor:CGColorCreateGenericGray(0.0, .3)];
        
    [_selectionToolbar setAutoresizingMask:NSViewWidthSizable];
    
    return _selectionToolbar;
}

-(void)setSelectionToolbarHidden:(BOOL)value
{
    if(_selectionToolbarHidden == value) return;
    
    _selectionToolbarHidden = value;
    
    [self.selectionToolbar setFrame:NSMakeRect(0, self.view.frame.size.height-44, self.view.frame.size.width, 44)];
    [self.selectionToolbar.layer setZPosition:1000];
    
    if(_selectionToolbarHidden)
    {
        /*
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.25f];
        
        [[self.selectionToolbar animator] setFrame:NSMakeRect(0, self.view.frame.size.height, self.view.frame.size.width, 44)];
        
        [NSAnimationContext endGrouping];

        */
        [CATransaction setDisableActions:NO];
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.25f];
        
        

        //[self.selectionToolbar.layer setOpacity:0.0];
        [self.selectionToolbar.layer setPosition:CGPointMake(0, 44)];
            
        [CATransaction commit];
        
        //[CATransaction setDisableActions:YES];
    }
    
    else
    {
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.25f];
        
        

        
        //[self.selectionToolbar.layer setOpacity:1.0];
        [self.selectionToolbar.layer setPosition:CGPointMake(0, 0)];
        
        [CATransaction commit];
        
        /*
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.25f];
        
        [[self.selectionToolbar animator] setFrame:NSMakeRect(0, self.view.frame.size.height-44, self.view.frame.size.width, 44)];
        
        [NSAnimationContext endGrouping];
        
        /*
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.25f]; 
        
        [[self.selectionToolbar animator] setFrame:NSMakeRect(0, self.view.frame.size.height-44, self.view.frame.size.width, 44)];
        
        [NSAnimationContext endGrouping];*/
    }
}


-(void)albumChanged:(NSNotification *)notification
{    
    self.browserData = nil;
    [self.browserView reloadData];
}

-(void)setAlbum:(Album *)album
{
    if(_album == album) return;
    if (_album!=nil)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AlbumDidChangeNotification object:_album];
    }
    if (album!=nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumChanged:) name:AlbumDidChangeNotification object:_album];
        
    }
    _album = album;
    if (self.browserView)
    {
        self.selectedPhotos = nil;
        [self.browserView setSelectionIndexes:nil byExtendingSelection:NO];
        
        self.browserData = nil;
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
    //NSIndexSet *selectedItems = [self.browserView selectionIndexes];
    NSArray *itemsToDelete = [self.browserData objectsAtIndexes:indexes];
    [self deleteItems:itemsToDelete];
    /*if ([selectedItems count]>1)
    {
        //[self.browserData removeObjectsAtIndexes:indexes];
        //[self.browserView reloadData];
        NSRunAlertPanel(@"Multiple Deletion", @"Deleting multiple photos is not available yet.", @"OK", nil, nil);
    } else if ([selectedItems count]==1) {
        NSUInteger index = [selectedItems lastIndex];
        [self deleteItems:[self.browserData objectAtIndex:index]];
    }*/
	
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
    if([aBrowser.selectionIndexes count] > 0)
    {
        self.selectionToolbarHidden = NO;
    }
    
    else
    {
        self.selectionToolbarHidden = YES;
    }
}


// -------------------------------------------------------------------------------
//  imageBrowser:cellWasDoubleClickedAtIndex:index
// -------------------------------------------------------------------------------
- (void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index
{
    // deselect all items in the view
    [self.browserView setSelectionIndexes:nil byExtendingSelection:NO];
    
    self.browserData = nil;
    [self.browserView reloadData];
    
    
    NSLog(@"cellWasDoubleClickedAtIndex");
    [self showPageControllerForIndex:index];
    //MainWindowController *windowController = (MainWindowController *) [[[NSApplication sharedApplication] mainWindow] delegate];
    //[windowController showPageControllerForAlbum:self.album];
    //return;
    
    //pageViewController.view.frame = ((NSView*)mainWindow.contentView).bounds;
    
}

-(void)showPageControllerForIndex:(NSUInteger)index
{
    PageViewController *pageViewController = [[PageViewController alloc] initWithNibName:@"PageViewController" bundle:nil];
    pageViewController.album = self.album;
    pageViewController.initialSelectedItem = [self.album.photos objectAtIndex:index];
    [self.navigationViewController pushViewController:pageViewController];
}


// Since IKImageBrowserView doesn't support context menus out of the box, we need to display them manually in
// the following two delegate methods. Why couldn't Apple take care of this?

- (void) imageBrowser:(IKImageBrowserView*)inView backgroundWasRightClickedWithEvent:(NSEvent*)inEvent
{
    if ([[self.browserView selectionIndexes] count])
    {
        //NSMenu* menu = [self menuForObject:nil];
        NSMenu*  menu;
        
        menu = [[NSMenu alloc] initWithTitle:@"menu"];
        [menu setAutoenablesItems:NO];
        
        [menu addItemWithTitle:[NSString stringWithFormat:@"Create New Album"] action:
         @selector(createAlbumWithSelectedPhotos:) keyEquivalent:@""];
        //[menu addItemWithTitle:[NSString stringWithFormat:@"Delete"] action:
        //@selector(deleteItems:) keyEquivalent:@""];
        
        [[[menu itemArray] lastObject] setTarget:self];
        
        [NSMenu popUpContextMenu:menu withEvent:inEvent forView:inView];
    }
}

- (void) imageBrowser:(IKImageBrowserView *) aBrowser
cellWasRightClickedAtIndex:(NSUInteger) inIndex withEvent:(NSEvent *)
event
{
    
    Photo* object = [self.browserData objectAtIndex:inIndex];
	//NSMenu* menu = [self menuForObject:object];
	//[NSMenu popUpContextMenu:menu withEvent:inEvent forView:inView];
    //contextual menu for item index
    NSMenu*  menu;
    
    menu = [[NSMenu alloc] initWithTitle:@"menu"];
    [menu setAutoenablesItems:NO];
    
    [menu addItemWithTitle:[NSString stringWithFormat:@"Open"] action:
     @selector(openInApp:) keyEquivalent:@""];
    [menu addItemWithTitle:[NSString stringWithFormat:@"Delete"] action:
     @selector(deleteItems:) keyEquivalent:@""];
    [menu addItemWithTitle:[NSString stringWithFormat:@"Get Info"] action:
     @selector(getInfo:) keyEquivalent:@""];
    [menu addItemWithTitle:[NSString stringWithFormat:@"Show In Finder"] action:
     @selector(revealInFinder:) keyEquivalent:@""];
    
    for (NSMenuItem * anItem in [menu itemArray])
    {
        [anItem setRepresentedObject:object];
    }
    
    
    [NSMenu popUpContextMenu:menu withEvent:event forView:aBrowser];
}

-(IBAction)getInfo:(id)sender;
{
    //NSInteger row = [sender clickedRow];
    NSIndexSet *idxSet = [self.browserView selectionIndexes];
    
    [idxSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        Photo *item = [self.browserData objectAtIndex:idx];
        if (item) {
            NSPasteboard *pboard = [NSPasteboard pasteboardWithUniqueName];
            [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
            [pboard setString:[item.filePath path]  forType:NSStringPboardType];
            NSPerformService(@"Finder/Show Info", pboard);
        }
    }];
    
}

- (IBAction) openInApp:(id)sender
{
    NSIndexSet *idxSet = [self.browserView selectionIndexes];
    [idxSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        Photo *item = [self.browserData objectAtIndex:idx];
        if (item) {
            NSString* path = (NSString*)[[item filePath] path];
            [[NSWorkspace sharedWorkspace] openFile:path];
        }
    }];
	
}

- (IBAction) revealInFinder:(id)inSender
{
	NSString* path = [[(Photo *)[inSender representedObject] filePath] path];
	NSString* folder = [path stringByDeletingLastPathComponent];
	[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:folder];
}

- (IBAction) createAlbumWithSelectedPhotos:(id)inSender
{
	DLog(@"createAlbumWithSelectedPhotos");
    NSRunAlertPanel(@"Create Album", @"This feature is not ready yet.", @"OK", nil, nil);
}

-(void)moveItems:(NSArray *)items
{
    NSMutableArray *undoArray = [NSMutableArray arrayWithCapacity:items.count];
    for (NSDictionary *aDict in items)
    {
        NSString *src = [aDict valueForKey:@"source"];
        NSString *dest = [aDict valueForKey:@"destination"];
        
        NSString *undoSrc = [NSString stringWithFormat:@"%@/%@", dest, [src lastPathComponent]];
        NSString *undoDest = [src stringByDeletingLastPathComponent];
        
        [undoArray addObject:@{@"source" : undoSrc, @"destination" : undoDest}];
                         
        [[NSWorkspace sharedWorkspace]
         performFileOperation:NSWorkspaceMoveOperation
         source: [src stringByDeletingLastPathComponent]
         destination:dest
         files:[NSArray arrayWithObject:[src lastPathComponent]]
         tag:nil];
    }
    
    [self.album updatePhotosFromFileSystem];
    self.browserData = nil;
    [self.browserView reloadData];
    
    NSUndoManager *undoManager = [[AppDelegate applicationDelegate] undoManager];
    [undoManager registerUndoWithTarget:self selector:@selector(moveItems:) object:undoArray];
    
}

- (IBAction) deleteItems:(id )inSender
{
    if ([[inSender class] isKindOfClass: [NSArray class]])
    {
        inSender =  [NSArray arrayWithObject:inSender];
    }
    
    NSMutableArray *pathsToDelete = [NSMutableArray arrayWithCapacity:[inSender count]];
    NSString *trashFolder = [[AppDelegate applicationDelegate] trashFolderPath];
    for (id anItem in (NSArray *)inSender)
    {
        NSString *path = nil;
        //Photo *aPhoto = nil;
        if ([anItem class] == [Photo class])
        {
            path = [[(Photo*)anItem filePath] path];
            //aPhoto = anItem;
        } else {
            path = [[(Photo*)[anItem representedObject] filePath] path];
            //aPhoto = [anItem representedObject];
        }
        
        [pathsToDelete addObject:@{@"source" : path, @"destination" : trashFolder}];
    }

    
    if (NSRunCriticalAlertPanel(
                                [NSString stringWithFormat:@"The file(s) will be deleted immediately.\nAre you sure you want to continue?"], @"You cannot undo this action.", @"Delete", @"Cancel", nil) == NSAlertDefaultReturn) {
        
        
        
        //[self moveItems:pathsToDelete];
        [[[AppDelegate applicationDelegate] sharedFileManager] moveFiles:pathsToDelete];
        /*[self.album updatePhotosFromFileSystem];
        self.browserData = nil;
        [self.browserView reloadData];*/
        
        //[self.browserData removeObject:aPhoto];
        
        
        
        
        //return [self removeFileAtPath:standardizedSource handler:nil];
    } else { // User clicked cancel, they obviously do not want to delete the file. return NO;
    } 

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
	//Get the files from the drop
	NSArray * files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    
    NSMutableArray *pathsToPaste = [NSMutableArray arrayWithCapacity:[files count]];
    NSString *destPath = self.album.filePath;
    for (NSString * path in files)
    {
        [pathsToPaste addObject:@{@"source" : path, @"destination" : destPath}];
    }
    
    if ([self optionKeyIsPressed])
    {
        [[[AppDelegate applicationDelegate] sharedFileManager] moveFiles:pathsToPaste];
    } else {
        [[[AppDelegate applicationDelegate] sharedFileManager] copyFiles:pathsToPaste];
    }
    return YES;
    
    // handle copied files
    /*NSError *anError = nil;
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
	
	return NO;*/
}

- (void)concludeDragOperation:(id < NSDraggingInfo >)sender
{
    //[self.browserView setAnimates:NO];
	//[self.browserView reloadData];
}



@end
