//
//  PIXVideoViewController.m
//  UnboundApp
//
//  Created by Bob on 7/16/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXVideoViewController.h"
//#import "AutoSizingImageView.h"
#import "PIXVideoImageOverlayView.h"
#import "PIXPlayVideoHUDWindow.h"
#import "PIXPhoto.h"
#import "PIXDefines.h"
#import "PIXAppDelegate.h"
#import "PIXMainWindowController.h"

#import "PIXLeapInputManager.h"
#import <QTKit/QTKit.h>

@interface PIXVideoViewController ()

@property CGFloat startPinchZoom;
@property NSPoint startPinchPosition;

@end

@implementation PIXVideoViewController

// Add C implementations of missing methods that we’ll add
// to the StdMovieUISliderCell class later.
static NSSliderType SliderType(id self, SEL _cmd)
{
    return NSLinearSlider;
}

static NSInteger NumberOfTickMarks(id self, SEL _cmd)
{
    return 0;
}

// rot13, just to be extra safe.
static NSString *ResolveName(NSString *aName)
{
    const char *_string = [aName cStringUsingEncoding:NSASCIIStringEncoding];
    NSUInteger stringLength = [aName length];
    char newString[stringLength+1];
    
    NSUInteger x;
    for(x = 0; x < stringLength; x++)
    {
        unsigned int aCharacter = _string[x];
        
        if( 0x40 < aCharacter && aCharacter < 0x5B ) // A - Z
            newString[x] = (((aCharacter - 0x41) + 0x0D) % 0x1A) + 0x41;
        else if( 0x60 < aCharacter && aCharacter < 0x7B ) // a-z
            newString[x] = (((aCharacter - 0x61) + 0x0D) % 0x1A) + 0x61;
        else  // Not an alpha character
            newString[x] = aCharacter;
    }
    newString[x] = '\0';
    
    return [NSString stringWithCString:newString encoding:NSASCIIStringEncoding];
}

// Add both methods if they aren’t already there. This should makes this
// code safe, even if Apple decides to implement the methods later on.
+ (void)load
{
    Class MovieSliderCell = NSClassFromString(ResolveName(@"FgqZbivrHVFyvqrePryy"));
    
    if (!class_getInstanceMethod(MovieSliderCell, @selector(sliderType)))
    {
        const char *types = [[NSString stringWithFormat:@"%s%s%s",
                              @encode(NSSliderType), @encode(id), @encode(SEL)] UTF8String];
        class_addMethod(MovieSliderCell, @selector(sliderType),
                        (IMP)SliderType, types);
    }
    if (!class_getInstanceMethod(MovieSliderCell, @selector(numberOfTickMarks)))
    {
        const char *types = [[NSString stringWithFormat: @"%s%s%s",
                              @encode(NSInteger), @encode(id), @encode(SEL)] UTF8String];
        class_addMethod(MovieSliderCell, @selector(numberOfTickMarks),
                        (IMP)NumberOfTickMarks, types);
    }
}

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
}

-(void)playMoviePressed:(NSNotification *)notification
{
    DLog(@"playMoviePressed");
    [self dismissOverlay];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieFinishedPlaying:) name:QTMovieDidEndNotification object:nil];//]self.movieView.movie];
    [[self.movieView movie] play];
}
     
-(void)movieFinishedPlaying:(NSNotification *)notification
 {
     if ([self isCurrentView]) {
         [[NSNotificationCenter defaultCenter] removeObserver:self name:QTMovieDidEndNotification object:nil];
         [self displayOverlay];
     }
 }

-(void)dismissOverlay
{
    if (self.overlayWindow!=nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UB_PLAY_MOVIE_PRESSED" object:nil];
        [self.myImageView removeFromSuperview];
        self.myImageView = nil;
        [[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] removeChildWindow:self.overlayWindow];
        self.overlayWindow = nil;
    }
}
-(void)displayOverlay
{
    if (self.overlayWindow!=nil) {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playMoviePressed:) name:@"UB_PLAY_MOVIE_PRESSED" object:nil];
    //self.imageView.delegate = self;
    NSPoint baseOrigin, screenOrigin;
    QTMovieView *mMovieView = self.movieView;
	baseOrigin = NSMakePoint([mMovieView frame].origin.x,
                             [mMovieView frame].origin.y);
    
    // convert our QTMovieView coords from local coords to screen coords
    // which we'll use when creating our NSWindow below
	screenOrigin = [[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] convertBaseToScreen:baseOrigin];
    
    // Create an overlay window which will be attached as a child
    // window to our main window. We will create it directly on top
    // of our main window, so when we draw things they will appear
    // on top of our playing movie
    CGRect movieFrame = [[[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] contentView] frame]; //[self.movieView frame]
    
    self.overlayWindow=[[PIXPlayVideoHUDWindow alloc] initWithContentRect:NSMakeRect(screenOrigin.x,screenOrigin.y,
                                                                   movieFrame.size.width,
                                                                   movieFrame.size.height)
                                              styleMask:NSBorderlessWindowMask
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    [_overlayWindow setOpaque:NO];
    [_overlayWindow setHasShadow:YES];
    
    // specify we can click through the to
    // the window underneath.
    [_overlayWindow setIgnoresMouseEvents:NO];
    [_overlayWindow setAlphaValue:1.0];
    [_overlayWindow setBackgroundColor:[NSColor clearColor]];
    
    NSRect	movieViewBounds, subViewRect;
    
    movieViewBounds = [[[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] contentView] bounds]; //[mMovieView bounds];
    // our imaging NSView will occupy the upper portion
    // of our underlying QTMovieView space
    subViewRect = NSMakeRect(movieViewBounds.origin.x + movieViewBounds.size.width/2,
                             movieViewBounds.origin.y + movieViewBounds.size.height/2,
                             movieViewBounds.size.width/2,
                             movieViewBounds.size.height/2);
    // create a subView for drawing images
	self.myImageView = [[PIXVideoImageOverlayView alloc] initWithFrame:subViewRect];
    [[_overlayWindow contentView] addSubview:self.myImageView];
    
    
    [_overlayWindow orderFront:self];
    
    // add our overlay window as a child window of our main window
    [[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] addChildWindow:_overlayWindow ordered:NSWindowAbove];
    //[[mMovieView window] addChildWindow:overlayWindow ordered:NSWindowAbove];
    
    // mark our image NSView as needing display - this will cause its
    // drawRect routine to get invoked
	[self.myImageView setNeedsDisplay:YES];
}


-(void)dealloc
{
    //self.imageView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissOverlay];
}

-(void)setRepresentedObject:(id)representedObject
{
    //    if (representedObject==nil) {
    //        //[super setRepresentedObject:representedObject];
    //    }
    [self setPhoto:(PIXPhoto *)representedObject];
}

-(void)photoFullsizeChanged:(NSNotification *)notification
{
    //DLog(@"photoFullsizeChanged: %@", notification);
    NSCAssert(notification.object == self.representedObject, @"Notification received for wrong photo");
    //PIXPhoto *aPhoto = (PIXPhoto *)notification.object;
    id obj = notification.object;
    //DLog(@"obj class : %@", [obj class]);
    PIXPhoto *aPhoto = (PIXPhoto *)obj;
    self.movieView.movie = [QTMovie movieWithFile:aPhoto.path error:nil];
//    NSCParameterAssert(aPhoto.fullsizeImage);
//    self.imageView.image = aPhoto.fullsizeImage;
//    [self.imageView setNeedsDisplay:YES];
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
        
        if (self.representedObject!=nil) {
            //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoChanged:) name:PhotoThumbDidChangeNotification object:self.representedObject];
            self.movieView.movie = [QTMovie movieWithFile:newPhoto.path error:nil];
            //[self.imageView setNeedsDisplay];
            //NSCParameterAssert(self.imageView.image);
            //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoFullsizeChanged:) name:PhotoFullsizeDidChangeNotification object:self.representedObject];
        }
        
    } else if (newPhoto!=nil) {
        DLog(@"same non-nil representedObject being set.");
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

-(void)leapPanZoomStart
{
    if(![self.view.window isKeyWindow]) return;
    
    self.startPinchZoom = [self.scrollView magnification];
    
    CGRect bounds = [[self.scrollView contentView] bounds];
    
    self.startPinchPosition= CGPointMake(bounds.origin.x + (bounds.size.width / 2),
                                         bounds.origin.y + (bounds.size.height / 2));
}

-(void)leapPanZoomPosition:(NSPoint)position andScale:(CGFloat)scale
{
    if(![self.view.window isKeyWindow]) return;
    
    
    float magnification = self.startPinchZoom * scale;
    
    
    if(!isnan(magnification))
    {
        [self.scrollView setMagnification:magnification];
    }
    
    // tweak the position depen
    position.x *= 1.0 + (([self.scrollView magnification]-1.0) / 3.0);
    position.y *= 1.0 + (([self.scrollView magnification]-1.0) / 3.0);
    
    CGRect bounds = [[self.scrollView contentView] bounds];
    
    NSPoint scaledPosition = NSMakePoint(position.x * [[self.scrollView contentView] bounds].size.width,
                                         position.y * [[self.scrollView contentView] bounds].size.height);
    
    
    NSPoint newScrollPosition =  NSMakePoint(self.startPinchPosition.x - (bounds.size.width / 2) - scaledPosition.x,
                                             self.startPinchPosition.y - (bounds.size.height / 2) - scaledPosition.y);
    
    
    if(!isnan(newScrollPosition.x) && !isnan(newScrollPosition.y))
    {
        [[self.scrollView documentView] scrollPoint:newScrollPosition];
    }
    
    [self.scrollView setNeedsDisplay:YES];
}



@end
