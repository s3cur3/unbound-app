//
//  PIXVideoImageOverlayView.m
//  UnboundApp
//
//  Created by Bob on 7/18/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXVideoImageOverlayView.h"
#import "PIXPlayVideoHUDWindow.h"

@implementation PIXVideoImageOverlayView


-(void)mouseDown:(NSEvent *)theEvent
{
    DLog(@"mouseDown");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UB_PLAY_MOVIE_PRESSED" object:nil];
}

//-(void)mouseEntered:(NSEvent *)theEvent
//{
//    DLog(@"mouseEntered");
//    //[(PIXPlayVideoHUDWindow *)[self window] setHasMouse:YES];
//}

//-(void)mouseMoved:(NSEvent *)theEvent
//{
//    //[(PIXPlayVideoHUDWindow *)[self window] setHasMouse:YES];
//}


//-(void)mouseExited:(NSEvent *)theEvent
//{
//    DLog(@"mouseExited");
//    //[(PIXPlayVideoHUDWindow *)[self window] setHasMouse:NO];
//}

-(void)updateTrackingAreas
{
    
    if(self.boundsTrackingArea != nil) {
        [self removeTrackingArea:self.boundsTrackingArea];
    }
    
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingMouseMoved);
    NSPoint buttonPoint = NSMakePoint(0,0);
    NSRect trackingBounds = CGRectMake(buttonPoint.x, buttonPoint.y, 74.0, 74.0);//[self bounds]
    self.boundsTrackingArea = [ [NSTrackingArea alloc] initWithRect:trackingBounds
                                                            options:opts
                                                              owner:self
                                                           userInfo:nil];
    [self addTrackingArea:self.boundsTrackingArea];
}

//////////
//
// imageInit
//
// Locate our image file and create an NSImage for it. Also, create
// a string which we'll use to draw in our view.
//
//////////

-(void) imageInit
{
    // create an NSImage for our image file
	//NSString *filePath = [[NSBundle mainBundle] pathForResource:@"play" ofType:@"png"];
	drawImage = [NSImage imageNamed:@"playbutton"];//[[NSImage alloc] initWithContentsOfFile:filePath];
    
    // Set up attributed text which we will draw into our view
//    NSFont *font = [NSFont fontWithName:@"Helvetica" size:36.0];
//    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
//    
//    [attrs setObject:font forKey:NSFontAttributeName];
//    [attrs setObject:[NSColor greenColor]
//              forKey:NSForegroundColorAttributeName];
//    
//    textString = [ [NSMutableAttributedString alloc]
//                  initWithString:@"Play"
//                  attributes:attrs];
    
}


//////////
//
// initWithFrame
//
// Initialize our NSView with frameRect
//
//////////

- (id)initWithFrame:(NSRect)frameRect
{
	id view = [super initWithFrame:frameRect];
    
	[self imageInit];
    
	return view;
}

//////////
//
// initWithCoder
//
// Initializes a newly allocated NSView instance from data in aDecoder.
//
//////////

- (id)initWithCoder:(NSCoder *)aDecoder
{
	id view = [super initWithCoder:aDecoder];
    
	[self imageInit];
    
	return view;
}


//////////
//
// drawRect
//
// Draw our image & text string to the view
//
//////////

- (void)drawRect:(NSRect)rect
{
	[[NSColor clearColor] set];
	NSRectFill([self bounds]);
    
	//[drawImage compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
    CGSize size = [drawImage size];
    CGFloat xval = CGRectGetMidX(rect)-(size.width/2);
    CGFloat yval = CGRectGetMidY(rect);//(size.height/2);
    [drawImage drawAtPoint:NSMakePoint(xval,yval) fromRect:rect operation:NSCompositeSourceOver fraction:1.0f];
    
	//[textString drawAtPoint:NSMakePoint(50,5)];
}



//////////
//
// dealloc
//
// cleanup
//
//////////

- (void)dealloc
{

}

@end
