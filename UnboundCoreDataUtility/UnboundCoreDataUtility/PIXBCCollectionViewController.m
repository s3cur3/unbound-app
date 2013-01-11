//
//  PIXBCCollectionViewController.m
//  UnboundCoreDataUtility
//
//  Created by Bob on 1/10/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXBCCollectionViewController.h"
#import "BCCollectionView.h"
#import "CellViewController.h"
#import "PIXAlbumCollectionViewItem.h"
#import "PIXAppDelegate+CoreDataUtils.h"
#import "PIXAppDelegate.h"

@interface PIXBCCollectionViewController ()

@end

@implementation PIXBCCollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(NSMutableArray *)albums
{
    if (_albums == nil)
    {
        NSArray *someAlbums = [[PIXAppDelegate sharedAppDelegate] fetchAllAlbums];
        if (someAlbums.count) {
            _albums = [someAlbums mutableCopy];
        }
    }
    return _albums;
}


- (void)awakeFromNib
{
	[super awakeFromNib];
	
//	_imageContent = [[NSMutableArray alloc] init];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameQuickLookTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameBluetoothTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameIChatTheaterTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameSlideshowTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameActionTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameSmartBadgeTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameIconViewTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameListViewTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameColumnViewTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameFlowViewTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNamePathTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameInvalidDataFreestandingTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameLockLockedTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameLockUnlockedTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameGoRightTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameGoLeftTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameRightFacingTriangleTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameLeftFacingTriangleTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameAddTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameRemoveTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameRevealFreestandingTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameFollowLinkFreestandingTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameEnterFullScreenTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameExitFullScreenTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameStopProgressTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameRefreshTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameRefreshFreestandingTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameBonjour]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameComputer]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameFolderBurnable]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameFolderSmart]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameFolder]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameNetwork]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameDotMac]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameMobileMe]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameMultipleDocuments]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameUserAccounts]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNamePreferencesGeneral]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameAdvanced]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameInfo]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameFontPanel]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameColorPanel]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameUser]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameUserGroup]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameEveryone]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameUserGuest]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameMenuOnStateTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameMenuMixedStateTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameApplicationIcon]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameTrashEmpty]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameTrashFull]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameHomeTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameBookmarksTemplate]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameCaution]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameStatusAvailable]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameStatusPartiallyAvailable]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameStatusUnavailable]];
//	[_imageContent addObject:[NSImage imageNamed:NSImageNameStatusNone]];
	
	//[self.collectionView reloadDataWithItems:_imageContent emptyCaches:NO];
    
    [self.collectionView reloadDataWithItems:self.albums emptyCaches:NO];
}


//CollectionView assumes all cells are the same size and will resize its subviews to this size.
- (NSSize)cellSizeForCollectionView:(BCCollectionView *)collectionView
{
	return NSMakeSize(200, 200);
}

//Return an empty ViewController, this might not be visible to the user immediately
- (NSViewController *)reusableViewControllerForCollectionView:(BCCollectionView *)collectionView
{
	//return [[CellViewController alloc] init];
    return [[PIXAlbumCollectionViewItem alloc] initWithNibName:@"IconViewPrototype" bundle:nil];
}

//The CollectionView is about to display the ViewController. Use this method to populate the ViewController with data
- (void)collectionView:(BCCollectionView *)collectionView willShowViewController:(NSViewController *)viewController forItem:(id)anItem
{
	PIXAlbumCollectionViewItem *cell = (PIXAlbumCollectionViewItem*)viewController;
    cell.representedObject = anItem;
	//[cell.imageView setImage:anItem];
}

@end
