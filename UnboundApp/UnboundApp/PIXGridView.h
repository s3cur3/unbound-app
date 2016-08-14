//
//  PIXGridView.h
//  UnboundApp
//
//  Created by Ditriol Wei on 29/7/16.
//  Copyright © 2016 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PIXLeapInputManager.h"

@protocol PIXGridViewDelegate;
@interface PIXGridView : NSCollectionView <PIXLeapResponder>

@property (nonatomic, assign) id<PIXGridViewDelegate> gridViewDelegate;

@property (nonatomic, assign) NSSize itemSize;

/* Don't use */
@property (nonatomic, assign) CGFloat headerSpace;

- (void)setBackgroundColor:(NSColor *)c;

- (void)reloadSelection;

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

@end