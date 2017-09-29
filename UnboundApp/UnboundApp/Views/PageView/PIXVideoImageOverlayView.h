//
//  PIXVideoImageOverlayView.h
//  UnboundApp
//
//  Created by Bob on 7/18/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PIXVideoImageOverlayView : NSView
{
	NSImage *drawImage;
	NSMutableAttributedString *textString;   // text string to draw
}

- (void)drawRect:(NSRect)rect;
- (void)imageInit;
- (id)initWithFrame:(NSRect)frameRect;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)dealloc;

@property (strong) NSTrackingArea * boundsTrackingArea;

@end
