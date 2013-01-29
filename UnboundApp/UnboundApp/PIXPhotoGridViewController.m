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

@interface PIXPhotoGridViewController ()

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
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadItems:) name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
    
    //
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(albumsChanged:)
//                                                 name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM
//                                               object:nil];
    
    
}


-(void)setAlbum:(id)album
{
    BOOL firstLoad = NO;
    //The first time album is set, no need to reload
    if (_album==nil && album!=nil)
    {
        firstLoad = YES;
    }
    _album = album;
    if (album) {
        [[[PIXAppDelegate sharedAppDelegate] window] setTitle:[self.album title]];
        if (firstLoad == NO)
        {
            self.items = [self fetchItems];
            [self.gridView reloadData];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadItems:) name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
        }
    }
}

-(NSMutableArray *)fetchItems
{
    //return [[[PIXAppDelegate sharedAppDelegate] fetchAllPhotos] mutableCopy];
    return [NSMutableArray arrayWithArray:[self.album.photos array]];
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

- (void)gridView:(CNGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    CNLog(@"didDoubleClickItemAtIndex: %li", index);
    [self showPageControllerForIndex:index];
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

@end
