//
//  PIXMiniExifView.m
//  UnboundApp
//
//  Created by Scott Sykora on 2/25/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXExifBGView.h"

@implementation PIXExifBGView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

BOOL isDarkMode()
{
	NSAppearance *appearance = NSAppearance.currentAppearance;
	if (@available(*, macOS 10.14)) {
		return appearance.name == NSAppearanceNameDarkAqua;
	}

	return [[NSUserDefaults standardUserDefaults] integerForKey:@"backgroundTheme"] != 0;
}

- (void)drawRect:(NSRect)dirtyRect
{
	// Only draw the green background in light mode
	if(!isDarkMode()) {
		// inset the rect by half a pixel so the 1px stroke at the end lines up with the pixels correctly
		NSRect greenRect = NSInsetRect([self bounds], 0.5, 0.5);
		
		
		// Create and fill the shown path
		NSBezierPath * path = [NSBezierPath bezierPathWithRoundedRect:greenRect xRadius:3 yRadius:3];
		
		NSColor * color1 = [NSColor colorWithCalibratedRed:0.883 green:0.890 blue:0.807 alpha:1.000];
		NSColor * color2 = [NSColor colorWithCalibratedRed:0.734 green:0.766 blue:0.608 alpha:1.000];
		
		NSGradient * gradient = [[NSGradient alloc] initWithStartingColor:color1
															  endingColor:color2];
		
		[color1 setFill];
		[path fill];
		
		[gradient drawInBezierPath:path angle:90];
		
		// Save the graphics state for shadow
		[NSGraphicsContext saveGraphicsState];
		
		// Set the shown path as the clip
		[path setClip];

		NSGraphicsContext *context = [NSGraphicsContext currentContext];
		[context setCompositingOperation:NSCompositePlusDarker];
		
		[[NSColor whiteColor] setStroke];
		
		// Create and stroke the shadow
		NSShadow * shadow = [[NSShadow alloc] init];
		[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:.7]];
		[shadow setShadowBlurRadius:4.0];
		[shadow setShadowOffset:NSMakeSize(0, -1)];
		[shadow set];
		
		
		[path stroke];
		 
		
		// Restore the graphics state
		[NSGraphicsContext restoreGraphicsState];
		
		// Add a nice stroke for a border
		[path setLineWidth:1.0];
		[[NSColor colorWithCalibratedWhite:0.0 alpha:.5] setStroke];
		[path stroke];
	}
}

@end
