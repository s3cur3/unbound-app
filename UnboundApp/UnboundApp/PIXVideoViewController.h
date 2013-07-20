//
//  PIXVideoViewController.h
//  UnboundApp
//
//  Created by Bob on 7/16/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PIXLeapInputManager.h"

@class PIXPageViewController;
//@class AutoSizingImageView;
@protocol PIXLeapResponder;
@class QTMovieView;
@class PIXVideoImageOverlayView;
@class PIXPlayVideoHUDWindow;

@interface PIXVideoViewController : NSViewController <PIXLeapResponder>
{
    //NSWindow		*overlayWindow;
    
	float contentViewBoundsWidth, contentViewBoundsHeight;
}

@property (nonatomic, assign) PIXPageViewController *pageViewController;
@property (nonatomic, strong) IBOutlet NSScrollView * scrollView;
@property (nonatomic, strong) IBOutlet QTMovieView *movieView;

@property (nonatomic) BOOL isCurrentView;

@property (nonatomic,strong) PIXPlayVideoHUDWindow *overlayWindow;
@property (nonatomic,strong) PIXVideoImageOverlayView *myImageView;

-(void)dismissOverlay;
-(void)displayOverlay;


@end
