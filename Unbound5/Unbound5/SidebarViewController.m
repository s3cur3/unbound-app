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
#import "PIViewController.h"
#import "AppDelegate.h"
#import "PIFileManager.h"

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
        
        //[self.outlineView setDataSource:self.splitViewController];
        
        [self.outlineView registerForDraggedTypes:[NSArray arrayWithObject: NSURLPboardType]];
    }
}





-(void)setSelectedAlbum:(Album *)anAlbum
{
    _selectedAlbum = anAlbum;
}



@end

@implementation SidebarViewController(NSOutlineViewDataSource)


//Working with Items in a View
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
    return result;
}
//

//Drag and Drop Support

-(BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index
{
    
    //Get the files from the drop
	NSArray * files = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    
    NSMutableArray *pathsToPaste = [NSMutableArray arrayWithCapacity:[files count]];
    NSString *destPath = self.dragDropDestination.filePath;
    for (NSString * path in files)
    {
        [pathsToPaste addObject:@{@"source" : path, @"destination" : destPath}];
    }
    
    if ([PIViewController optionKeyIsPressed] == NO)
    {
        [[[AppDelegate applicationDelegate] sharedFileManager] moveFiles:pathsToPaste];
    } else {
        [[[AppDelegate applicationDelegate] sharedFileManager] copyFiles:pathsToPaste];
    }
    return YES;

    
}



-(NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    if (index != -1)
    {
        return NSDragOperationNone;
    }
    
    self.dragDropDestination = item;
    
    if ( [[[info draggingSource] identifier] isEqualToString:@"MyImageBrowserView"])
    {
		
        if ([PIViewController optionKeyIsPressed]) {
            DLog(@"Drag and drop is from browser WITH alt key pressed - copy operation");
            return NSDragOperationCopy;
        } else {
            DLog(@"Drag and drop is from browser - move operation");
            return NSDragOperationMove;
        }
	} else {
        
        if (![PIViewController optionKeyIsPressed])
        {
            DLog(@"Drag and drop is outside source - default to copy operation");
            return NSDragOperationCopy;
        } else {
            DLog(@"Drag and drop is outside source with alt pressed - use move operation");
            return NSDragOperationMove;
        }
	}
    
}

- (IBAction)textTitleChanged:(id)sender {
    DLog(@"textTitleChanged");
    if ([self.outlineView selectedRow] != -1) {
        NSTextField *aTextField =(NSTextField *)sender;
        
        Album *anAlbum =  [self.outlineView itemAtRow:[self.outlineView selectedRow]];
        if ([aTextField.stringValue length]==0 || [aTextField.stringValue isEqualToString:anAlbum.title])
        {
            return;
        }
        NSString *parentFolderPath = [anAlbum.filePath stringByDeletingLastPathComponent];
        NSString *newFilePath = [parentFolderPath stringByAppendingPathComponent:aTextField.stringValue];
        
        
        NSError *error;
        BOOL success = [[NSFileManager defaultManager] moveItemAtPath:anAlbum.filePath toPath:newFilePath error:&error];
        if (!success)
        {
            [[NSApplication sharedApplication] presentError:error];
            //an error occurred when moving so keep the old title
            aTextField.stringValue = anAlbum.title;
        } else {
            [anAlbum userSetTitle:aTextField.stringValue];
            //anAlbum.filePath = newFilePath;
            [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:anAlbum];
        }
    }
}

@end
