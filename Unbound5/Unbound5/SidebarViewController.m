//
//  SidebarViewController.m
//  Unbound
//
//  Created by Bob on 11/8/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "SidebarViewController.h"
#import "Album.h"
#import "SidebarTableCellView.h"
#import "SplitViewController.h"
#import "ImageBrowserViewController.h"

@interface SidebarViewController ()
{
    
}

@end

@implementation SidebarViewController

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
    //self.outlineView.dataSource = self.mainWindow;
    //self.outlineView.delegate = self.mainWindow;
    
    if (self.selectedAlbum)
    {
        NSUInteger index = [self.directoryArray indexOfObject:self.selectedAlbum];
        [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
        [self.outlineView scrollRowToVisible:index];
    }
}

-(CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    return 55;
}

- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    return [self.directoryArray count];
}


- (NSArray *)_childrenForItem:(id)item {
    NSArray *children;
    if (item == nil) {
        children = self.directoryArray;
    } else {
        children = [NSArray arrayWithObject:self.selectedAlbum];
    }
    return children;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return [self.directoryArray objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return NO;
}

-(id)outlineView:(NSOutlineView *) aView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return [item title];
}



- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    if ([self.outlineView selectedRow] != -1) {
        //Album *item = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
        Album *anAlbum =  [self.outlineView itemAtRow:[self.outlineView selectedRow]];
        if (self.selectedAlbum == anAlbum) {
            DLog(@"selectedAlbum didn't seem to change - no need to update browserView");
        } else if (anAlbum!=nil){
            self.selectedAlbum = anAlbum;
        } else {
            DLog(@"selectedAlbum in tableView doesn't exist - no need to update browserView");
            return;
        }
        
        //[self.browserData removeAllObjects];
        //[self.browserView reloadData];
        // NSURL *searchURL = [NSURL URLWithString:[newDir valueForKey:@"filePath"]];
        //Album *anAlbum = [self.directoryDict valueForKey:newDir.filePath];
        if (anAlbum!=nil)
        {
            DLog(@"New album selected");
            //self.splitViewController.selectedAlbum = anAlbum;
            self.splitViewController.imageBrowserViewController.album = anAlbum;
            [self.splitViewController.imageBrowserViewController.browserView reloadData];
            //[self.browserView reloadData];
        } else {
            //assert(NO);
            //NSURL *searchURL = [NSURL URLWithString:[anAlbum valueForKey:@"filePath"]];
            //[self createNewSearchForWithScopeURL:searchURL];
        }
        

    }
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    SidebarTableCellView *result = [outlineView makeViewWithIdentifier:@"MainCell" owner:self];
    result.album = (Album *)item;
    if (item == self.selectedAlbum)
    {
        DLog(@"Selected row sky");
    }
    return result;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index
{
	// get the URLs
	/*NSArray * urls = [[info draggingPasteboard] readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]] options:nil];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    // handle copied files
    NSError *anError = nil;
    BOOL refreshSrcDir = NO;
    NSString *srcpath = nil;
    for (NSURL * url in urls)
    {
        // check if the destination folder is different from the source folder
        if ([self.dragDropDestination.filePath isEqualToString:[  url.path stringByDeletingLastPathComponent]] || !self.dragDropDestination)
            continue;
        
        NSURL * destinationURL = [NSURL fileURLWithPath:self.dragDropDestination.filePath];
        
        NSURL *srcURL = url;//NSURL fileURLWithPath:url];
        destinationURL = [destinationURL URLByAppendingPathComponent:[url.path lastPathComponent]];
        
        
        if ([info draggingSource] == self.browserView) {
            DLog(@"Drag and drop is from browser view - default to move operation");
            if ([self optionKeyIsPressed]) {
                [fileManager copyItemAtURL:srcURL toURL:destinationURL error:&anError];
            } else {
                [fileManager moveItemAtPath:srcURL.path toPath:destinationURL.path error:&anError];
                refreshSrcDir = YES;
                srcpath = [srcURL.path stringByDeletingLastPathComponent];
            }
        } else {
            DLog(@"Drag and drop is outside source - default to copy operation");
            if (![NSEvent modifierFlags] & NSAlternateKeyMask) {
                [fileManager copyItemAtURL:srcURL toURL:destinationURL error:&anError];
            } else {
                [fileManager moveItemAtPath:srcURL.path toPath:destinationURL.path error:&anError];
                refreshSrcDir = YES;
                srcpath = [srcURL.path stringByDeletingLastPathComponent];
            }
        }
        
    }
    if (anError!=nil)
    {
        DLog(@"error copying dragged files : %@", anError);
    }
	
	if([self.browserData count] > 0) {
        [self.dragDropDestination updatePhotosFromFileSystem];
        if (refreshSrcDir && srcpath) {
            Album *srcAlbum = [self.fileSystemEventController.albumLookupTable valueForKey:srcpath];
            [srcAlbum updatePhotosFromFileSystem];
        }
        [self.browserView reloadData];
        return YES;
    }
	
	return NO;*/

}



-(NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    /*if (index != -1)
    {
        return NSDragOperationNone;
    }

    self.dragDropDestination = item;

    if ([info draggingSource] == self.browserView) {
		DLog(@"Drag and drop is from browser view - default to move operation");
        if ([self optionKeyIsPressed])
            return NSDragOperationCopy;
        else
            return NSDragOperationMove;
	} else {
        
        if (![self optionKeyIsPressed])
        {
            DLog(@"Drag and drop is outside source - default to copy operation");
            return NSDragOperationCopy;
        } else {
            DLog(@"Drag and drop is outside source with alt pressed - use move operation");
            return NSDragOperationMove;
        }
	}*/

}


-(void)setSelectedAlbum:(Album *)anAlbum
{
    _selectedAlbum = anAlbum;
}



@end
