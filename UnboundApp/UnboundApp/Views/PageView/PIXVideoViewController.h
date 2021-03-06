//
//  PIXVideoViewController.h
//  UnboundApp
//
//  Created by Bob on 7/16/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PIXPageViewController;
@class AVPlayerView;
@class PIXVideoImageOverlayView;
@class PIXPlayVideoHUDWindow;

@interface PIXVideoViewController : NSViewController
{
    //NSWindow		*overlayWindow;
    
	float contentViewBoundsWidth, contentViewBoundsHeight;
}

@property (nonatomic, assign) PIXPageViewController *pageViewController;
@property (nonatomic, strong) IBOutlet NSScrollView * scrollView;
@property (nonatomic, strong) IBOutlet AVPlayerView *movieView;

@property (nonatomic) BOOL isCurrentView;

@property (nonatomic,strong) PIXPlayVideoHUDWindow *overlayWindow;
@property (nonatomic,strong) PIXVideoImageOverlayView *myImageView;

-(void)dismissOverlay;
-(void)displayOverlay;

-(BOOL)movieIsPlaying;

-(void)playMoviePressed:(NSNotification *)notification;


@end
