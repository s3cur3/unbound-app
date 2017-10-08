//
// Created by Ryan Harter on 10/6/17.
// Copyright (c) 2017 Pixite Apps LLC. All rights reserved.
//

#import "NSCollectionView+PIXSelection.h"


@implementation NSCollectionView (PIXSelection)

- (void)selectInverse; {
    if (self.selectionIndexPaths.count == 0) {
        [self selectAll:nil];
        return;
    }

    if (self.dataSource == nil) {
        NSLog(@"Called NSCollectionView+PIXSelection selectInverse with no datasource attached.");
        return;
    }

    NSSet<NSIndexPath *> *original = self.selectionIndexPaths;
    NSMutableSet<NSIndexPath *> *newSelection = [NSMutableSet set];

    NSInteger sections = [self.dataSource numberOfSectionsInCollectionView:self];
    for (NSInteger i = 0; i < sections; i++) {
        NSInteger items = [self.dataSource collectionView:self numberOfItemsInSection:i];
        for (NSInteger j = 0; j < items; j++) {
            NSIndexPath *index = [NSIndexPath indexPathForItem:j inSection:i];
            if (![original containsObject:index]) {
                [newSelection addObject:index];
            }
        }
    }
    self.animator.selectionIndexPaths = newSelection;
}

@end