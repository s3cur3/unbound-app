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
#import "PIXAppDelegate+CoreDataUtils.h"
#import "PIXSidebarTableCellView.h"
#import "PIXSplitViewController.h"
#import "Album.h"
#import "PIXAlbum.h"
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
    /*[self.outlineView reloadData];
    if ([self currentlySelectedAlbum] != nil)
    {
        NSUInteger index = [self.topLevelItems indexOfObject:[self currentlySelectedAlbum]];
        [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
        [self.outlineView scrollRowToVisible:index];
    }*/
    //[self.outlineView registerForDraggedTypes:[NSArray arrayWithObject: NSURLPboardType]];
    
    //[self.view setWantsLayer:YES];
    
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
