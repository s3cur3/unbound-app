/*
     File: AutoSizingImageView.m 
 Abstract: Main image view properly sized within its scroll view.
  
  Version: 1.1 
  
 */

#import "AutoSizingImageView.h"

#import "PIXLeapInputManager.h"

//#import "ImageViewController.h"
//#import "PageViewController.h"

@interface AutoSizingImageView () <leapResponder>

@end

@implementation AutoSizingImageView 

// The imageView should always be the same size as the enclosing scrollview regardless of
// the bounds of the clipView. We need to do this manually because auto-layout would try
// to size the view to the bounds of the clipview effectively nulling the magnification.
//
- (void)setFrameSize:(NSSize)newSize {

    NSScrollView *scrollView = [self enclosingScrollView];
    if (scrollView) {
        [super setFrameSize:scrollView.frame.size];
    } else {
        [super setFrameSize:newSize];
    }
}

-(void)rightMouseDown:(NSEvent *)theEvent {
    DLog(@"rightMouseDown:%@", theEvent);
    [[self nextResponder] rightMouseDown:theEvent];
}

-(void)mouseDown:(NSEvent *)theEvent{
    DLog(@"mouseDown:%@", theEvent);
    if (theEvent.clickCount ==2) {
        NSScrollView *scrollView = [self enclosingScrollView];
        CGFloat curMagnification = [scrollView magnification];
        CGFloat maxMagnification = 3.0f;//[scrollView maxMagnification];
        DLog(@"double click received. curMagnification : %f - maxMagnification : %f", curMagnification, maxMagnification);
        if (curMagnification != maxMagnification) {
            DLog(@"zooming to max magnification : %f", maxMagnification);
            [scrollView setMagnification:maxMagnification];
        } else {
            [scrollView setMagnification:1.0];
        }
        
    } else {
        [[self nextResponder] mouseDown:theEvent];
    }
}

@end
