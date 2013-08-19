//
//  AutoSizingVideoView.m
//  Unbound5
//
//  Created by Bob on 10/9/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "AutoSizingVideoView.h"
//#import "PIXPageViewController.h"


@implementation AutoSizingVideoView

// The imageView should always be the same size as the enclosing scrollview regardless of
// the bounds of the clipView. We need to do this manually because auto-layout would try
// to size the view to the bounds of the clipview effectively nulling the magnification.
//
//- (void)setFrameSize:(NSSize)newSize {
//    NSScrollView *scrollView = [self enclosingScrollView];
//    if (scrollView) {
//        [super setFrameSize:scrollView.frame.size];
//    } else {
//        [super setFrameSize:newSize];
//    }
//}


-(void)mouseDown:(NSEvent *)theEvent{
    DLog(@"mouseDown:%@", theEvent);
    //[super mouseDown:theEvent];
    //[[self nextResponder] mouseDown:theEvent];
    
    if (theEvent.clickCount ==2) {
        [super mouseDown:theEvent];
//        NSScrollView *scrollView = [self enclosingScrollView];
//        CGFloat curMagnification = [scrollView magnification];
//        CGFloat maxMagnification = [scrollView maxMagnification];
//        if (maxMagnification<=0) {
//            maxMagnification = 4.0f;
//        }
//        CGFloat thresholdMagnification = maxMagnification/2.0f;
//        DLog(@"double click received. curMagnification : %f - maxMagnification : %f", curMagnification, maxMagnification);
//        if (curMagnification < thresholdMagnification) {
//            DLog(@"zooming to max magnification : %f", maxMagnification);
//            
//            [scrollView setMagnification:maxMagnification centeredAtPoint:(NSPoint)theEvent.locationInWindow];
//            
//        } else {
//            [scrollView magnifyToFitRect:self.bounds];
//        }
    } else {
        [super mouseDown:theEvent];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UB_PLAY_MOVIE_PRESSED" object:nil];
        
    }
    
    
}

//- (void)mouseDown:(NSEvent *)theEvent {}
- (void)rightMouseDown:(NSEvent *)theEvent {DLog(@"%@", theEvent);}
- (void)otherMouseDown:(NSEvent *)theEvent {DLog(@"%@", theEvent);}
- (void)mouseUp:(NSEvent *)theEvent {DLog(@"%@", theEvent);}
- (void)otherMouseUp:(NSEvent *)theEvent {DLog(@"%@", theEvent);}
- (void)rightMouseUp:(NSEvent *)theEvent {DLog(@"%@", theEvent);}
- (void)scrollWheel:(NSEvent *)theEvent {

    //DLog(@"%@", theEvent);

    if ([self.pageViewController movieIsPlaying] == YES) {
        //DLog(@"movieIsPlaying is YES");
        return;
    } else {
        PIXPageViewController *aPageVC = (PIXPageViewController *)[[theEvent window] firstResponder];
        DLog(@"nextResponder : %@", self.nextResponder);
        [self.nextResponder scrollWheel:theEvent];
    }
    
}
- (NSMenu *)menuForEvent:(NSEvent *)theEvent {DLog(@"%@", theEvent); return nil; }
- (BOOL)acceptsFirstResponder { return NO; }


@end
