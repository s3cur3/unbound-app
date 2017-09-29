//
//  AutoSizingVideoView.h
//  Unbound5
//
//  Created by Bob on 10/9/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXVideoViewController.h"
#import <AVKit/AVKit.h>

@interface AutoSizingVideoView : AVPlayerView

@property (nonatomic, weak) IBOutlet PIXVideoViewController *pageViewController;

@end
