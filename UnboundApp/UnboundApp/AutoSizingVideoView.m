//
//  AutoSizingVideoView.m
//  Unbound5
//
//  Created by Bob on 10/9/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "AutoSizingVideoView.h"

@implementation AutoSizingVideoView

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


@end
