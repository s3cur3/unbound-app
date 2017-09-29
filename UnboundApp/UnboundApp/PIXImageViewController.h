//
//  PIXImageViewController.h
//  UnboundApp
//
//  Created by Bob on 12/16/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PIXPageViewController;
@class AutoSizingImageView;

@interface PIXImageViewController : NSViewController

@property (nonatomic, assign) PIXPageViewController *pageViewController;
@property (nonatomic, strong) IBOutlet NSScrollView * scrollView;
@property (nonatomic, strong) IBOutlet AutoSizingImageView *imageView;

@property (nonatomic) BOOL isCurrentView;

@end
