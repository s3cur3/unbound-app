//
//  PIXPhotoCollectionViewController.h
//  UnboundApp
//
//  Created by Ditriol Wei on 14/9/16.
//  Copyright © 2016 Pixite Apps LLC. All rights reserved.
//

#import "PIXCollectionViewController.h"
#import "PIXPageViewController.h"

@class PIXSplitViewController;


@interface PIXPhotoCollectionViewController : PIXCollectionViewController <PIXPageViewControllerDelegate>

@property (nonatomic, strong) PIXAlbum *album;
@property (nonatomic, weak) PIXSplitViewController *splitViewController;

// send a size between 0 and 1 (will be transformed into appropriate sizes)
-(void)setThumbSize:(CGFloat)size;

//PIXPageViewControllerDelegate
//-(void)pagerDidMoveToPhotoAtIndex:(NSUInteger)index;

- (void)selectFirstItem;

- (void)collectionItemViewDoubleClick:(id)sender;

@end

@class PIXAlbum;
@class PIXSplitViewController;

#import "PIXPageViewController.h"
