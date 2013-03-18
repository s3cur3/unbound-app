/*
     File: AutoSizingImageView.m 
 Abstract: Main image view properly sized within its scroll view.
  
  Version: 1.1 
  
 */

#import "AutoSizingImageView.h"
//#import "ImageViewController.h"
//#import "PageViewController.h"

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
    
    [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
}

-(void)keyDown:(NSEvent *)theEvent
{
    DLog(@"keyDown : %@", theEvent);
	// get the event and the modifiers
    NSString * characters = [theEvent charactersIgnoringModifiers];
    unichar event = [characters characterAtIndex:0];
    
    switch (event)
    {
        case ' ':
            
            break;
            
        default:
            [super keyDown:theEvent];
    }
}

- (NSView *)hitTest:(NSPoint)aPoint
{
    // don't allow any mouse clicks for subviews in this NSBox
    if(NSPointInRect(aPoint,[self convertRect:[self bounds] toView:[self superview]])) {
		return self;
	} else {
		return nil;
	}
}

-(void)rightMouseDown:(NSEvent *)theEvent {
    DLog(@"rightMouseDown:%@", theEvent);
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(rightMouseDown:)]) {
        [self.delegate performSelector:@selector(rightMouseDown:) withObject:theEvent];
    }
}

-(void)mouseDown:(NSEvent *)theEvent {
	[super mouseDown:theEvent];
    
}
/*- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
{
    NSString*   const   character   =   [theEvent charactersIgnoringModifiers];
    unichar     const   code        =   [character characterAtIndex:0];
    
    switch (code)
    {
        case NSLeftArrowFunctionKey:
        {
            [[self.delegate pageViewController] performSelector:@selector(moveToPreviousPage)];
            break;
        }
        case NSRightArrowFunctionKey:
        {
            [[self.delegate pageViewController] performSelector:@selector(moveToNextPage)];
            break;
        }
    }
    
    return YES;
}*/

-(void)setDesktopImage:(id)sender
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(setDesktopImage:)]) {
        [self.delegate performSelector:@selector(setDesktopImage:) withObject:sender];
    }
}


@end
