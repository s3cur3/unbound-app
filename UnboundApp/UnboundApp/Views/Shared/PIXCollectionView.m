//
// Created by Ryan Harter on 10/8/17.
// Copyright (c) 2017 Pixite Apps LLC. All rights reserved.
//

#import "PIXCollectionView.h"


@implementation PIXCollectionView

- (void)keyDown:(NSEvent *)event {
//    NSLog(@"event: %@", event);
    switch (event.keyCode) {
        case 123: // left
        case 124: // right
        case 125: // down
        case 126: // up
            if (self.selectionIndexPaths.count == 0 && self.visibleItems.count != 0) {
                self.selectionIndexPaths = [NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:0]];
            } else {
                [super keyDown:event];
            }
            break;

        default:
            [self.nextResponder keyDown:event];
    }
}

@end

