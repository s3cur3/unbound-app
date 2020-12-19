//
// Created by Ryan Harter on 10/6/17.
// Copyright (c) 2017 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PIXCollectionToolbar : NSView

@property (nonatomic, strong) IBOutlet NSView *contentView;
@property (nonatomic, strong) IBOutlet NSView *bottomBorderView;
@property (nonatomic, strong) IBOutlet NSTextField *titleField;
@property (nonatomic, strong) IBOutlet NSStackView * buttonHolder;

@property (nonatomic, strong) NSCollectionView *collectionView;

- (void)setButtons:(NSArray *)buttonArray;
- (void)showToolbar;
- (void)hideToolbar;

- (void)setTitle:(NSString *)title;

@end
