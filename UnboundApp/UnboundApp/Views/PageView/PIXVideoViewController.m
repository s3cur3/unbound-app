//
//  PIXVideoViewController.m
//  UnboundApp
//
//  Created by Bob on 7/16/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXVideoViewController.h"
#import "PIXVideoImageOverlayView.h"
#import "PIXPlayVideoHUDWindow.h"
#import "PIXPhoto.h"
#import "PIXDefines.h"
#import "PIXAppDelegate.h"
#import "PIXMainWindowController.h"
#import "PIXPageViewController.h"
#import <AVKit/AVKit.h>

@interface PIXVideoViewController ()

@property CGFloat startPinchZoom;
@property NSPoint startPinchPosition;
@property AVPlayer *player;

@end

@implementation PIXVideoViewController

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
    //[self displayOverlay];
    DLog(@"awakeFromNib");
}

- (void)viewWillAppear {
    [super viewWillAppear];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(movieFinishedPlaying:)
                                               name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:nil];
}

- (void)viewWillDisappear {
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:AVPlayerItemDidPlayToEndTimeNotification
                                                object:nil];
    [super viewWillDisappear];
}



-(void)playMoviePressed:(NSNotification *)notification
{
    DLog(@"Player failed to load video. %@", self.player);

    DLog(@"playMoviePressed");
    [[self pageViewController] tryFadeControls];
    [self dismissOverlay];

    if(self.player.rate == 0) {
        // start over if we're at the end
        if (self.player.currentTime.value >= self.player.currentItem.duration.value) {
            [self.player seekToTime:CMTimeMake(0, 1)];
        }

        [self.player play];
    }
    
    else
    {
        [self.player pause];
    }
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context {
    if (object == self.player && [@"rate" isEqualToString:keyPath]) {
        DLog(@"Received notification for rate change. rate=%f", self.player.rate);
        if (self.player.rate == 0) {
            [self movieFinishedPlaying:nil];
        }
    } else if (object == self.player && [@"status" isEqualToString:keyPath]) {
        DLog(@"Received notification for player status.");
        switch (self.player.status) {
            case AVPlayerStatusReadyToPlay: {
                DLog(@"Player is ready to play, pausing.")
                [self.player pause];
                [self.player seekToTime:CMTimeMake(0, 1)];
                break;
            }

            case AVPlayerStatusFailed: {
                DLog(@"Player failed to load video. %@", self.player.error)
                break;
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)keyDown:(NSEvent *)event {
    if (event.type == NSKeyDown && [event.characters isEqualToString:@"\r"]) {
        [self playMoviePressed:nil];
    } else {
        [super keyDown:event];
    }
}


-(void)movieFinishedPlaying:(NSNotification *)notification
 {
     if ([self isCurrentView]) {
         [self displayOverlay];
     }
 }

- (void)scrollWheel:(NSEvent *)theEvent {
    DLog(@"%@", theEvent);
}

-(void)dismissOverlay
{
    if (self.overlayWindow!=nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UB_PLAY_MOVIE_PRESSED" object:nil];
        [self.myImageView setHidden:YES];
        [self.myImageView setNeedsDisplay:YES];
        [self.myImageView removeFromSuperview];
        self.myImageView = nil;
        [[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] removeChildWindow:self.overlayWindow];
        [self.overlayWindow close];
        self.overlayWindow = nil;
        [[[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] contentView] setNeedsDisplay:YES];
    }
}
-(void)displayOverlay
{
    if (self.overlayWindow!=nil) {
        return;
    }
    if (self.pageViewController.pageController.selectedViewController != self) {
        DLog(@"not selected vc");
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playMoviePressed:) name:@"UB_PLAY_MOVIE_PRESSED" object:nil];
    //self.imageView.delegate = self;
    NSPoint baseOrigin, screenOrigin;
    AVPlayerView *mMovieView = self.movieView;
	baseOrigin = NSMakePoint([mMovieView frame].origin.x,
                             [mMovieView frame].origin.y);
    
    // convert our QTMovieView coords from local coords to screen coords
    // which we'll use when creating our NSWindow below
	screenOrigin = [[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] convertBaseToScreen:baseOrigin];
   // NSLog(@"screenOrigin : x: %f y: %f , baseOrigin : x: %f y: %f ", screenOrigin.x, screenOrigin.y, baseOrigin.x, baseOrigin.y);
    
    //NSLog(@"mMovieView : %@", mMovieView);
    // Create an overlay window which will be attached as a child
    // window to our main window. We will create it directly on top
    // of our main window, so when we draw things they will appear
    // on top of our playing movie
    //GRect movieFrame = [[[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] contentView] frame]; //[self.movieView frame]
    CGRect movieFrame = [self.movieView frame];
//    self.overlayWindow=[[PIXPlayVideoHUDWindow alloc] initWithContentRect:NSMakeRect(screenOrigin.x,screenOrigin.y,
//                                                                   movieFrame.size.width,
//                                                                   movieFrame.size.height)
//                                              styleMask:NSBorderlessWindowMask
//                                                backing:NSBackingStoreBuffered
//                                                  defer:NO];
    
    //NSImage *playButtonImage = [NSImage imageNamed:@"playbutton"];
    //[playButtonImage setScalesWhenResized:YES];
    //CGRect playButtonRect = CGRectMake(CGRectGetMidX(movieFrame)-100.0, CGRectGetMidY(movieFrame)-100.0, 200.0, 200.0);//
    
//    CGRect playButtonRect = CGRectApplyAffineTransform(imageRect, CGAffineTransformMakeScale(0.33, 0.33));
//    [playButtonRect drawInRect:playButtonRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    
    
    
    CGRect playButtonWindowFrame = NSMakeRect((screenOrigin.x+(movieFrame.size.width/2))-100.0,
                                        (screenOrigin.y+(movieFrame.size.height/2))-100.0,
                                        200.0,
                                        200.0);
    
//    CGRect playButtonViewFrame = NSMakeRect((screenOrigin.x+(movieFrame.size.width/2))-100.0,
//                                        (screenOrigin.y+(movieFrame.size.height/2))-100.0,
//                                        200.0,
//                                        200.0);
    
    
    CGRect playButtonViewFrame = NSMakeRect(0.0f,
                                            0.0f,
                                            200.0f,
                                            200.0f);
    self.overlayWindow=[[PIXPlayVideoHUDWindow alloc] initWithContentRect:playButtonWindowFrame
                                                                styleMask:NSBorderlessWindowMask
                                                                  backing:NSBackingStoreBuffered
                                                                    defer:NO];
    [self.overlayWindow setParentView:self.pageViewController.pageController.selectedViewController.view];
    [_overlayWindow setOpaque:NO];
    [_overlayWindow setHasShadow:YES];
    
    // specify we can click through the to
    // the window underneath.
    [_overlayWindow setIgnoresMouseEvents:NO];
    //[_overlayWindow setAlphaValue:0.3];
    //[_overlayWindow setBackgroundColor:[NSColor clearColor]];
    
//    NSRect	movieViewBounds, subViewRect;
//    
//    movieViewBounds = [[[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] contentView] bounds]; //[mMovieView bounds];
//    // our imaging NSView will occupy the upper portion
//    // of our underlying QTMovieView space
//    subViewRect = NSMakeRect(movieViewBounds.origin.x + movieViewBounds.size.width/2,
//                             movieViewBounds.origin.y + movieViewBounds.size.height/2,
//                             movieViewBounds.size.width/2,
//                             movieViewBounds.size.height/2);
    // create a subView for drawing images
	self.myImageView = [[PIXVideoImageOverlayView alloc] initWithFrame:playButtonViewFrame];
    [[_overlayWindow contentView] addSubview:self.myImageView];
    
    
    [_overlayWindow orderFront:self];
    
    // add our overlay window as a child window of our main window
    [[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] addChildWindow:_overlayWindow ordered:NSWindowAbove];
    //[[mMovieView window] addChildWindow:overlayWindow ordered:NSWindowAbove];
    
    // mark our image NSView as needing display - this will cause its
    // drawRect routine to get invoked
	[self.myImageView setNeedsDisplay:YES];
}


-(void)dealloc {
    [self dismissOverlay];
    self.player = nil;
}

-(void)setRepresentedObject:(id)representedObject {
    [self setPhoto:(PIXPhoto *)representedObject];
}

- (AVPlayer *)player {
    return self.movieView.player;
}

-(void)setPlayer:(AVPlayer *)player {
    if (self.movieView.player != nil) {
        [self.movieView.player removeObserver:self forKeyPath:@"rate"];
        [self.movieView.player removeObserver:self forKeyPath:@"status"];
    }

    self.movieView.player = player;

    if (player != nil) {
        [self.movieView.player addObserver:self forKeyPath:@"status" options:nil context:nil];
        [self.movieView.player addObserver:self forKeyPath:@"rate" options:nil context:nil];
    }
}

-(void)photoFullsizeChanged:(NSNotification *)notification
{
    //DLog(@"photoFullsizeChanged: %@", notification);
    NSCAssert(notification.object == self.representedObject, @"Notification received for wrong photo");
    //PIXPhoto *aPhoto = (PIXPhoto *)notification.object;
    id obj = notification.object;
    //DLog(@"obj class : %@", [obj class]);
    PIXPhoto *aPhoto = (PIXPhoto *)obj;

    self.player = [AVPlayer playerWithURL:aPhoto.filePath];
}

-(void)setPhoto:(PIXPhoto *)newPhoto
{
    if (self.representedObject != newPhoto)
    {
        if (self.representedObject!=nil)
        {
            //[[NSNotificationCenter defaultCenter] removeObserver:self name:PhotoThumbDidChangeNotification object:self.representedObject];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:PhotoFullsizeDidChangeNotification object:self.representedObject];
            //            if (newPhoto!=nil) {
            //                [self.representedObject cancelFullsizeLoading];
            //            }
        }
        
        [super setRepresentedObject:newPhoto];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(photoFullsizeChanged:)
                                                   name:PhotoFullsizeDidChangeNotification
                                                 object:self.representedObject];

        if (self.representedObject!=nil) {
            self.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:newPhoto.path]];
        }
        
    }
    
}


-(void)setIsCurrentView:(BOOL)value
{
    if(_isCurrentView != value)
    {
        _isCurrentView = value;
    }
    if (!_isCurrentView) {
        [self dismissOverlay];
    } else {
        [self displayOverlay];
    }
}

-(BOOL)movieIsPlaying
{
    float rate = 0.0f;
    if (self.player) {
        rate = self.player.rate;
    }
    //DLog(@"rate : %f, isIdle : %d", rate, isIdle);
    BOOL isPlaying = [[NSNumber numberWithFloat:rate] boolValue];
    return isPlaying;
}




@end
