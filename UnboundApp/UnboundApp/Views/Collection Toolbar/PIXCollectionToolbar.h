//
// Created by Ryan Harter on 10/6/17.
// Copyright (c) 2017 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PIXGradientBarView.h"

@interface PIXCollectionToolbar : PIXGradientBarView

@property (nonatomic, strong) IBOutlet NSView *contentView;
@property (nonatomic, strong) IBOutlet NSTextField *titleField;

@property (nonatomic, strong) NSCollectionView *collectionView;

- (void)showToolbar:(BOOL)animated;
- (void)hideToolbar:(BOOL)animated;

- (void)setTitle:(NSString *)title;

@end