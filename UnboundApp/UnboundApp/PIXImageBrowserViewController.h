//
//  PIXImageBrowserViewController.h
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "PIXViewController.h"

@class Album;
@class PIXAlbum;

@interface PIXImageBrowserViewController : PIXViewController

@property (assign) IBOutlet IKImageBrowserView * browserView;
@property (nonatomic, strong) PIXAlbum *album;
@property (nonatomic, readwrite, strong) NSMutableArray * browserData;
@property (nonatomic, readwrite, strong) NSIndexSet * selectedPhotos;

@end
