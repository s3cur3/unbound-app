//
// Created by Ryan Harter on 10/6/17.
// Copyright (c) 2017 Pixite Apps LLC. All rights reserved.
//

#import "PIXCollectionToolbar.h"
#import "NSCollectionView+PIXSelection.h"


@interface PIXCollectionToolbar() <NSMenuDelegate>

@property (strong) NSLayoutConstraint *position;
@property BOOL isShowing;

@end

@implementation PIXCollectionToolbar

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self commonInit];
    }

    return self;
}


- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }

    return self;
}

- (void)commonInit {
    [NSBundle.mainBundle loadNibNamed:@"PIXCollectionToolbar" owner:self topLevelObjects:nil];
    [self addSubview:self.contentView];
    self.contentView.frame = self.bounds;
    self.contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    // Find the positional constraint
    for (NSLayoutConstraint *constraint in self.superview.constraints) {
        if (constraint.firstItem == self && constraint.firstAttribute == NSLayoutAttributeTop) {
            self.position = constraint;
            break;
        }
    }
}

#pragma mark - Show/Hide Toolbar
- (void)showToolbar:(BOOL)animated; {
    if (!self.isShowing) {
        if (animated) {
            self.position.animator.constant = 0;
        } else {
            self.position.constant = 0;
        }
        self.isShowing = YES;
    }

}

- (void)hideToolbar:(BOOL)animated {
    if(self.isShowing)
    {
        if (animated) {
            self.position.animator.constant = -self.frame.size.height;
        } else {
            self.position.constant = -self.frame.size.height;
        }
        self.isShowing = NO;
    }
}

- (void)setTitle:(NSString *)title; {
    self.titleField.stringValue = title;
}

#pragma mark - Item Selection
- (IBAction)selectAll:(id)sender
{
    if (self.collectionView) {
        [self.collectionView selectAll:sender];
    }
}

- (IBAction)selectNone:(id)sender
{
    if (self.collectionView) {
        [self.collectionView deselectAll:sender];
    }
}

- (IBAction)toggleSelection:(id)sender
{
    if (self.collectionView) {
        [self.collectionView selectInverse];
    }
}

- (IBAction)deleteItems:(id )sender
{
    if ([self.delegate respondsToSelector:@selector(toolbar:deleteSelectedItems:)]) {
        [self.delegate toolbar:self deleteSelectedItems:sender];
    }
}


@end