//
//  PIXSidebarViewController.m
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXSidebarViewController.h"
#import "PIXDataSource.h"
#import "PIXAppDelegate.h"
#import "PIXFileManager.h"
#import "PIXAppDelegate+CoreDataUtils.h"
#import "PIXSidebarTableCellView.h"
#import "PIXSplitViewController.h"
#import "PIXPhotoGridViewController.h"
#import "PIXFileParser.h"
#import "PIXAlbum.h"
#import "PIXPhoto.h"
#import "PIXDefines.h"

@interface PIXSidebarViewController ()

@property (nonatomic, strong) NSArray * searchedAlbums;
@property (nonatomic, strong) IBOutlet NSSearchField * searchField;
@property (nonatomic, strong) NSString * lastSearch;

@end

@implementation PIXSidebarViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        //self.topLevelItems = [[[PIXDataSource fileSystemDataSource] albums] mutableCopy];
    }
    
    return self;
}


-(NSArray *)albums
{
    //[self.outlineView registerForDraggedTypes:[NSArray arrayWithObject: NSURLPboardType]];
    if(_albums != nil) {return _albums;}
    
    //[self.view setWantsLayer:YES];
    _albums = [[PIXAppDelegate sharedAppDelegate] fetchAllAlbums];
    
    return _albums;
}


- (void)controlTextDidChange:(NSNotification *)aNotification
{
    [self updateSearch];
}

-(void)updateSearch
{
	
    NSString * searchText = [self.searchField stringValue];
    if(searchText != nil && [searchText length] > 0)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.title CONTAINS[cd] %@", searchText];
        
        if([self.albums count] > 0)
        {
            // if this search is more narrow than the last filter then re-filter based on the last set
            // (this happens while typing)
            
            if(self.lastSearch != nil && [searchText rangeOfString:self.lastSearch].length != 0)
            {
                self.searchedAlbums = [self.searchedAlbums filteredArrayUsingPredicate:predicate];
            }
            
            else
            {
                self.searchedAlbums = [self.albums filteredArrayUsingPredicate:predicate];
            }
            
            self.lastSearch = searchText;
        }
    }
    
    else
    {
        self.searchedAlbums = nil;
        self.lastSearch = nil;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:searchText forKey:@"PIX_AlbumSearchString"];
        
    [self.outlineView reloadData];
    [self scrollToSelectedAlbum];
	
}


-(void)willShowPIXView
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                   selector:@selector(albumsChanged:)
                                                       name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM
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
    
    // this will be called by updateSearch so no need to call  it here
    //[self scrollToSelectedAlbum];
}





-(void)awakeFromNib
{
    [super awakeFromNib];

    [self.outlineView registerForDraggedTypes:[NSArray arrayWithObject: NSURLPboardType]];
    
    ///[self.outlineView setWantsLayer:NO];
}

-(void)scrollToSelectedAlbum
{
    if ([self currentlySelectedAlbum] != nil)
    {
        NSUInteger index = NSNotFound;
        
        if(self.searchedAlbums)
        {
            index = [self.searchedAlbums indexOfObject:[self currentlySelectedAlbum]];
        }
        
        else
        {
            index = [self.albums indexOfObject:[self currentlySelectedAlbum]];
        }
        
        if(index != NSNotFound)
        {
            [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
            [self.outlineView scrollRowToVisible:index];
        }
    }
}

-(void)albumsChanged:(NSNotification *)note
{
    
    self.albums = nil;
    
    //[self.outlineView.enclosingScrollView setWantsLayer:NO];
    
    [self.outlineView reloadData];
    [self scrollToSelectedAlbum];
    
    
}

-(Album *)currentlySelectedAlbum
{
    return self.splitViewController.selectedAlbum;
}

/*-(void)setSelectedAlbum:(Album *)anAlbum
{
    [self setSelectedAlbum:anAlbum shouldEdit:NO];
}

-(void)setSelectedAlbum:(Album *)anAlbum shouldEdit:(BOOL)isEditing
{
    _selectedAlbum = anAlbum;
    if (_selectedAlbum!=nil)
    {
        NSUInteger index = [self.topLevelItems indexOfObject:self.selectedAlbum];
        [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
        [self.outlineView scrollRowToVisible:index];
        if (isEditing)
        {
            //set the newly selected albums's label to editing mode
            [self.outlineView editColumn:0 row:index
                               withEvent:nil select:YES];
        }
        
        
    }
}

-(void)setSelectedAlbumAndEdit:(Album *)anAlbum
{
    [self setSelectedAlbum:anAlbum shouldEdit:YES];
}*/

//Drag and Drop Support

-(BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index
{
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
    
//    for (NSString * path in files)
//    {
//        [pathsToPaste addObject:@{@"source" : path, @"destination" : destPath}];
//    }

    DLog(@"Sidebar acccepting drop with source : %@, option key presssed : %@", [info draggingSource], ([PIXViewController optionKeyIsPressed] ? @"YES" : @"NO"));
    //TODO: find out why this doesn't work
    if ( [[info draggingSource] class] == [PIXPhotoGridViewController class])
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
    if (index != -1)
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
    
    if ( [[info draggingSource] class] == [PIXPhotoGridViewController class])
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
            return;
        } else {
            //[[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:anAlbum];
            DLog(@"Album was renamed successfuly : \"%@\"", anAlbum.path);
        }
    }
}


-(void)dealloc
{
    self.outlineView.delegate = nil;
    self.outlineView.dataSource = nil;
    self.splitViewController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
}


@end

@implementation PIXSidebarViewController(NSOutlineViewDelegate)

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    PIXSidebarTableCellView *result = [outlineView makeViewWithIdentifier:@"MainCell" owner:self];
    result.album = (PIXAlbum *)item;
    return result;
}

-(void)outlineViewSelectionDidChange:(NSNotification *)notification {
    if ([self.outlineView selectedRow] != -1) {

        PIXAlbum *anAlbum =  [self.outlineView itemAtRow:[self.outlineView selectedRow]];
        if (anAlbum!=nil)
        {
            DLog(@"New album selected");
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
