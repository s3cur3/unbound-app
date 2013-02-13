//
//  PIXPhotoGridViewController.m
//  UnboundApp
//
//  Created by Bob on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXPhotoGridViewController.h"
#import "PIXAppDelegate.h"
#import "PIXAppDelegate+CoreDataUtils.h"
#import "PIXAlbum.h"
#import "PIXPageViewController.h"
#import "PIXNavigationController.h"
#import "PIXDefines.h"
#import "PIXPhotoGridViewItem.h"

@interface PIXPhotoGridViewController ()

@property(nonatomic,strong) NSMutableArray * selectedItems;

@end

@implementation PIXPhotoGridViewController

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
    [super awakeFromNib];
    [self performSelector:@selector(updateAlbum) withObject:nil afterDelay:0.1];

//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadItems:) name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
    
    //
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(albumsChanged:)
//                                                 name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM
//                                               object:nil];
    
}


-(void)setAlbum:(id)album
{
  
    
    if (album != _album)
    {
        _album = album;
        [[[PIXAppDelegate sharedAppDelegate] window] setTitle:[self.album title]];
        
        [self updateAlbum];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAlbum) name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
        
    }
}

-(void)updateAlbum
{
    self.items = [self fetchItems];
    [self.gridView reloadData];
    [self.gridViewTitle setStringValue:[NSString stringWithFormat:@"%ld photos", [self.items count]]];
    
}

-(NSMutableArray *)fetchItems
{
    //return [[[PIXAppDelegate sharedAppDelegate] fetchAllPhotos] mutableCopy];
    return [NSMutableArray arrayWithArray:[self.album.photos array]];
}

- (CNGridViewItem *)gridView:(CNGridView *)gridView itemAtIndex:(NSInteger)index inSection:(NSInteger)section
{
    static NSString *reuseIdentifier = @"CNGridViewItem";
    
    PIXPhotoGridViewItem *item = [gridView dequeueReusableItemWithIdentifier:reuseIdentifier];
    if (item == nil) {
        item = [[PIXPhotoGridViewItem alloc] initWithLayout:nil reuseIdentifier:reuseIdentifier];
    }
    
    //    NSDictionary *contentDict = [self.items objectAtIndex:index];
    //    item.itemTitle = [NSString stringWithFormat:@"Item: %lu", index];
    //    item.itemImage = [contentDict objectForKey:kContentImageKey];
    
    PIXPhoto * photo = [self.items objectAtIndex:index];
    [item setPhoto:photo];
    return item;
}

-(void)showPageControllerForIndex:(NSUInteger)index
{
    PIXPageViewController *pageViewController = [[PIXPageViewController alloc] initWithNibName:@"PIXPageViewController" bundle:nil];
    pageViewController.album = self.album;
    pageViewController.initialSelectedObject = [self.album.photos objectAtIndex:index];
    [self.navigationViewController pushViewController:pageViewController];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNGridView Delegate

//- (void)gridView:(CNGridView *)gridView didClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
//{
//    CNLog(@"didClickItemAtIndex: %li", index);
//}

//- (void)gridView:(CNGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
//{
//    CNLog(@"didDoubleClickItemAtIndex: %li", index);
//    [self showPageControllerForIndex:index];
//}

- (void)gridView:(CNGridView *)gridView rightMouseButtonClickedOnItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event
{
    PIXPhoto * itemClicked = [self.items objectAtIndex:index];
    NSMenu *contextMenu = [self menuForObject:itemClicked];
    [NSMenu popUpContextMenu:contextMenu withEvent:event forView:self.view];
    
    // can use this and the self.selectedAlbum array to build a right click menu here
    
    DLog(@"rightMouseButtonClickedOnItemAtIndex: %li", index);
}

//- (void)gridView:(CNGridView *)gridView rightMouseButtonClickedOnItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
//{
//    CNLog(@"rightMouseButtonClickedOnItemAtIndex: %li", index);
//}
//
//- (void)gridView:(CNGridView *)gridView didSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
//{
//    CNLog(@"didSelectItemAtIndex: %li", index);
//}
//
//- (void)gridView:(CNGridView *)gridView didDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
//{
//    CNLog(@"didDeselectItemAtIndex: %li", index);
//}



- (void)gridView:(CNGridView *)gridView didSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [self.selectedItems addObject:[self.items objectAtIndex:index]];
    
    [self updateToolbar];
}

- (void)gridView:(CNGridView *)gridView didDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [self.selectedItems removeObject:[self.items objectAtIndex:index]];
    
    [self updateToolbar];
}

- (void)gridViewDidDeselectAllItems:(CNGridView *)gridView
{
    [self.selectedItems removeAllObjects];
    [self updateToolbar];
}


-(void)updateToolbar
{
    if([self.selectedItems count] > 0)
    {
        if([self.selectedItems count] > 1)
        {
            [self.toolbarTitle setStringValue:[NSString stringWithFormat:@"%ld photos selected", (unsigned long)[self.selectedItems count]]];
        }
        
        else
        {
            [self.toolbarTitle setStringValue:@"1 photo selected"];
        }
        
        [self showToolbar:YES];
    }
    
    else
    {
        [self hideToolbar:YES];
    }
}

-(NSMutableArray *)selectedItems
{
    if(_selectedItems != nil) return _selectedItems;
    
    _selectedItems = [NSMutableArray new];
    
    return _selectedItems;
}

@end
