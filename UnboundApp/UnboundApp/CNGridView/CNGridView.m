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
#import "PIXLeapInputManager.h"


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


@interface CNGridView () <leapResponder> {
    NSMutableDictionary *keyedVisibleItems;
    NSMutableDictionary *reuseableItems;
    NSMutableDictionary *selectedItemsBySelectionFrame;
    CNSelectionFrameView *selectionFrameView;
    NSNotificationCenter *nc;
    NSMutableArray *clickEvents;
    NSTrackingArea *gridViewTrackingArea;
    NSTimer *clickTimer;
    NSInteger lastHoveredIndex;
    NSInteger lastSelectedItemIndex;
    NSInteger shouldDeselectOnMouseUpIndex;
    NSInteger numberOfItems;
    CGPoint selectionFrameInitialPoint;
    BOOL mouseDragSelectMode;
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
//- (void)selectItemAtIndex:(NSUInteger)selectedItemIndex usingModifierFlags:(NSUInteger)modifierFlags;
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
    
    [[PIXLeapInputManager sharedInstance] addResponder:self];
    
}


-(BOOL)canBecomeKeyView
{
    return YES;
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
    NSRect scrollRect = [self enclosingScrollView].frame;
    scrollRect.size.width = scrollRect.size.width;
    scrollRect.size.height = ([self allOverRowsInGridView] * self.itemSize.height) + self.headerSpace;
    
    if(scrollRect.size.height < self.superview.frame.size.height)
    {
        scrollRect.size.height = self.superview.frame.size.height;
    }
    
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
            
            item.selected = [self gridView:self itemIsSelectedAtIndex:idx inSection:0];
            
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
    NSUInteger rangeLength = MIN(numberOfItems, (columns * rows) * 2); // load two pages worth of items
    rangeLength = ((rangeStart + rangeLength) > numberOfItems ? numberOfItems - rangeStart : rangeLength);

    NSRange rangeForVisibleRect = NSMakeRange(rangeStart, rangeLength);
    return rangeForVisibleRect;
}

// this method was modified by scott to support stretching row layout
- (NSRect)rectForItemAtIndex:(NSUInteger)index
{
    NSUInteger columns = [self columnsInGridView];
    
    NSUInteger column = (index % columns);
    CGFloat xpos = column  * self.itemSize.width;
    
    CGFloat space = ([self clippedRect].size.width - (columns * self.itemSize.width)) / (columns + 1);
    

    xpos = xpos + (space * (column+1));
    
    NSRect itemRect = NSMakeRect(rint(xpos),
                                 rint((((index - (index % columns)) / columns) * self.itemSize.height)+self.headerSpace),
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

// this method was modified by scott to support stretching row layout
- (NSUInteger)indexForItemAtLocation:(NSPoint)location
{
    NSPoint point = [self convertPoint:location fromView:nil];
    NSUInteger indexForItemAtLocation;
    
    NSUInteger columns = [self columnsInGridView];
    CGFloat space = (self.frame.size.width - (columns * self.itemSize.width)) / (columns + 1);
    
    NSUInteger currentColumn = floor(point.x / (self.itemSize.width+space));
    NSUInteger currentRow = floor((point.y-self.headerSpace) / self.itemSize.height);
    indexForItemAtLocation = currentRow * [self columnsInGridView] + currentColumn;
    indexForItemAtLocation = (indexForItemAtLocation > (numberOfItems - 1) ? NSNotFound : indexForItemAtLocation);
    
    // now check that we're inside of the contentFrame rect    
    if (indexForItemAtLocation != NSNotFound)
    {
        CNGridViewItem *gridViewItem = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:indexForItemAtLocation]];
        
        NSPoint pointInItemView = [gridViewItem convertPoint:location fromView:nil];
        
        if(CGRectContainsPoint(gridViewItem.contentFrame, pointInItemView))
        {
            return indexForItemAtLocation;
        }
    
        
    }
    
    return NSNotFound;
}

// this is used by the drag select -- added by scott
- (NSUInteger)indexForItemAtLocationNoSpace:(NSPoint)location
{
    NSPoint point = [self convertPoint:location fromView:nil];
    
    if(!CGRectContainsPoint(self.bounds, point))
    {
        return NSNotFound;
    }
    
    NSUInteger indexForItemAtLocation = NSNotFound;
    
    NSUInteger columns = [self columnsInGridView];
    CGFloat space = (self.frame.size.width - (columns * self.itemSize.width)) / (columns + 1);
    
    /*if (point.x > ((self.itemSize.width+space) * [self columnsInGridView])) {
        indexForItemAtLocation = NSNotFound;
        
    } else {*/
    
        NSUInteger currentColumn = floor(point.x / ((self.itemSize.width+space)+space));
        NSUInteger currentRow = floor(point.y / self.itemSize.height);
        indexForItemAtLocation = currentRow * [self columnsInGridView] + currentColumn;
        indexForItemAtLocation = (indexForItemAtLocation > (numberOfItems - 1) ? NSNotFound : indexForItemAtLocation);
    //}
    
    
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
     //[[self window ] disableScreenUpdatesUntilFlush];
        
    numberOfItems = [self gridView:self numberOfItemsInSection:0];
    [keyedVisibleItems enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        CNGridViewItem * item = (CNGridViewItem *)obj;
        [item removeFromSuperview];
    }];
    
    [keyedVisibleItems removeAllObjects];
    [reuseableItems removeAllObjects];
    [self refreshGridViewAnimated:animated];
    
    //[[self window] enableFlushWindow];
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

- (void)selectItemAtIndexMouseDown:(NSUInteger)selectedItemIndex usingModifierFlags:(NSUInteger)modifierFlags
{
    if (selectedItemIndex == NSNotFound)
    {
        return;
    }
        

    CNGridViewItem *gridViewItem = nil;

    /*
    if (lastSelectedItemIndex != NSNotFound && lastSelectedItemIndex != selectedItemIndex) {
        gridViewItem = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:lastSelectedItemIndex]];
        [self deSelectItem:gridViewItem];
    }*/

    gridViewItem = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:selectedItemIndex]];
    if (gridViewItem) {
        
        // if we're in multiselect mode or the user is holding down command (same action)
        if (self.allowsMultipleSelection || modifierFlags & NSCommandKeyMask) {
            if (!gridViewItem.selected) {
                
                if(modifierFlags & NSShiftKeyMask)
                {
                    [self gridView:self didShiftSelectItemAtIndex:selectedItemIndex inSection:0];
                }
                
                else
                {
                    [self selectItem:gridViewItem];
                }
                shouldDeselectOnMouseUpIndex = -1;
            } else {
                
                // dont deselect items on mouse down. Instead deselect on mouse up (more fluid user experience)
                shouldDeselectOnMouseUpIndex = selectedItemIndex;
            }

        } else {
            
            [self selectItem:gridViewItem];
            
        }
        
        lastSelectedItemIndex = selectedItemIndex;
    }
}

- (void)selectItemAtIndexMouseUp:(NSUInteger)selectedItemIndex usingModifierFlags:(NSUInteger)modifierFlags
{
    if (selectedItemIndex == NSNotFound)
    {
        return;
    }
    
    
    CNGridViewItem *gridViewItem = nil;
    
    if (lastSelectedItemIndex != NSNotFound && lastSelectedItemIndex != selectedItemIndex) {
        gridViewItem = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:lastSelectedItemIndex]];
        [self deSelectItem:gridViewItem];
    }
    
    gridViewItem = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:selectedItemIndex]];
    
    // if we're in multiselect mode or the user is holding down command (same action)
    if (self.allowsMultipleSelection || modifierFlags & NSCommandKeyMask) {
        if (shouldDeselectOnMouseUpIndex == selectedItemIndex) {
            [self deSelectItem:gridViewItem];
        }
    }
    
    // clear this flag out so we don't deslect again
    shouldDeselectOnMouseUpIndex = -1;
}


- (void)selectItem:(CNGridViewItem *)theItem
{
    /// inform the delegate
    [self gridView:self willSelectItemAtIndex:theItem.index inSection:0];

    theItem.selected = YES;

    /// inform the delegate
    [self gridView:self didSelectItemAtIndex:theItem.index inSection:0];
    
}

- (void)deSelectItem:(CNGridViewItem *)theItem
{
    /// inform the delegate
    [self gridView:self willDeselectItemAtIndex:theItem.index inSection:0];

    theItem.selected = NO;

    /// inform the delegate
    [self gridView:self didDeselectItemAtIndex:theItem.index inSection:0];
}


- (void)reloadSelection
{
    // loop through all items on the screen and set their selection 
    [[self indexesForVisibleItems] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
      
        CNGridViewItem *selectedItem = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:idx]];
        selectedItem.selected = [self gridView:self itemIsSelectedAtIndex:idx inSection:0];
        
    }];
    
}

- (CNGridViewItem *)scrollToAndReturnItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    // scroll to this index
    
    NSPoint point = [self rectForItemAtIndex:index].origin;
    point.x = 0;
    
    
    CGFloat scrollY = -1;
    
    // if we need to scroll
    if (point.y-self.headerSpace < self.clippedRect.origin.y)
    {
        scrollY = point.y - self.headerSpace;
    }
    
    else if(point.y+self.itemSize.height > self.clippedRect.origin.y + self.clippedRect.size.height)
    {
        scrollY = (point.y+self.itemSize.height)-self.clippedRect.size.height;
    }
    
    if(scrollY != -1)
    {
        if(animated)
        {
            [NSAnimationContext beginGrouping];
            NSClipView* clipView = [[self enclosingScrollView] contentView];
            NSPoint newOrigin = [clipView bounds].origin;
            newOrigin.y = scrollY;
            [[clipView animator] setBoundsOrigin:newOrigin];
            [NSAnimationContext endGrouping];
        }
        
        else
        {
            [self scrollPoint:NSMakePoint(0, scrollY)];
        }
    }
    
    
    
    CNGridViewItem * item = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:index]];
    
    return item;
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
    shouldDeselectOnMouseUpIndex = -1;
    if (selectedItemIndex == NSNotFound)
        return;
    
    [self gridViewDidDeselectAllItems:self];
    [self selectItemAtIndexMouseDown:selectedItemIndex usingModifierFlags:[NSEvent modifierFlags]];
    
    

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
        
        CGFloat posX = ceil((location.x > selectionFrameInitialPoint.x ? selectionFrameInitialPoint.x : location.x));
        posX = (posX < NSMinX(clippedRect) ? NSMinX(clippedRect) : posX);
            
        CGFloat posY = ceil((location.y > selectionFrameInitialPoint.y ? selectionFrameInitialPoint.y : location.y));
        posY = (posY < NSMinY(clippedRect) ? NSMinY(clippedRect) : posY);
        
        CGFloat width = (location.x > selectionFrameInitialPoint.x ? location.x - selectionFrameInitialPoint.x : selectionFrameInitialPoint.x - posX);
        width = (posX + width >= (self.bounds.size.width) ? (self.bounds.size.width) - posX - 1 : width);

        CGFloat height = (location.y > selectionFrameInitialPoint.y ? location.y - selectionFrameInitialPoint.y : selectionFrameInitialPoint.y - posY);
        height = (posY + height > NSMaxY(clippedRect) ? NSMaxY(clippedRect) - posY : height);

        NSRect selectionFrame = NSMakeRect(posX, posY, width, height);
        selectionFrameView.frame = selectionFrame;
    }
}

- (void)selectItemsCoveredBySelectionFrame:(NSRect)selectionFrame usingModifierFlags:(NSUInteger)modifierFlags
{
    // loop through all items on the screen
    [[self indexesForVisibleItems] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        CNGridViewItem *item = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:idx]];
                
        if (item) {

            // if the content rect of the item intersects the selection frame then mark it as selected
            
            CGRect contentFrameInMainView = [self convertRect:item.contentFrame fromView:item];
            
            if (CGRectIntersectsRect(contentFrameInMainView, selectionFrame))
            {
                item.selected = YES;
                [selectedItemsBySelectionFrame setObject:item forKey:[NSNumber numberWithInteger:item.index]];
                
            }
            
            
            // if the item is out of the list remove it from the selected item list (and put it back to the way it was)
            else
            {
                // check if this item was previously selected
                if([self gridView:self itemIsSelectedAtIndex:idx inSection:0] == YES)
                {
                    item.selected = YES;
                }
                
                else
                {
                    item.selected = NO;
                }
                
                [selectedItemsBySelectionFrame removeObjectForKey:[NSNumber numberWithInteger:item.index]];
            }
        }
    }];

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
   // BOOL animated = (self.frame.size.width == frameRect.size.width ? NO: YES);
    [super setFrame:frameRect];
    [self refreshGridViewAnimated:NO];
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
#pragma mark -
#pragma mark NSResponder

-(BOOL)acceptsFirstResponder
{
    return YES;
}

#pragma mark Mouse handlers

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

- (void)mouseExited:(NSEvent *)theEvent
{
    lastHoveredIndex = NSNotFound;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [self.window makeFirstResponder:self];
    
    if (!self.allowsSelection)
        return;
    
    NSPoint location = [theEvent locationInWindow];
    NSUInteger index = [self indexForItemAtLocation:location];
    
    // if we're clicking on a contect rect then handl selection stuff
    if(index != NSNotFound)
    {
        // any drags that start with this click down will be for drag and drop, not selection box
        mouseDragSelectMode = NO;
        selectionFrameInitialPoint = location;
        
        // check for a double click right at mouse down to make this react faster -- scott
        if([clickEvents count] >= 1)
        {
            NSUInteger indexClick1 = [self indexForItemAtLocation:[[clickEvents objectAtIndex:0] locationInWindow]];
            if (indexClick1 == index) {
                [self handleDoubleClickForItemAtIndex:indexClick1];
                
                [clickEvents removeAllObjects];
                [clickTimer invalidate];
                clickTimer = nil;
                
                
                return;
            }
        }
        
        
        // else if this was not selected then select (will deselect on mouseup instead of mousedown
        [self selectItemAtIndexMouseDown:index usingModifierFlags:theEvent.modifierFlags];
    }
    
    else
    {
        // any drags that start with this click down will be for a selection box
        mouseDragSelectMode = YES;
    }
    
    
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    NSPoint location = [theEvent locationInWindow];
    /// inform the delegate
    [self gridView:self rightMouseButtonClickedOnItemAtIndex:[self indexForItemAtLocation:location] inSection:0 andEvent:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if (!self.allowsMultipleSelection)
        return;

    mouseHasDragged = YES;
    [NSCursor closedHandCursor];

    // if we're dragging a selection (Drag started off a content rect)
    if (!abortSelection && mouseDragSelectMode) {
        NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        [self drawSelectionFrameForMousePointerAtLocation:location];
        [self selectItemsCoveredBySelectionFrame:selectionFrameView.frame usingModifierFlags:theEvent.modifierFlags];
    }
    
    // if we're dragging for drag and drop (Drag started over a content rect)
    if(!mouseDragSelectMode)
    {
        // if the location has moved at least 10 pixels from the initial mousedown point
        CGPoint location = [theEvent locationInWindow];
        
        CGFloat dx = abs(location.x - selectionFrameInitialPoint.x);
        CGFloat dy = abs(location.y - selectionFrameInitialPoint.y);
        
        if(dx > 10 || dy > 10)
        {
            NSUInteger itemIndex = [self indexForItemAtLocation:theEvent.locationInWindow];
            [self gridView:self dragDidBeginAtIndex:itemIndex inSection:0 andEvent:theEvent];
        }
            
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [NSCursor arrowCursor];
    
    // get the index clicked up in
    NSPoint location = [theEvent locationInWindow];
    NSInteger index = [self indexForItemAtLocation:location];
    
    // this will only deselect the same object we clicked down in, so we're save to do this first
    if(index != NSNotFound)
    {
        // if we're clicking up while on a selected item
        // else if this was not selected then deselect --scott
        [self selectItemAtIndexMouseUp:index usingModifierFlags:theEvent.modifierFlags];
    }

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
        
        // if we're clicking up while not on any item then deselect all -- scott
        
        if(index == NSNotFound)
        {
            [self gridViewDidDeselectAllItems:self];
            return;
        }
        
        
        //  start the click event timer -- scott
        [clickEvents addObject:theEvent];
        clickTimer = nil;
        clickTimer = [NSTimer scheduledTimerWithTimeInterval:[NSEvent doubleClickInterval] target:self selector:@selector(handleClicks:) userInfo:nil repeats:NO]; 
    }
}

#pragma mark Keyboard handlers

- (void)keyDown:(NSEvent*)event
{
    BOOL localEvent = NO;
    
    if ([event type] == NSKeyDown)
    {
        NSString* pressedChars = [event characters];
        if ([pressedChars length] == 1)
        {
            unichar pressedUnichar =
            [pressedChars characterAtIndex:0];
            
            if ( (pressedUnichar == NSDeleteCharacter) || // delete forward
                (pressedUnichar == 0xf728) || // delete backward
                pressedUnichar == NSCarriageReturnCharacter)
            {
                localEvent = YES;
            }
            
            // map space to newline as well (open it)
            if(pressedUnichar == ' ')
            {
                [self insertNewline:nil];
                return;
            }
            
            
        }
    }
    
    // If it was a delete key, handle the event specially, otherwise call
    if (localEvent)
    {
        // This will end up calling deleteBackward: or deleteForward:.
        [self interpretKeyEvents:[NSArray arrayWithObject:event]];
    }
    else
    {
        [super keyDown:event];
    }
}

/*
 
// don't use this, we need escape to get out of fullscreen mode
-(void)cancelOperation:(id)sender
{
    // escape key pressed
    [self gridViewDidDeselectAllItems:self];
}*/

-(void)deleteForward:(id)sender
{
    if([self.delegate respondsToSelector:@selector(gridViewDeleteKeyPressed:)])
    {
        [self.delegate gridViewDeleteKeyPressed:self];
    }
}

-(void)deleteBackward:(id)sender
{
    if([self.delegate respondsToSelector:@selector(gridViewDeleteKeyPressed:)])
    {
        [self.delegate gridViewDeleteKeyPressed:self];
    }
}

// return key pressed
-(void)insertNewline:(id)sender
{
    if(lastSelectedItemIndex != NSNotFound &&
       [[keyedVisibleItems objectForKey:[NSNumber numberWithInteger:lastSelectedItemIndex]] selected])
    {
        if([self.delegate respondsToSelector:@selector(gridView:didKeyOpenItemAtIndex:inSection:)])
        {
            [self.delegate gridView:self didKeyOpenItemAtIndex:lastSelectedItemIndex inSection:0];
        }
    }
}



-(void)moveRight:(id)sender
{
    NSUInteger newIndex = 0;
    
    if(lastSelectedItemIndex != NSNotFound &&
       [[keyedVisibleItems objectForKey:[NSNumber numberWithInteger:lastSelectedItemIndex]] selected])
    {
        CNItemPoint lastSelectedPoint = [self locationForItemAtIndex:lastSelectedItemIndex];
        
        if(lastSelectedPoint.column < self.columnsInGridView)
        {
            lastSelectedPoint.column++;
        }
        
        else
        {
            return; // do nothing if we're at the furthest right column
        }
        
        newIndex = lastSelectedPoint.column-1 + ((lastSelectedPoint.row-1) * self.columnsInGridView);
        
        if(newIndex >= numberOfItems)
        {
            newIndex = numberOfItems-1;
        }
        
    }
    
    if([self.delegate respondsToSelector:@selector(gridView:didKeySelectItemAtIndex:inSection:)])
    {
        [self.delegate gridView:self didKeySelectItemAtIndex:newIndex inSection:0];
    }
    
    // scroll to keep the item visible
    [self scrollToAndReturnItemAtIndex:newIndex animated:YES];
    
    // do this after the delegate call because that will probably call reloadSelection
    lastSelectedItemIndex = newIndex;
}

-(void)moveLeft:(id)sender
{
    NSUInteger newIndex = 0;
    
    if(lastSelectedItemIndex != NSNotFound &&
       [[keyedVisibleItems objectForKey:[NSNumber numberWithInteger:lastSelectedItemIndex]] selected])
    {
        CNItemPoint lastSelectedPoint = [self locationForItemAtIndex:lastSelectedItemIndex];
        
        if(lastSelectedPoint.column > 1)
        {
            lastSelectedPoint.column--;
        }
        
        else
        {
            return; // do nothing if we're at the furthest left column
        }
        
        newIndex = lastSelectedPoint.column-1 + ((lastSelectedPoint.row-1) * self.columnsInGridView);
        
    }
    
    if([self.delegate respondsToSelector:@selector(gridView:didKeySelectItemAtIndex:inSection:)])
    {
        [self.delegate gridView:self didKeySelectItemAtIndex:newIndex inSection:0];
    }
    
    // scroll to keep the item visible
    [self scrollToAndReturnItemAtIndex:newIndex animated:YES];
    
    // do this after the delegate call because that will probably call reloadSelection
    lastSelectedItemIndex = newIndex;
}

-(void)moveUp:(id)sender
{
    NSUInteger newIndex = 0;
    
    if(lastSelectedItemIndex != NSNotFound &&
       [[keyedVisibleItems objectForKey:[NSNumber numberWithInteger:lastSelectedItemIndex]] selected])
    {
        CNItemPoint lastSelectedPoint = [self locationForItemAtIndex:lastSelectedItemIndex];
        
        if(lastSelectedPoint.row > 1)
        {
            lastSelectedPoint.row--;
        }
        
        else
        {
            return; // do nothing if we're at the top
        }
        
        newIndex = lastSelectedPoint.column-1 + ((lastSelectedPoint.row-1) * self.columnsInGridView);
        
    }
    
    if([self.delegate respondsToSelector:@selector(gridView:didKeySelectItemAtIndex:inSection:)])
    {
        [self.delegate gridView:self didKeySelectItemAtIndex:newIndex inSection:0];
    }
    
    // scroll to keep the item visible
    [self scrollToAndReturnItemAtIndex:newIndex animated:YES];
    
    
    // do this after the delegate call because that will probably call reloadSelection
    lastSelectedItemIndex = newIndex;
}

-(void)moveDown:(id)sender
{
    NSUInteger newIndex = 0;
    
    if(lastSelectedItemIndex != NSNotFound &&
       [[keyedVisibleItems objectForKey:[NSNumber numberWithInteger:lastSelectedItemIndex]] selected])
    {
        CNItemPoint lastSelectedPoint = [self locationForItemAtIndex:lastSelectedItemIndex];
        
        if(lastSelectedPoint.row <= (int)(numberOfItems / self.columnsInGridView))
        {
            lastSelectedPoint.row++;
        }
        
        else
        {
            return; // do nothing if we're at the top
        }
        
        
        newIndex = lastSelectedPoint.column-1 + ((lastSelectedPoint.row-1) * self.columnsInGridView);
        
        if(newIndex >= numberOfItems)
        {
            newIndex = numberOfItems-1;
        }
        
        if(newIndex == lastSelectedItemIndex)
        {
            return; // do nothing if we're at the end
        }
        
    }
    
    if([self.delegate respondsToSelector:@selector(gridView:didKeySelectItemAtIndex:inSection:)])
    {
        [self.delegate gridView:self didKeySelectItemAtIndex:newIndex inSection:0];
    }
    
    // scroll to keep the item visible
    [self scrollToAndReturnItemAtIndex:newIndex animated:YES];
    
    // do this after the delegate call because that will probably call reloadSelection
    lastSelectedItemIndex = newIndex;
}



#pragma mark - Leap Responder
-(void)singleFingerPoint:(NSPoint)normalizedPosition
{
    if(self.window == nil) return;
    
    
    static NSUInteger lastPointed = -1;
    
    //first, denormailize the point
    NSPoint pointInWindow = NSMakePoint((self.window.frame.size.width * normalizedPosition.x),
                                      (self.window.frame.size.height * normalizedPosition.y));
    
    NSUInteger index = [self indexForItemAtLocationNoSpace:pointInWindow];
    
    
    
    //DLog(@"Index pointed at: %d", index);
    
    //CNGridViewItem * item = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:index]];
    //[item setSelected:YES];
    
    if(index != lastPointed && index != NSNotFound)
    {
        lastPointed = index;
        
        if([self.delegate respondsToSelector:@selector(gridView:didPointItemAtIndex:inSection:)])
        {
            [self.delegate gridView:self didPointItemAtIndex:index inSection:0];
        }
    }
    
    
    // scroll the grid view if we're near the edges
    if(normalizedPosition.y < .2)
    {
        
        float scrollChange = pow(((normalizedPosition.y - 0.2) * 15), 2);
        NSPoint currentPoint = NSMakePoint([self clippedRect].origin.x, [self clippedRect].origin.y);
        
        currentPoint.y += scrollChange;
        
        [self scrollPoint:currentPoint];
    }
    
    else if(normalizedPosition.y > .8)
    {
        
        float scrollChange = pow(((normalizedPosition.y - 0.8) * 15), 2);
        NSPoint currentPoint = NSMakePoint([self clippedRect].origin.x, [self clippedRect].origin.y);
        
        currentPoint.y -= scrollChange;
        
        [self scrollPoint:currentPoint];
    }
    
}

-(void)singleFingerSelect:(NSPoint)normalizedPosition
{
    if(self.window == nil) return;
    
    //static NSUInteger lastPointed = -1;
    
    //first, denormailize the point
    NSPoint pointInView = NSMakePoint((self.clippedRect.size.width * normalizedPosition.x),
                                      (self.clippedRect.size.height * normalizedPosition.y));
    
    NSUInteger index = [self indexForItemAtLocationNoSpace:pointInView];
    
    [self gridView:self didDoubleClickItemAtIndex:index inSection:0]; 
    
    //DLog(@"Index pointed at: %d", index);
    
    //CNGridViewItem * item = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:index]];
    //[item setSelected:YES];
    /*
    if(index != lastPointed && index != NSNotFound)
    {
        lastPointed = index;
        
        if([self.delegate respondsToSelector:@selector(gridView:didPointItemAtIndex:inSection:)])
        {
            [self.delegate gridView:self didPointItemAtIndex:index inSection:0];
        }
    }*/
    
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

- (void)gridView:(CNGridView*)gridView didShiftSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    /*[nc postNotificationName:CNGridViewDidSelectItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];*/
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView didShiftSelectItemAtIndex:index inSection:section];
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
    
    [self reloadSelection];
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

- (void)gridView:(CNGridView *)gridView rightMouseButtonClickedOnItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event
{
    [nc postNotificationName:CNGridViewRightMouseButtonClickedOnItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView rightMouseButtonClickedOnItemAtIndex:index inSection:section andEvent:event];
    }
}

- (void)gridView:(CNGridView *)gridView dragDidBeginAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event;
{
    /*[nc postNotificationName:CNGridViewDragDidBeginNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];*/
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView dragDidBeginAtIndex:index inSection:section andEvent:event];
    }
}

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
    if([self.delegate respondsToSelector:@selector(dropOperationsForDrag:)])
    {
        return [self.delegate dropOperationsForDrag:sender];
    }
    
    return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender
{
    if([self.delegate respondsToSelector:@selector(prepareForDragOperation:)])
    {
        return [self.delegate prepareForDragOperation:sender];
    }
    
    return NO;
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
{
    if([self.delegate respondsToSelector:@selector(performDragOperation:)])
    {
        return [self.delegate performDragOperation:sender];
    }
    
    return NO;
}

- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender
{
    if([self.delegate respondsToSelector:@selector(draggingUpdated:)])
    {
        return [self.delegate draggingUpdated:sender];
    }
    
    return NSDragOperationNone;
}

- (void)draggingExited:(id < NSDraggingInfo >)sender
{
    ;
}

- (void)draggingEnded:(id < NSDraggingInfo >)sender
{
    ;
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
        
- (BOOL)gridView:(CNGridView *)gridView itemIsSelectedAtIndex:(NSInteger)index inSection:(NSInteger)section
{
    if ([self.dataSource respondsToSelector:_cmd]) {
        return [self.dataSource gridView:gridView itemIsSelectedAtIndex:index inSection:section];
    }
    return NO;
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