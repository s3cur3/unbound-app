//
//  PIXPhotoGridViewController.h
//  UnboundApp
//
//  Created by Bob on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXGridViewController.h"

@class PIXAlbum;

@interface PIXPhotoGridViewController : PIXGridViewController

@property (nonatomic, strong) PIXAlbum *album;

// send a size between 0 and 1 (will be transformed into appropriate sizes)
-(void)setThumbSize:(CGFloat)size;

@end
