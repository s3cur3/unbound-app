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
    //    NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Options"];
    //    [theMenu insertItemWithTitle:@"Set As Desktop Background" action:@selector(setDesktopImage:) keyEquivalent:@""atIndex:0];
    //    [NSMenu popUpContextMenu:theMenu withEvent:theEvent forView:self.imageView];
}

@end
