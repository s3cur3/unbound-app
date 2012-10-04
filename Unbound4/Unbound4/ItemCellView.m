//
//  ItemCellView.m
//  LionTableViewTesting
//
//  Created by Tomaž Kragelj on 8/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ItemCellView.h"

static BOOL kLargeSizeRequested = YES;

#pragma mark -

@implementation ItemCellView

@synthesize detailTextField = _detailTextField;

/*- (void)dealloc {
	[_detailTextField release], _detailTextField = nil;
    [super dealloc];
}*/

- (void)setObjectValue:(id)objectValue {
	[super setObjectValue:objectValue];
	//[self layoutViewsForLargeSize:kLargeSizeRequested animated:NO];
}

/*- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
	NSColor *textColor = (backgroundStyle == NSBackgroundStyleDark) ? [NSColor windowBackgroundColor] : [NSColor controlShadowColor];
	self.detailTextField.textColor = textColor;
	[super setBackgroundStyle:backgroundStyle];
}*/

- (void)layoutViewsForLargeSize:(BOOL)largeSize animated:(BOOL)animated {
	kLargeSizeRequested = largeSize;
	
	// If large size is requested, we should show details text field otherwise hide it.
	CGFloat detailAlpha = largeSize ? 1.0f : 0.0f;

	// If large size is requested, we should use 32x32, otherwise 16x16 icon.
	CGFloat iconSize = largeSize ? 32.0f : 16.0f;
	NSRect iconFrame = NSMakeRect(2.0f, 2.0f, iconSize, iconSize);
	
	// We should always align name text field to the right of the icon.
	CGFloat nameLeft = iconFrame.origin.x + iconFrame.size.width + 5.0f;
	CGFloat nameBottom = iconFrame.origin.y + iconFrame.size.height - (largeSize ? 18.0f : 16.0f);
	CGFloat nameWidth = self.bounds.size.width - nameLeft - 2.0f;
	CGFloat nameHeight = 16.0f;
	NSRect nameFrame = NSMakeRect(nameLeft, nameBottom, nameWidth, nameHeight);
	
	if (animated) {
		[[self.detailTextField animator] setAlphaValue:detailAlpha];
		[[self.imageView animator] setFrame:iconFrame];
		[[self.textField animator] setFrame:nameFrame];
	} else {
		[self.detailTextField setAlphaValue:detailAlpha];
		[self.imageView setFrame:iconFrame];
		[self.textField setFrame:nameFrame];
	}
}

@end
