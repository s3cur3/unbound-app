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

@end

@implementation PIXSidebarViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        //self.topLevelItems = [[[PIXDataSource fileSystemDataSource] albums] mutableCopy];
        self.topLevelItems = [[PIXAppDelegate sharedAppDelegate] fetchAllAlbums];
    }
    
    return self;
}

-(NSArray *)topLevelItems
{
    //[self.outlineView registerForDraggedTypes:[NSArray arrayWithObject: NSURLPboardType]];
    if(_topLevelItems != nil) {return _topLevelItems;}
    
    //[self.view setWantsLayer:YES];
    _topLevelItems = [[PIXAppDelegate sharedAppDelegate] fetchAllAlbums];
    
    return _topLevelItems;
}

//-(void)loadView
//{
//    [super loadView];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(albumsChanged:)
//                                                 name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM
//                                               object:nil];
//}

-(void)willShowPIXView
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                   selector:@selector(albumsChanged:)
                                                       name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM
                                                     object:nil];
    [self scrollToSelectedAlbum];
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
        NSUInteger index = [self.topLevelItems indexOfObject:[self currentlySelectedAlbum]];
        [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
        [self.outlineView scrollRowToVisible:index];
    }
}

-(void)albumsChanged:(NSNotification *)note
{
    _topLevelItems = nil;
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
    return [self.topLevelItems count];
}


- (NSArray *)_childrenForItem:(id)item {
    NSArray *children;
    if (item == nil) {
        children = self.topLevelItems;
    } else {
        children = [NSArray arrayWithObject:[self.topLevelItems lastObject]];
    }
    return children;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return [self.topLevelItems objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return NO;
}

-(id)outlineView:(NSOutlineView *) aView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return [item title];
}

@end
