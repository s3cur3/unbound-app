//
//  PIXSidebarViewController.m
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXSidebarViewController.h"
#import "PIXAppDelegate.h"
#import "PIXFileManager.h"
#import "PIXSidebarTableCellView.h"
#import "PIXSplitViewController.h"
#import "PIXPhotoCollectionViewController.h"
#import "PIXCollectionView.h"
#import "PIXFileParser.h"
#import "PIXAlbum.h"
#import "PIXPhoto.h"
#import "PIXDefines.h"
#import "Unbound-Swift.h"

@interface PIXSidebarViewController ()

@property (nonatomic, strong) NSArray * searchedAlbums;
@property (nonatomic, strong) NSString * lastSearch;

@end

@implementation PIXSidebarViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    
    return self;
}

-(NSArray *)albums
{
    if(_albums != nil) {return _albums;}
    
    //[self.view setWantsLayer:YES];
    _albums = [PIXAlbum sortedAlbums];
    
    return _albums;
}


- (void)controlTextDidChange:(NSNotification *)aNotification
{
    [self updateSearch];
}

-(IBAction)newAlbumPressed:(id)sender
{
    PIXAlbum * newAlbum = [[PIXFileManager sharedInstance] createAlbumWithName:@"New Album"]; // sends a notification that causes the album list to refresh
    NSUInteger index = [self.albums indexOfObject:newAlbum];
    NSAssert(index != NSNotFound, @"We should always find the album");
    [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[self scrollToSelectedAlbum];
	[self editSelectionName];
}

-(void)editSelectionName
{
	[self.outlineView editColumn:0 row:self.outlineView.selectedRow withEvent:nil select:YES];
}

-(void)updateSearch
{
    NSArray * prev = self.searchedAlbums == nil ? self.albums : self.searchedAlbums;
    NSString * searchText = [self.searchField stringValue];
    if(searchText != nil && [searchText length] > 0)
    {
		// if this search is more narrow than the last filter then re-filter based on the last set (this happens while typing)
		NSArray * toFilter = self.lastSearch != nil && [searchText rangeOfString:self.lastSearch].length > 0 ?
                             self.searchedAlbums :
                             self.albums;
        self.searchedAlbums = [toFilter filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.title CONTAINS[cd] %@", searchText]];
		self.lastSearch = searchText;
    }
    else
    {
        self.searchedAlbums = nil;
        self.lastSearch = nil;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:searchText forKey:@"PIX_AlbumSearchString"];

    NSArray * current = self.searchedAlbums == nil ? self.albums : self.searchedAlbums;
    if(![prev isEqualToArray:current]) {
        [self.outlineView reloadData];
        [self scrollToSelectedAlbum];
    }
}


-(void)willShowPIXView
{    
    [self.outlineView registerForDraggedTypes:[NSArray arrayWithObject: NSURLPboardType]];
    
    [self.outlineView setDraggingSourceOperationMask:(NSDragOperationCopy) forLocal:NO];

    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(albumsChanged:)
               name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM
             object:nil];

    [nc addObserver:self
           selector:@selector(albumCreated:)
               name:AlbumCreatedNotification
             object:nil];
	
    
    NSString * searchString = [[NSUserDefaults standardUserDefaults] objectForKey:@"PIX_AlbumSearchString"];
    
    if(searchString != nil)
    {
        [self.searchField setStringValue:searchString];
    }
    
    else
    {
        [self.searchField setStringValue:@""];
    }
    
    [self updateSearch];
}

-(void)scrollToSelectedAlbum
{
    if ([self currentlySelectedAlbum] != nil)
    {
		NSArray * albums = self.searchedAlbums == nil ? self.albums : self.searchedAlbums;
        NSUInteger index = [albums indexOfObject:[self currentlySelectedAlbum]];
        if(index != NSNotFound)
        {
			NSIndexSet * newSelection = [NSIndexSet indexSetWithIndex:index];
			if(![self.outlineView.selectedRowIndexes isEqualToIndexSet:newSelection])
			{
				[self.outlineView selectRowIndexes:newSelection byExtendingSelection:NO];
			}
            [self.outlineView scrollRowToVisible:index];
        }
    }
}

-(void)albumsChanged:(NSNotification *)note
{
    NSArray * latestAlbums = [PIXAlbum sortedAlbums];
    if(![latestAlbums isEqualToArray:self.albums]) {
		BOOL editing = self.outlineView.currentEditor != nil;
		if(editing)
		{
			[self.outlineView commitEditing];
		}
        self.albums = latestAlbums;
        [self.outlineView reloadData];
        [self scrollToSelectedAlbum];
		if(editing)
		{
			[self editSelectionName];
		}
    }
}

-(void)albumCreated:(NSNotification *)note
{
    PIXAlbum * album = note.userInfo[@"album"];
    if(![self.albums containsObject:album]) {
        [self.outlineView reloadData];
    }
    self.splitViewController.selectedAlbum = album;
    [self scrollToSelectedAlbum];
	[self editSelectionName];
}

-(Album *)currentlySelectedAlbum
{
    return self.splitViewController.selectedAlbum;
}

-(void)keyDown:(NSEvent *)event
{
	DLog("Keycode pressed: %d", event.keyCode);
	NSEventModifierFlags modifiers = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;
	if(modifiers == NSEventModifierFlagCommand) {
		if (event.keyCode == 51 && self.currentlySelectedAlbum != nil) { // Cmd + Backspace/delete
            [PIXFileManager.sharedInstance deleteItemsWorkflow:[NSSet setWithObject:self.currentlySelectedAlbum]];
			return;
		} else if ([@"n" isEqualToString:event.characters]) {
			[self newAlbumPressed:nil];
			return;
		}
	}

	[super keyDown:event];
}


#pragma mark - Drag and Drop Support

-(BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index
{
    if (index != -1 || item==nil)
    {
        return NO;
    }
    //DLog(@"drragging info %@", info);
    DLog(@"1)Dragging Source %@", [info draggingSource]);
    DLog(@"2)proposedItem %@", item);
    //Get the files from the drop
	//NSArray * files = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    //DLog(@"Sidebar acccepting droppped files : %@, option key presssed : %@", pathsToPaste, ([PIXViewController optionKeyIsPressed] ? @"YES" : @"NO"));
    DLog(@"Sidebar acccepting droppped files NSDraggingInfo : %@", info);
    //NSMutableArray *pathsToPaste = [NSMutableArray arrayWithCapacity:[files count]];
    
    NSString *destPath = self.dragDropDestination.path;
    NSArray *pathsToPaste = [[PIXFileManager sharedInstance] itemsForDraggingInfo:info forDestination:destPath];
    NSUInteger fileCount = [pathsToPaste count];
    info.numberOfValidItemsForDrop = fileCount;
    if (fileCount==0) {
        DLog(@"No files to drop after filtering return NO");
        return NO;
    }

    DLog(@"Sidebar acccepting drop with source : %@, option key presssed : %@", [info draggingSource], ([PIXViewController optionKeyIsPressed] ? @"YES" : @"NO"));
    if ( [[info draggingSource] class] == [PIXCollectionView class])
    {
        if (![PIXViewController optionKeyIsPressed])
        {
            DLog(@"acceptDrop -- Drag and drop is from browser - move operation");
            [[PIXFileManager sharedInstance] moveFiles:pathsToPaste];
        } else {
            DLog(@"acceptDrop -- Drag and drop is from browser WITH alt key pressed - copy operation");
            [[PIXFileManager sharedInstance] copyFiles:pathsToPaste];
        }
	} else {
        
        if ([PIXViewController optionKeyIsPressed])
        {
            DLog(@"acceptDrop -- Drag and drop is outside source with alt pressed - use move operation");
            [[PIXFileManager sharedInstance] moveFiles:pathsToPaste];
        } else {
            DLog(@"acceptDrop -- Drag and drop is outside source - default to copy operation");
            [[PIXFileManager sharedInstance] copyFiles:pathsToPaste];
        }
	}

    return YES;
    
    
}



-(NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    if (index != -1 || item==nil)
    {
        return NSDragOperationNone;
    }
    DLog(@"drragging info %@", info);
    DLog(@"Dragging Source %@", [info draggingSource]);
    DLog(@"proposedItem %@", item);
    PIXAlbum *dropDestAlbum = item;
    NSArray *pathsToPaste = [[PIXFileManager sharedInstance] itemsForDraggingInfo:info forDestination:dropDestAlbum.path];
    NSUInteger fileCount = [pathsToPaste count];
    info.numberOfValidItemsForDrop = fileCount;
    if (fileCount==0) {
        return NSDragOperationNone;
    }
    
    [info setNumberOfValidItemsForDrop:fileCount];
    
    self.dragDropDestination = item;
    
    DLog(@"Sidebar validating drop with source : %@, option key presssed : %@", [info draggingSource], ([PIXViewController optionKeyIsPressed] ? @"YES" : @"NO"));
    
    if ( [[info draggingSource] class] == [PIXCollectionView class])
    {
		
        if ([PIXViewController optionKeyIsPressed]) {
            DLog(@"Drag and drop is from browser WITH alt key pressed - copy operation");
            return NSDragOperationCopy;
        } else {
            DLog(@"Drag and drop is from browser - move operation");
            return NSDragOperationMove;
        }
	} else {
        
        if (![PIXViewController optionKeyIsPressed])
        {
            DLog(@"Drag and drop is outside source - default to copy operation");
            return NSDragOperationCopy;
        } else {
            DLog(@"Drag and drop is outside source with alt pressed - use move operation");
            return NSDragOperationMove;
        }
	}
    
}

#pragma mark - Dragging Source Methods:

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
    [pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:nil];
    
    NSMutableArray * filenames = [[NSMutableArray alloc] initWithCapacity:[items count]];
    
    for(PIXAlbum * anAlbum in items)
    {
        [filenames addObject:anAlbum.path];
        //[dragPBoard setString:anAlbum.path forType:NSFilenamesPboardType];
    }
    
    [pboard setPropertyList:filenames
                        forType:NSFilenamesPboardType];
    
    
    
    return YES;
}

- (IBAction)textTitleChanged:(id)sender {
    DLog(@"textTitleChanged");
    if ([self.outlineView selectedRow] != -1) {
        NSTextField *aTextField =(NSTextField *)sender;

        PIXAlbum *anAlbum =  [self.outlineView itemAtRow:[self.outlineView selectedRow]];
        if ([aTextField.stringValue length]==0 || [aTextField.stringValue isEqualToString:anAlbum.title])
        {
            DLog(@"renaming to empty string or same name disallowed.");
            return;
        }
        
        BOOL success = [[PIXFileManager sharedInstance] renameAlbum:anAlbum withName:aTextField.stringValue];
        
        if (!success)
        {
            //an error occurred when moving so keep the old title
            aTextField.stringValue = anAlbum.title;
            [[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] makeFirstResponder:aTextField];
            return;
        } else {
            //[[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:anAlbum];
            DLog(@"Album was renamed successfuly : \"%@\"", anAlbum.path);
        }
    }
}

-(void)moveRight:(id)sender
{
    // make the image grid the first responder
    [self.view.window makeFirstResponder:self.splitViewController.imageBrowserViewController.collectionView];
    [self.splitViewController.imageBrowserViewController selectFirstItem];
}

-(void)cancelOperation:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.splitViewController popViewAndUpdateAlbumSelectionForDelegate];
    });
    
}


-(void)dealloc
{
    self.outlineView.delegate = nil;
    self.outlineView.dataSource = nil;
    self.splitViewController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
}

-(BOOL)becomeFirstResponder
{
    return YES;
}

-(BOOL)acceptsFirstResponder
{
    return YES;
}

-(void)rightMouseDown:(NSEvent *)theEvent {
    DLog(@"rightMouseDown:%@", theEvent);
    [[self nextResponder] rightMouseDown:theEvent];
}

@end

@implementation PIXSidebarViewController(NSOutlineViewDelegate)

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    PIXSidebarTableCellView *result = [outlineView makeViewWithIdentifier:@"MainCell" owner:self];
    result.album = (PIXAlbum *)item;
    return result;
}

-(void)outlineViewSelectionDidChange:(NSNotification *)notification {
    NSInteger aSelectedRow = [self.outlineView selectedRow];
    
    if (aSelectedRow != -1) {
        
        PIXAlbum *anAlbum =  [self.outlineView itemAtRow:aSelectedRow];
        if (anAlbum!=nil)
        {
            //DLog(@"New album selected");
            self.splitViewController.selectedAlbum = anAlbum;
        }
        
        
    }
}

//Working with Items in a View
-(CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    return 55;
}

@end

@implementation PIXSidebarViewController(NSOutlineViewDataSource)

- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    
    if(self.searchedAlbums != nil)
    {
        return [self.searchedAlbums count];
    }
    
    return [self.albums count];
}


- (NSArray *)_childrenForItem:(id)item {

    if (item == nil) {
        
        if(self.searchedAlbums != nil)
        {
            return self.searchedAlbums;
        }
        
        return self.albums;
    }
    
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if(item == nil)
    {
        if(self.searchedAlbums != nil)
        {
            return [self.searchedAlbums objectAtIndex:index];
        }
        
        return [self.albums objectAtIndex:index];
    }
    
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return NO;
}

-(id)outlineView:(NSOutlineView *) aView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return [item title];
}



@end
