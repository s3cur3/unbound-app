//
//  PIXBCAlbumViewController.m
//  UnboundApp
//
//  Created by Bob on 1/16/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXBCAlbumViewController.h"
#import "PIXAlbumCollectionViewItem.h"
#import "PIXAppDelegate.h"
#import "PIXAppDelegate+CoreDataUtils.h"
#import "PIXDefines.h"
#import "PIXAlbum.h"

//#import "CellViewController.h"

@interface PIXBCAlbumViewController ()

@end

@implementation PIXBCAlbumViewController

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
    self.imageContent = [[NSMutableArray alloc] init];
    if ([self albums] == nil) {
        assert(NO);
    }
    
    [self.imageContent addObjectsFromArray:[self albums]];
    //[self.collectionView reloadDataWithItems:self.imageContent emptyCaches:YES];
    
    //[self.collectionView setMaxItemSize:NSSizeFromCGSize(CGSizeMake(300, 200))];
    //[self.collectionView setMinItemSize:NSSizeFromCGSize(CGSizeMake(200, 200))];
    
    [self.collectionView setWantsLayer:YES];
    
    [self.collectionView reloadDataWithItems:self.imageContent emptyCaches:YES];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(albumsChanged:)
                                                 name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM
                                               object:nil];
    
    /*[[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(photosChanged:)
     name:kUB_PHOTOS_LOADED_FROM_FILESYSTEM
     object:[PIXFileSystemDataSource sharedInstance]];*/
    
    
}

-(void)albumsChanged:(NSNotification *)notifcation
{
    [self.imageContent removeAllObjects];
    [self.imageContent addObjectsFromArray:[self albums]];
    [self.collectionView reloadDataWithItems:self.imageContent emptyCaches:NO];
}

-(NSMutableArray *)albums
{
    //return [[PIXFileSystemDataSource sharedInstance] albums];
    return [[[PIXAppDelegate sharedAppDelegate] fetchAllAlbums] mutableCopy];
}

#pragma mark BCCollectionViewDelegate

//CollectionView assumes all cells are the same size and will resize its subviews to this size.
- (NSSize)cellSizeForCollectionView:(BCCollectionView *)collectionView
{
	return NSMakeSize(200, 200);
}

//Return an empty ViewController, this might not be visible to the user immediately
- (NSViewController *)reusableViewControllerForCollectionView:(BCCollectionView *)collectionView
{
	return [[PIXAlbumCollectionViewItem alloc] initWithNibName:@"IconViewPrototype" bundle:nil];
    //return [[CellViewController alloc] init];
}

//The CollectionView is about to display the ViewController. Use this method to populate the ViewController with data
- (void)collectionView:(BCCollectionView *)collectionView willShowViewController:(NSViewController *)viewController forItem:(id)anItem
{
	PIXAlbumCollectionViewItem *cell = (PIXAlbumCollectionViewItem *)viewController;
    [cell setRepresentedObject:anItem];
    //CellViewController *cell = (CellViewController*)viewController;
    //PIXAlbum *anAlbum = (PIXAlbum *)anItem;
	//[cell.imageView setImage:[anAlbum thumbnailImage]];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
