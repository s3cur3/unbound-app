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
      
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(keyWindowChanged)
                                                   name:NSWindowDidResignMainNotification
                                                 object:[self window]];
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(keyWindowChanged)
                                                   name:NSWindowDidBecomeMainNotification
                                                 object:[self window]];
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
    self.contentView.wantsLayer = true;
    self.contentView.frame = self.bounds;
    self.contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  self.bottomBorderView.wantsLayer = true;
  
  self.titleField.textColor = NSColor.controlTextColor;
}

- (void) updateLayer {
  self.contentView.layer.backgroundColor = NSColor.controlBackgroundColor.CGColor;
  if (@available(macOS 10.14, *)) {
    self.bottomBorderView.layer.backgroundColor = NSColor.separatorColor.CGColor;
  } else {
    NSColor *borderColor;
    if ([[self window] isMainWindow]) {
      borderColor = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
    } else {
      borderColor = [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
    }
    self.bottomBorderView.layer.backgroundColor = borderColor.CGColor;
  }
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

-(void)setButtons:(NSArray *)buttonArray
{
  // remove all subviews
  NSArray * subviews = self.buttonHolder.subviews.copy;
  for(NSView * subview in subviews) {
    [subview removeFromSuperview];
  }
  
  for (NSButton *button in buttonArray) {
    button.bezelStyle = NSBezelStyleRounded;
    [self.buttonHolder addView:button inGravity:NSStackViewGravityTrailing];
  }
}

-(void)keyWindowChanged
{
  [self setNeedsDisplay:YES];
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

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
