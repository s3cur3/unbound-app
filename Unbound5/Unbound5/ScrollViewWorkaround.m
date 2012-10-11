//
//  ScrollViewWorkaround.m
//  IKImageViewDemo
//
//  Created by Nicholas Riley on 1/25/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "ScrollViewWorkaround.h"
#import <Quartz/Quartz.h>


@interface IKImageClipView : NSClipView
- (NSRect)docRect;
@end

@implementation ScrollViewWorkaround

- (void)reflectScrolledClipView:(NSClipView *)cView;
{
    NSView *_imageView = [self documentView];
    [super reflectScrolledClipView:cView];
    if ([_imageView isKindOfClass:[IKImageView class]] &&
	 [[self contentView] isKindOfClass:[IKImageClipView class]] &&
	 [[self contentView] respondsToSelector:@selector(docRect)]) {
	NSSize docSize = [(IKImageClipView *)[self contentView] docRect].size;
	NSSize scrollViewSize = [self contentSize];
	// NSLog(@"doc %@ scrollView %@", NSStringFromSize(docSize), NSStringFromSize(scrollViewSize));
	if (docSize.height > scrollViewSize.height || docSize.width > scrollViewSize.width)
	 ((IKImageView *)_imageView).autohidesScrollers = NO;
	else
	 ((IKImageView *)_imageView).autohidesScrollers = YES;
    }
}

@end
