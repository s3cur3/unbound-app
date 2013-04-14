//
//  PIXPhotoGridViewController.h
//  UnboundApp
//
//  Created by Bob on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXGridViewController.h"
#import "PIXPageViewController.h"

@class PIXAlbum;
@class PIXSplitViewController;

@interface PIXPhotoGridViewController : PIXGridViewController <PIXPageViewControllerDelegate>

@property (nonatomic, strong) PIXAlbum *album;
@property (nonatomic, weak) PIXSplitViewController *splitViewController;

// send a size between 0 and 1 (will be transformed into appropriate sizes)
-(void)setThumbSize:(CGFloat)size;

//PIXPageViewControllerDelegate
-(void)pagerDidMoveToPhotoAtIndex:(NSUInteger)index;

@end
