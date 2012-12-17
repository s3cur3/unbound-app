//
//  PIXImageBrowserView.m
//  Unbound
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXImageBrowserView.h"
#import "PIXImageBrowserCell.h"

@implementation PIXImageBrowserView

-(void)awakeFromNib
{
    [self setConstrainsToOriginalSize:YES];
    //[self setAnimates:YES];
    [self setAllowsReordering:YES];
	// cell spacing
	//[self setIntercellSpacing:NSMakeSize(5.0f, 5.0f)];
    
    
    [self setValue:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.0] forKey:IKImageBrowserBackgroundColorKey];
    
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

//---------------------------------------------------------------------------------
// drawRect:
//
// override draw rect and force the background layer to redraw if the view did resize or did scroll
//---------------------------------------------------------------------------------
- (void) drawRect:(NSRect) rect
{
	//retrieve the visible area
	NSRect visibleRect = [self visibleRect];
	
	//compare with the visible rect at the previous frame
	if(!NSEqualRects(visibleRect, lastVisibleRect)){
		//we did scroll or resize, redraw the background
		[[self backgroundLayer] setNeedsDisplay];
		
		//update last visible rect
		lastVisibleRect = visibleRect;
	}
	
	[super drawRect:rect];
}



//---------------------------------------------------------------------------------
// newCellForRepresentedItem:
//
// Allocate and return our own cell class for the specified item. The returned cell must not be autoreleased
//---------------------------------------------------------------------------------
- (IKImageBrowserCell *) newCellForRepresentedItem:(id) cell
{
	return [[PIXImageBrowserCell alloc] init];
}


@end
