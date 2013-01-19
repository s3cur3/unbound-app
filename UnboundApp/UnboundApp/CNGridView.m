//
//  CNGridView.m
//
//  Created by cocoa:naut on 06.10.12.
//  Copyright (c) 2012 cocoa:naut. All rights reserved.
//

/*
 The MIT License (MIT)
 Copyright © 2012 Frank Gregor, <phranck@cocoanaut.com>

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the “Software”), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import <QuartzCore/QuartzCore.h>
#import "NSColor+CNGridViewPalette.h"
#import "NSView+CNGridView.h"
#import "CNGridView.h"


#if !__has_feature(objc_arc)
#error "Please use ARC for compiling this file."
#endif



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Notifications

const int CNSingleClick = 1;
const int CNDoubleClick = 2;
const int CNTrippleClick = 3;

NSString *CNGridViewSelectAllItemsNotification = @"CNGridViewSelectAllItems";
NSString *CNGridViewDeSelectAllItemsNotification = @"CNGridViewDeSelectAllItems";

NSString *CNGridViewWillHoverItemNotification = @"CNGridViewWillHoverItem";
NSString *CNGridViewWillUnhoverItemNotification = @"CNGridViewWillUnhoverItem";
NSString *CNGridViewWillSelectItemNotification = @"CNGridViewWillSelectItem";
NSString *CNGridViewDidSelectItemNotification = @"CNGridViewDidSelectItem";
NSString *CNGridViewWillDeselectItemNotification = @"CNGridViewWillDeselectItem";
NSString *CNGridViewDidDeselectItemNotification = @"CNGridViewDidDeselectItem";
NSString *CNGridViewWillDeselectAllItemsNotification = @"CNGridViewWillDeselectAllItems";
NSString *CNGridViewDidDeselectAllItemsNotification = @"CNGridViewDidDeselectAllItems";
NSString *CNGridViewDidClickItemNotification = @"CNGridViewDidClickItem";
NSString *CNGridViewDidDoubleClickItemNotification = @"CNGridViewDidDoubleClickItem";
NSString *CNGridViewRightMouseButtonClickedOnItemNotification = @"CNGridViewRightMouseButtonClickedOnItem";

NSString *CNGridViewItemKey = @"gridViewItem";
NSString *CNGridViewItemIndexKey = @"gridViewItemIndex";
NSString *CNGridViewSelectedItemsKey = @"CNGridViewSelectedItems";



CNItemPoint CNMakeItemPoint(NSUInteger aColumn, NSUInteger aRow) {
    CNItemPoint point;
    point.column = aColumn;
    point.row = aRow;
    return point;
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark CNSelectionFrameView

@interface CNSelectionFrameView : NSView
@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark CNGridView


@interface CNGridView () {
    NSMutableDictionary *keyedVisibleItems;
    NSMutableDictionary *reuseableItems;
    NSMutableDictionary *selectedItems;
    NSMutableDictionary *selectedItemsBySelectionFrame;
    CNSelectionFrameView *selectionFrameView;
    NSNotificationCenter *nc;
    NSMutableArray *clickEvents;
    NSTrackingArea *gridViewTrackingArea;
    NSTimer *clickTimer;
    NSInteger lastHoveredIndex;
    NSInteger lastSelectedItemIndex;
    NSInteger numberOfItems;
    CGPoint selectionFrameInitialPoint;
    BOOL isInitialCall;
    BOOL mouseHasDragged;
    BOOL abortSelection;
}
- (void)setupDefaults;
- (void)updateVisibleRect;
- (void)refreshGridViewAnimated:(BOOL)animated;
- (void)updateReuseableItems;
- (void)updateVisibleItems;
- (NSIndexSet *)indexesForVisibleItems;
- (void)arrangeGridViewItemsAnimated:(BOOL)animated;
- (NSRange)visibleItemRange;
- (NSRect)rectForItemAtIndex:(NSUInteger)index;
- (NSUInteger)columnsInGridView;
- (NSUInteger)allOverRowsInGridView;
- (NSUInteger)visibleRowsInGridView;
- (NSRect)clippedRect;
- (NSUInteger)indexForItemAtLocation:(NSPoint)location;
- (CNItemPoint)locationForItemAtIndex:(NSUInteger)itemIndex;
- (void)hoverItemAtIndex:(NSInteger)index;
- (void)unHoverItemAtIndex:(NSInteger)index;
- (void)selectItemAtIndex:(NSUInteger)selectedItemIndex usingModifierFlags:(NSUInteger)modifierFlags;
- (void)handleClicks:(NSTimer *)theTimer;
- (void)handleSingleClickForItemAtIndex:(NSUInteger)selectedItemIndex;
- (void)handleDoubleClickForItemAtIndex:(NSUInteger)selectedItemIndex;
- (void)drawSelectionFrameForMousePointerAtLocation:(NSPoint)location;
- (void)selectItemsCoveredBySelectionFrame:(NSRect)selectionFrame usingModifierFlags:(NSUInteger)modifierFlags;
@end


@implementation CNGridView

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        [self setupDefaults];
        _delegate = nil;
        _dataSource = nil;
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDefaults];
        _delegate = nil;
        _dataSource = nil;
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupDefaults];
    }
    return self;
}

- (void)setupDefaults
{
    keyedVisibleItems = [[NSMutableDictionary alloc] init];
    reuseableItems = [[NSMutableDictionary alloc] init];
    selectedItems = [[NSMutableDictionary alloc] init];
    selectedItemsBySelectionFrame = [[NSMutableDictionary alloc] init];
    clickEvents = [NSMutableArray array];
    nc = [NSNotificationCenter defaultCenter];
    lastHoveredIndex = NSNotFound;
    lastSelectedItemIndex = NSNotFound;
    selectionFrameInitialPoint = CGPointZero;
    clickTimer = nil;
    isInitialCall = YES;
    abortSelection = NO;
    mouseHasDragged = NO;
    selectionFrameView = nil;


    /// properties
    _backgroundColor = [NSColor controlColor];
    _itemSize = [CNGridViewItem defaultItemSize];
    _gridViewTitle = nil;
    _scrollElasticity = YES;
    _allowsSelection = YES;
    _allowsMultipleSelection = NO;
    _useSelectionRing = YES;
    _useHover = YES;


    [[self enclosingScrollView] setDrawsBackground:YES];

    NSClipView *clipView = [[self enclosingScrollView] contentView];
    [clipView setPostsBoundsChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateVisibleRect)
                                                 name:NSViewBoundsDidChangeNotification
                                               object:clipView];
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Accessors

- (void)setItemSize:(NSSize)itemSize
{
    if (!NSEqualSizes(_itemSize, itemSize)) {
        _itemSize = itemSize;
        [self refreshGridViewAnimated:YES];
    }
}

- (void)setScrollElasticity:(BOOL)scrollElasticity
{
    _scrollElasticity = scrollElasticity;
    NSScrollView *scrollView = [self enclosingScrollView];
    if (_scrollElasticity) {
        [scrollView setHorizontalScrollElasticity:NSScrollElasticityAllowed];
        [scrollView setVerticalScrollElasticity:NSScrollElasticityAllowed];
    } else {
        [scrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
        [scrollView setVerticalScrollElasticity:NSScrollElasticityNone];
    }
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    [[self enclosingScrollView] setBackgroundColor:_backgroundColor];
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
    _allowsMultipleSelection = allowsMultipleSelection;
    if (selectedItems.count > 0 && !allowsMultipleSelection) {
        [nc postNotificationName:CNGridViewDeSelectAllItemsNotification object:self];
        [selectedItems removeAllObjects];
    }
}




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Helper

- (void)updateVisibleRect
{
    [self updateReuseableItems];
    [self updateVisibleItems];
    [self arrangeGridViewItemsAnimated:NO];
}

- (void)refreshGridViewAnimated:(BOOL)animated
{
    NSRect scrollRect = [self frame];
    scrollRect.size.width = scrollRect.size.width;
    scrollRect.size.height = [self allOverRowsInGridView] * self.itemSize.height;
    [super setFrame:scrollRect];

    [self updateReuseableItems];
    [self updateVisibleItems];
    [self arrangeGridViewItemsAnimated:animated];
}

- (void)updateReuseableItems
{
    NSRange visibleItemRange = [self visibleItemRange];

    [[keyedVisibleItems allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CNGridViewItem *item = (CNGridViewItem *)obj;
        if (!NSLocationInRange(item.index, visibleItemRange) && [item isReuseable]) {
            [keyedVisibleItems removeObjectForKey:[NSNumber numberWithUnsignedInteger:item.index]];
            [item removeFromSuperview];
            [item prepareForReuse];

            NSMutableSet *reuseQueue = [reuseableItems objectForKey:item.reuseIdentifier];
            if (reuseQueue == nil)
                reuseQueue = [NSMutableSet set];
            [reuseQueue addObject:item];
            [reuseableItems setObject:reuseQueue forKey:item.reuseIdentifier];
        }
    }];
}

- (void)updateVisibleItems
{
    NSRange visibleItemRange = [self visibleItemRange];
    NSMutableIndexSet *visibleItemIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:visibleItemRange];

    [visibleItemIndexes removeIndexes:[self indexesForVisibleItems]];

    /// update all visible items
    [visibleItemIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        CNGridViewItem *item = [self gridView:self itemAtIndex:idx inSection:0];
        if (item) {
            item.index = idx;
            if (isInitialCall) {
                [item setAlphaValue:0.0];
                [item setFrame:[self rectForItemAtIndex:idx]];
            }
            [keyedVisibleItems setObject:item forKey:[NSNumber numberWithUnsignedInteger:item.index]];
            [self addSubview:item];
        }
    }];
}

- (NSIndexSet *)indexesForVisibleItems
{
    __block NSMutableIndexSet *indexesForVisibleItems = [[NSMutableIndexSet alloc] init];
    [keyedVisibleItems enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [indexesForVisibleItems addIndex:[(CNGridViewItem *)obj index]];
    }];
    return indexesForVisibleItems;
}

- (void)arrangeGridViewItemsAnimated:(BOOL)animated
{
    /// on initial call (aka application startup) we will fade all items (after loading it) in
    if (isInitialCall && [keyedVisibleItems count] > 0) {
        isInitialCall = NO;

        [[NSAnimationContext currentContext] setDuration:0.35];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [keyedVisibleItems enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [[(CNGridViewItem *)obj animator] setAlphaValue:1.0];
            }];

        } completionHandler:^{

        }];
    }

    else if ([keyedVisibleItems count] > 0) {
        [[NSAnimationContext currentContext] setDuration:(animated ? 0.15 : 0.0)];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [keyedVisibleItems enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSRect newRect = [self rectForItemAtIndex:[(CNGridViewItem *)obj index]];
                [[(CNGridViewItem *)obj animator] setFrame:newRect];
            }];

        } completionHandler:^{

        }];
    }
}

- (NSRange)visibleItemRange
{
    NSRect clippedRect  = [self clippedRect];
    NSUInteger columns  = [self columnsInGridView];
    NSUInteger rows     = [self visibleRowsInGridView];

    NSUInteger rangeStart = 0;
    if (clippedRect.origin.y > self.itemSize.height) {
        rangeStart = (ceilf(clippedRect.origin.y / self.itemSize.height) * columns) - columns;
    }
    NSUInteger rangeLength = MIN(numberOfItems, (columns * rows) + columns);
    rangeLength = ((rangeStart + rangeLength) > numberOfItems ? numberOfItems - rangeStart : rangeLength);

    NSRange rangeForVisibleRect = NSMakeRange(rangeStart, rangeLength);
    return rangeForVisibleRect;
}

- (NSRect)rectForItemAtIndex:(NSUInteger)index
{
    NSUInteger columns = [self columnsInGridView];
    NSRect itemRect = NSMakeRect((index % columns) * self.itemSize.width,
                                 ((index - (index % columns)) / columns) * self.itemSize.height,
                                 self.itemSize.width,
                                 self.itemSize.height);
    return itemRect;
}

- (NSUInteger)columnsInGridView
{
    NSRect visibleRect  = [self clippedRect];
    NSUInteger columns = floorf((float)NSWidth(visibleRect) / self.itemSize.width);
    columns = (columns < 1 ? 1 : columns);
    return columns;
}

- (NSUInteger)allOverRowsInGridView
{
    NSUInteger allOverRows = ceilf((float)numberOfItems / [self columnsInGridView]);
    return allOverRows;
}

- (NSUInteger)visibleRowsInGridView
{
    NSRect visibleRect  = [self clippedRect];
    NSUInteger visibleRows = ceilf((float)NSHeight(visibleRect) / self.itemSize.height);
    return visibleRows;
}

- (NSRect)clippedRect
{
    return [[[self enclosingScrollView] contentView] bounds];
}

- (NSUInteger)indexForItemAtLocation:(NSPoint)location
{
    NSPoint point = [self convertPoint:location fromView:nil];
    NSUInteger indexForItemAtLocation;
    if (point.x > (self.itemSize.width * [self columnsInGridView])) {
        indexForItemAtLocation = NSNotFound;

    } else {
        NSUInteger currentColumn = floor(point.x / self.itemSize.width);
        NSUInteger currentRow = floor(point.y / self.itemSize.height);
        indexForItemAtLocation = currentRow * [self columnsInGridView] + currentColumn;
        indexForItemAtLocation = (indexForItemAtLocation > (numberOfItems - 1) ? NSNotFound : indexForItemAtLocation);
    }
    return indexForItemAtLocation;
}

- (CNItemPoint)locationForItemAtIndex:(NSUInteger)itemIndex
{
    NSUInteger columnsInGridView = [self columnsInGridView];
    NSUInteger row = floor(itemIndex / columnsInGridView) + 1;
    NSUInteger column = itemIndex - floor((row -1) * columnsInGridView) + 1;
    CNItemPoint location = CNMakeItemPoint(column, row);
    return location;
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Creating GridView Items

- (id)dequeueReusableItemWithIdentifier:(NSString *)identifier
{
    CNGridViewItem *reusableItem = nil;
    NSMutableSet *reuseQueue = [reuseableItems objectForKey:identifier];
    if (reuseQueue != nil && [reuseQueue count] > 0) {
        reusableItem = [reuseQueue anyObject];
        [reuseQueue removeObject:reusableItem];
        [reuseableItems setObject:reuseQueue forKey:identifier];
    }
    return reusableItem;
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Reloading GridView Data

- (void)reloadData
{
    [self reloadDataAnimated:NO];
}

- (void)reloadDataAnimated:(BOOL)animated
{
    numberOfItems = [self gridView:self numberOfItemsInSection:0];
    [keyedVisibleItems enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [(CNGridViewItem *)obj removeFromSuperview];
    }];
    [keyedVisibleItems removeAllObjects];
    [reuseableItems removeAllObjects];
    [self refreshGridViewAnimated:animated];
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Selection Handling

- (void)hoverItemAtIndex:(NSInteger)index
{
    /// inform the delegate
    [self gridView:self willHoverItemAtIndex:index inSection:0];

    lastHoveredIndex = index;
    CNGridViewItem *item = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:index]];
    item.hovered = YES;
}

- (void)unHoverItemAtIndex:(NSInteger)index
{
    /// inform the delegate
    [self gridView:self willUnhoverItemAtIndex:index inSection:0];

    CNGridViewItem *item = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:index]];
    item.hovered = NO;
}

- (void)selectItemAtIndex:(NSUInteger)selectedItemIndex usingModifierFlags:(NSUInteger)modifierFlags
{
    if (selectedItemIndex == NSNotFound)
        return;

    CNGridViewItem *gridViewItem = nil;

    if (lastSelectedItemIndex != NSNotFound && lastSelectedItemIndex != selectedItemIndex) {
        gridViewItem = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:lastSelectedItemIndex]];
        [self deSelectItem:gridViewItem];
    }

    gridViewItem = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:selectedItemIndex]];
    if (gridViewItem) {
        if (self.allowsMultipleSelection) {
            if (!gridViewItem.selected) {
                [self selectItem:gridViewItem];
            } else {
                if (modifierFlags & NSCommandKeyMask) {
                    [self deSelectItem:gridViewItem];
                }
            }

        } else {
            if (modifierFlags & NSCommandKeyMask) {
                if (gridViewItem.selected) {
                    [self deSelectItem:gridViewItem];
                } else {
                    [self selectItem:gridViewItem];
                }
            } else {
                [self selectItem:gridViewItem];
            }
        }
        lastSelectedItemIndex = (self.allowsMultipleSelection ? NSNotFound : selectedItemIndex);
    }
}

- (void)selectAllItems
{
    NSUInteger number = [self gridView:self numberOfItemsInSection:0];
    for (NSUInteger idx = 0; idx < number; idx++) {
        CNGridViewItem *item = [self gridView:self itemAtIndex:idx inSection:0];
        item.selected = YES;
        item.index = idx;
//        [item setNeedsDisplay:YES];
        [selectedItems setObject:item forKey:[NSNumber numberWithInteger:item.index]];
    };
}

- (void)deselectAllItems
{
    if (selectedItems.count > 0 && !self.allowsMultipleSelection) {
        /// inform the delegate
        [self gridView:self willDeselectAllItems:[self selectedItems]];

        [nc postNotificationName:CNGridViewDeSelectAllItemsNotification object:self];
        [selectedItems removeAllObjects];

        /// inform the delegate
        [self gridViewDidDeselectAllItems:self];
}
}

- (void)selectItem:(CNGridViewItem *)theItem
{
    if (![selectedItems objectForKey:[NSNumber numberWithInteger:theItem.index]]) {
        /// inform the delegate
        [self gridView:self willSelectItemAtIndex:theItem.index inSection:0];

        theItem.selected = YES;
        [selectedItems setObject:theItem forKey:[NSNumber numberWithInteger:theItem.index]];

        /// inform the delegate
        [self gridView:self didSelectItemAtIndex:theItem.index inSection:0];
    }
}

- (void)deSelectItem:(CNGridViewItem *)theItem
{
    if ([selectedItems objectForKey:[NSNumber numberWithInteger:theItem.index]]) {
        /// inform the delegate
        [self gridView:self willDeselectItemAtIndex:theItem.index inSection:0];

        theItem.selected = NO;
        [selectedItems removeObjectForKey:[NSNumber numberWithInteger:theItem.index]];

        /// inform the delegate
        [self gridView:self didDeselectItemAtIndex:theItem.index inSection:0];
    }
}

- (NSArray *)selectedItems
{
    return [selectedItems allValues];
}

- (void)handleClicks:(NSTimer *)theTimer
{
    switch ([clickEvents count]) {
        case CNSingleClick: {
            NSEvent *theEvent = [clickEvents lastObject];
            NSUInteger index = [self indexForItemAtLocation:theEvent.locationInWindow];
            [self handleSingleClickForItemAtIndex:index];
            break;
        }

        case CNDoubleClick: {
            NSUInteger indexClick1 = [self indexForItemAtLocation:[[clickEvents objectAtIndex:0] locationInWindow]];
            NSUInteger indexClick2 = [self indexForItemAtLocation:[[clickEvents objectAtIndex:1] locationInWindow]];
            if (indexClick1 == indexClick2) {
                [self handleDoubleClickForItemAtIndex:indexClick1];
            } else {
                [self handleSingleClickForItemAtIndex:indexClick1];
                [self handleSingleClickForItemAtIndex:indexClick2];
            }
            break;
        }

        case CNTrippleClick: {
            NSUInteger indexClick1 = [self indexForItemAtLocation:[[clickEvents objectAtIndex:0] locationInWindow]];
            NSUInteger indexClick2 = [self indexForItemAtLocation:[[clickEvents objectAtIndex:1] locationInWindow]];
            NSUInteger indexClick3 = [self indexForItemAtLocation:[[clickEvents objectAtIndex:2] locationInWindow]];
            if (indexClick1 == indexClick2 == indexClick3) {
                [self handleDoubleClickForItemAtIndex:indexClick1];
            }

            else if ((indexClick1 == indexClick2) && (indexClick1 != indexClick3)) {
                [self handleDoubleClickForItemAtIndex:indexClick1];
                [self handleSingleClickForItemAtIndex:indexClick3];
            }

            else if ((indexClick1 != indexClick2) && (indexClick2 == indexClick3)) {
                [self handleSingleClickForItemAtIndex:indexClick1];
                [self handleDoubleClickForItemAtIndex:indexClick3];
            }

            else if (indexClick1 != indexClick2 != indexClick3) {
                [self handleSingleClickForItemAtIndex:indexClick1];
                [self handleSingleClickForItemAtIndex:indexClick2];
                [self handleSingleClickForItemAtIndex:indexClick3];
            }
            break;
        }
    }
    [clickEvents removeAllObjects];
}

- (void)handleSingleClickForItemAtIndex:(NSUInteger)selectedItemIndex
{
    if (selectedItemIndex == NSNotFound)
        return;

    /// inform the delegate
    [self gridView:self didClickItemAtIndex:selectedItemIndex inSection:0];
}

- (void)handleDoubleClickForItemAtIndex:(NSUInteger)selectedItemIndex
{
    if (selectedItemIndex == NSNotFound)
        return;

    /// inform the delegate
    [self gridView:self didDoubleClickItemAtIndex:selectedItemIndex inSection:0];
}

- (void)drawSelectionFrameForMousePointerAtLocation:(NSPoint)location
{
    if (!selectionFrameView) {
        selectionFrameInitialPoint = location;
        selectionFrameView = [[CNSelectionFrameView alloc] init];
        selectionFrameView.frame = NSMakeRect(location.x, location.y, 0, 0);
        if (![self containsSubView:selectionFrameView])
            [self addSubview:selectionFrameView];
    }

    else {
        NSRect clippedRect = [self clippedRect];
        NSUInteger columnsInGridView = [self columnsInGridView];
        
        CGFloat posX = ceil((location.x > selectionFrameInitialPoint.x ? selectionFrameInitialPoint.x : location.x));
        posX = (posX < NSMinX(clippedRect) ? NSMinX(clippedRect) : posX);
            
        CGFloat posY = ceil((location.y > selectionFrameInitialPoint.y ? selectionFrameInitialPoint.y : location.y));
        posY = (posY < NSMinY(clippedRect) ? NSMinY(clippedRect) : posY);
        
        CGFloat width = (location.x > selectionFrameInitialPoint.x ? location.x - selectionFrameInitialPoint.x : selectionFrameInitialPoint.x - posX);
        width = (posX + width >= (columnsInGridView * self.itemSize.width) ? (columnsInGridView * self.itemSize.width) - posX - 1 : width);

        CGFloat height = (location.y > selectionFrameInitialPoint.y ? location.y - selectionFrameInitialPoint.y : selectionFrameInitialPoint.y - posY);
        height = (posY + height > NSMaxY(clippedRect) ? NSMaxY(clippedRect) - posY : height);

        NSRect selectionFrame = NSMakeRect(posX, posY, width, height);
        selectionFrameView.frame = selectionFrame;
    }
}

- (void)selectItemsCoveredBySelectionFrame:(NSRect)selectionFrame usingModifierFlags:(NSUInteger)modifierFlags
{
    NSUInteger topLeftItemIndex = [self indexForItemAtLocation:[self convertPoint:NSMakePoint(NSMinX(selectionFrame), NSMinY(selectionFrame)) toView:nil]];
    NSUInteger bottomRightItemIndex = [self indexForItemAtLocation:[self convertPoint:NSMakePoint(NSMaxX(selectionFrame), NSMaxY(selectionFrame)) toView:nil]];

    CNItemPoint topLeftItemPoint = [self locationForItemAtIndex:topLeftItemIndex];
    CNItemPoint bottomRightItemPoint = [self locationForItemAtIndex:bottomRightItemIndex];

    /// handle all "by selection frame" selected items beeing now outside
    /// the selection frame
    [[self indexesForVisibleItems] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        CNGridViewItem *selectedItem = [selectedItems objectForKey:[NSNumber numberWithInteger:idx]];
        CNGridViewItem *selectionFrameItem = [selectedItemsBySelectionFrame objectForKey:[NSNumber numberWithInteger:idx]];
        if (selectionFrameItem) {
            CNItemPoint itemPoint = [self locationForItemAtIndex:selectionFrameItem.index];

            /// handle all 'out of selection frame range' items
            if ((itemPoint.row < topLeftItemPoint.row)              ||  /// top edge out of range
                (itemPoint.column > bottomRightItemPoint.column)    ||  /// right edge out of range
                (itemPoint.row > bottomRightItemPoint.row)          ||  /// bottom edge out of range
                (itemPoint.column < topLeftItemPoint.column))           /// left edge out of range
            {
                /// ok. before we deselect this item, lets take a look into our `keyedVisibleItems`
                /// if it there is selected too. If it so, keep it untouched!

                /// so, the current item wasn't selected, we can restore its old state (to unselected)
                if (![selectionFrameItem isEqual:selectedItem]) {
                    selectionFrameItem.selected = NO;
                    [selectedItemsBySelectionFrame removeObjectForKey:[NSNumber numberWithInteger:selectionFrameItem.index]];
                }

                /// the current item already was selected, so reselect it.
                else {
                    selectionFrameItem.selected = YES;
                    [selectedItemsBySelectionFrame setObject:selectionFrameItem forKey:[NSNumber numberWithInteger:selectionFrameItem.index]];
                }
            }
        }
    }];

    /// update all items that needs to be selected
    NSUInteger columnsInGridView = [self columnsInGridView];
    for (NSUInteger row = topLeftItemPoint.row; row <= bottomRightItemPoint.row; row++) {
        for (NSUInteger col = topLeftItemPoint.column; col <= bottomRightItemPoint.column; col++) {
            NSUInteger itemIndex = ((row -1) * columnsInGridView + col) -1;
            CNGridViewItem *selectedItem = [selectedItems objectForKey:[NSNumber numberWithInteger:itemIndex]];
            CNGridViewItem *itemToSelect = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:itemIndex]];
            [selectedItemsBySelectionFrame setObject:itemToSelect forKey:[NSNumber numberWithInteger:itemToSelect.index]];
            if (modifierFlags & NSCommandKeyMask) {
                itemToSelect.selected = ([itemToSelect isEqual:selectedItem] ? NO : YES);
            } else {
                itemToSelect.selected = YES;
            }
        }
    }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Managing the Content

- (NSUInteger)numberOfVisibleItems
{
    return [keyedVisibleItems count];
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSView

- (BOOL)isFlipped { return YES; }

- (void)setFrame:(NSRect)frameRect
{
    BOOL animated = (self.frame.size.width == frameRect.size.width ? NO: YES);
    [super setFrame:frameRect];
    [self refreshGridViewAnimated:animated];
}

- (void)updateTrackingAreas
{
    if (gridViewTrackingArea)
        [self removeTrackingArea:gridViewTrackingArea];

    gridViewTrackingArea = nil;
    gridViewTrackingArea = [[NSTrackingArea alloc] initWithRect:self.frame
                                                        options:NSTrackingMouseMoved | NSTrackingActiveInKeyWindow
                                                          owner:self
                                                       userInfo:nil];
    [self addTrackingArea:gridViewTrackingArea];
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSResponder

- (void)mouseExited:(NSEvent *)theEvent
{
    lastHoveredIndex = NSNotFound;
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    if (!self.useHover)
        return;

    NSUInteger hoverItemIndex = [self indexForItemAtLocation:theEvent.locationInWindow];
    if (hoverItemIndex != NSNotFound || hoverItemIndex != lastHoveredIndex) {
        /// unhover the last hovered item
        if (lastHoveredIndex != NSNotFound && lastHoveredIndex != hoverItemIndex) {
            [self unHoverItemAtIndex:lastHoveredIndex];
        }

        /// inform the delegate
        if (lastHoveredIndex != hoverItemIndex) {
            [self hoverItemAtIndex:hoverItemIndex];
        }
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if (!self.allowsMultipleSelection)
        return;

    mouseHasDragged = YES;
    [NSCursor closedHandCursor];

    if (!abortSelection) {
        NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        [self drawSelectionFrameForMousePointerAtLocation:location];
        [self selectItemsCoveredBySelectionFrame:selectionFrameView.frame usingModifierFlags:theEvent.modifierFlags];
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [NSCursor arrowCursor];

    abortSelection = NO;

    /// this happens just if we have multiselection ON and dragged the
    /// mouse over items. In this case we have to handle this selection.
    if (mouseHasDragged) {
        mouseHasDragged = NO;

        /// remove selection frame
        [[selectionFrameView animator] setAlphaValue:0];
        [selectionFrameView removeFromSuperview];
        selectionFrameView = nil;

        /// catch all newly selected items that was selected by selection frame
        [selectedItemsBySelectionFrame enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([(CNGridViewItem *)obj selected] == YES) {
                [self selectItem:obj];
            } else {
                [self deSelectItem:obj];
            }
        }];
        [selectedItemsBySelectionFrame removeAllObjects];
    }

    /// otherwise it was a real click on an item
    else {
        [clickEvents addObject:theEvent];
        clickTimer = nil;
        clickTimer = [NSTimer scheduledTimerWithTimeInterval:[NSEvent doubleClickInterval] target:self selector:@selector(handleClicks:) userInfo:nil repeats:NO];
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (!self.allowsSelection)
        return;

    NSPoint location = [theEvent locationInWindow];
    [self selectItemAtIndex:[self indexForItemAtLocation:location] usingModifierFlags:theEvent.modifierFlags];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    NSPoint location = [theEvent locationInWindow];
    /// inform the delegate
    [self gridView:self rightMouseButtonClickedOnItemAtIndex:[self indexForItemAtLocation:location] inSection:0];
}

- (void)keyDown:(NSEvent *)theEvent
{
    CNLog(@"keyDown");
    switch ([theEvent keyCode]) {
        case 53: {  // escape
            abortSelection = YES;
            break;
        }
    }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNGridView Delegate Calls

- (void)gridView:(CNGridView *)gridView willHoverItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [nc postNotificationName:CNGridViewWillHoverItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView willHoverItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(CNGridView *)gridView willUnhoverItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [nc postNotificationName:CNGridViewWillUnhoverItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView willUnhoverItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(CNGridView*)gridView willSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [nc postNotificationName:CNGridViewWillSelectItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView willSelectItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(CNGridView*)gridView didSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [nc postNotificationName:CNGridViewDidSelectItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView didSelectItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(CNGridView*)gridView willDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [nc postNotificationName:CNGridViewWillDeselectItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView willDeselectItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(CNGridView*)gridView didDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [nc postNotificationName:CNGridViewDidDeselectItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView didDeselectItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(CNGridView *)gridView willDeselectAllItems:(NSArray *)theSelectedItems
{
    [nc postNotificationName:CNGridViewWillDeselectAllItemsNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:theSelectedItems forKey:CNGridViewSelectedItemsKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView willDeselectAllItems:theSelectedItems];
    }
}

- (void)gridViewDidDeselectAllItems:(CNGridView *)gridView
{
    [nc postNotificationName:CNGridViewDidDeselectAllItemsNotification object:gridView userInfo:nil];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridViewDidDeselectAllItems:gridView];
    }
}

- (void)gridView:(CNGridView *)gridView didClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [nc postNotificationName:CNGridViewDidClickItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView didClickItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(CNGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [nc postNotificationName:CNGridViewDidDoubleClickItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView didDoubleClickItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(CNGridView *)gridView rightMouseButtonClickedOnItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    [nc postNotificationName:CNGridViewRightMouseButtonClickedOnItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView rightMouseButtonClickedOnItemAtIndex:index inSection:section];
    }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNGridView DataSource Calls

- (NSUInteger)gridView:(CNGridView *)gridView numberOfItemsInSection:(NSInteger)section
{
    if ([self.dataSource respondsToSelector:_cmd]) {
        return [self.dataSource gridView:gridView numberOfItemsInSection:section];
    }
    return NSNotFound;
}

- (CNGridViewItem *)gridView:(CNGridView *)gridView itemAtIndex:(NSInteger)index inSection:(NSInteger)section
{
    if ([self.dataSource respondsToSelector:_cmd]) {
        return [self.dataSource gridView:gridView itemAtIndex:index inSection:section];
    }
    return nil;
}

- (NSUInteger)numberOfSectionsInGridView:(CNGridView *)gridView
{
    if ([self.dataSource respondsToSelector:_cmd]) {
        return [self.dataSource numberOfSectionsInGridView:gridView];
    }
    return NSNotFound;
}

- (NSString *)gridView:(CNGridView *)gridView titleForHeaderInSection:(NSInteger)section
{
    if ([self.dataSource respondsToSelector:_cmd]) {
        return [self.dataSource gridView:gridView titleForHeaderInSection:section];
    }
    return nil;
}

- (NSArray *)sectionIndexTitlesForGridView:(CNGridView *)gridView
{
    if ([self.dataSource respondsToSelector:_cmd]) {
        return [self.dataSource sectionIndexTitlesForGridView:gridView];
    }
    return nil;
}

@end





/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNSelectionFrameView

@implementation CNSelectionFrameView

- (void)drawRect:(NSRect)rect
{
    NSRect dirtyRect = NSMakeRect(0.5, 0.5, floorf(NSWidth(self.bounds))-1, floorf(NSHeight(self.bounds))-1);
    NSBezierPath *selectionFrame = [NSBezierPath bezierPathWithRoundedRect:dirtyRect xRadius:0 yRadius:0];

    [[[NSColor blackColor] colorWithAlphaComponent:0.15] setFill];
    [selectionFrame fill];

    [[NSColor whiteColor] set];
    [selectionFrame setLineWidth:1];
    [selectionFrame stroke];
}

- (BOOL)isFlipped { return YES; }

@end