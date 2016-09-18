//
//  PIXGridView.h
//  UnboundApp
//
//  Created by Ditriol Wei on 29/7/16.
//  Copyright © 2016 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PIXLeapInputManager.h"
#import "PIXCollectionViewItem.h"

@protocol PIXGridViewDelegate;

typedef struct _PIXItemPoint {
    NSUInteger column;
    NSUInteger row;
} PIXItemPoint;

@interface PIXGridView : NSCollectionView <PIXLeapResponder>

@property (nonatomic, assign) id<PIXGridViewDelegate> gridViewDelegate;

/**
 Property for setting the elasticity of the enclosing `NSScrollView`.
 
 This property will set and overwrite the values from Interface Builder. There is no horizontal-vertical distinction.
 The default value is `YES`.
 
 @param     YES Elasticity is on.
 @param     NO Elasticity is off.
 
 */
@property (nonatomic, assign) BOOL scrollElasticity;


@property (nonatomic, assign) NSSize itemSize;

/* Don't use */
@property (nonatomic, assign) CGFloat headerSpace;

- (void)setBackgroundColor:(NSColor *)c;

- (void)reloadSelection;

- (PIXCollectionViewItem *)scrollToAndReturnItemAtIndex:(NSUInteger)index animated:(BOOL)animated;

@end



@protocol PIXGridViewDelegate <NSObject>
@optional

- (void)gridViewDidDeselectAllItems:(PIXGridView *)gridView;

- (void)gridView:(PIXGridView*)gridView didShiftSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;

- (void)gridView:(PIXGridView *)gridView didClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;
- (void)gridView:(PIXGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;

- (void)gridView:(PIXGridView*)gridView willSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;
- (void)gridView:(PIXGridView*)gridView didSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;

- (void)gridView:(PIXGridView*)gridView willDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;
- (void)gridView:(PIXGridView*)gridView didDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;

- (void)gridView:(PIXGridView *)gridView rightMouseButtonClickedOnItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event;

- (void)gridView:(PIXGridView *)gridView dragDidBeginAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event;

- (BOOL)gridView:(PIXGridView *)gridView itemIsSelectedAtIndex:(NSInteger)index inSection:(NSInteger)section;


- (void)gridViewDeleteKeyPressed:(PIXGridView *)gridView;
- (void)gridView:(PIXGridView *)gridView didKeyOpenItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;
- (void)gridView:(PIXGridView *)gridView didKeySelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;
- (void)gridView:(PIXGridView *)gridView didPointItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;

@end