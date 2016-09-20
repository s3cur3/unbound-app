//
//  PIXGridView.m
//  UnboundApp
//
//  Created by Ditriol Wei on 29/7/16.
//  Copyright © 2016 Pixite Apps LLC. All rights reserved.
//

#import "PIXGridView.h"

PIXItemPoint PIXMakeItemPoint(NSUInteger aColumn, NSUInteger aRow) {
    PIXItemPoint point;
    point.column = aColumn;
    point.row = aRow;
    return point;
}

@interface PIXSelectionFrameView : NSView
@end

@implementation PIXGridView{
    CGPoint selectionFrameInitialPoint;
    BOOL mouseDragSelectMode;
    NSMutableArray * clickEvents;
    NSMutableDictionary *selectedItemsBySelectionFrame;
    NSTimer *clickTimer;
    NSInteger shouldDeselectOnMouseUpIndex;
    NSInteger lastSelectedItemIndex;
    BOOL mouseHasDragged;
    BOOL abortSelection;
    PIXSelectionFrameView *selectionFrameView;
}

- (void)awakeFromNib
{
    _itemSize = NSMakeSize(200, 200);
    _headerSpace = 0;

    clickEvents = [[NSMutableArray alloc] init];
    selectedItemsBySelectionFrame = [[NSMutableDictionary alloc] init];
    lastSelectedItemIndex = NSNotFound;
    mouseHasDragged = NO;
    abortSelection = NO;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)setBackgroundColor:(NSColor *)c
{
    if( c != nil )
        [self setBackgroundColors:@[c, c]];
}

- (void)setItemSize:(NSSize)s
{
    _itemSize = s;
    
    self.maxItemSize = s;
    self.minItemSize = s;
    
    dispatch_block_t block = ^(void){
        NSInteger nCnt = [self.content count];
        for( NSInteger i = 0 ; i < nCnt ; i++ )
        {
            PIXCollectionViewItem * item = (PIXCollectionViewItem *)[self itemAtIndex:i];
            [item refresh];
        }
    };
    
    if( [NSThread isMainThread] )
        block();
    else
        dispatch_sync(dispatch_get_main_queue(), block);
}

- (void)setScrollElasticity:(BOOL)scrollElasticity
{
    _scrollElasticity = scrollElasticity;
    NSScrollView *scrollView = [self enclosingScrollView];
    if (_scrollElasticity) {
        [scrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
        [scrollView setVerticalScrollElasticity:NSScrollElasticityAllowed];
    } else {
        [scrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
        [scrollView setVerticalScrollElasticity:NSScrollElasticityNone];
    }
}

- (PIXCollectionViewItem *)scrollToAndReturnItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    // scroll to this index
    NSPoint point = [self frameForItemAtIndex:index].origin;
    point.x = 0;
    
    CGFloat currentY = self.visibleRect.origin.y;
    CGFloat scrollY = -1;
    
    // if we need to scroll up
    if (point.y-self.headerSpace < currentY)
    {
        scrollY = point.y - self.headerSpace;
    }
    
    // if we need to scroll down
    else if(point.y+self.itemSize.height > self.visibleRect.origin.y + self.visibleRect.size.height)
    {
        scrollY = (point.y+self.itemSize.height)-self.visibleRect.size.height;
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
    
    PIXCollectionViewItem * item = (PIXCollectionViewItem *)[self itemAtIndex:index];
    return item;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSResponder

-(BOOL)acceptsFirstResponder
{
    return YES;
}

#pragma mark Mouse handlers
- (void)mouseDown:(NSEvent *)theEvent
{
    // not sure why, but we need to manually support ctrl+click for right mouse
    if (theEvent.modifierFlags & NSControlKeyMask)
        return [self rightMouseDown:theEvent];
    
    [self.window makeFirstResponder:self];
    
//    if (!self.selectable )
//        return;
    
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
        
        CGFloat dx = fabs(location.x - selectionFrameInitialPoint.x);
        CGFloat dy = fabs(location.y - selectionFrameInitialPoint.y);
        
        if(dx > 10 || dy > 10)
        {
            NSUInteger itemIndex = [self indexForItemAtLocation:theEvent.locationInWindow];
            [self gridView:self dragDidBeginAtIndex:itemIndex inSection:0 andEvent:theEvent];
        }
        
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSLog(@"CNGridView.m: mouseUp");
    [NSCursor arrowCursor];
    
    // get the index clicked up in
    NSPoint location = [theEvent locationInWindow];
    NSInteger index = [self indexForItemAtLocation:location];
    
    
    
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
            
            if ([(PIXCollectionViewItem *)obj isSelected] == YES) {
                [self selectItem:obj];
                // } else {
                //     [self deSelectItem:obj];
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
        
        // this will only deselect the same object we clicked down in, so we're safe to do this first
        else
        {
            // if we're clicking up while on a selected item
            // else if this was not selected then deselect --scott
            [self selectItemAtIndexMouseUp:index usingModifierFlags:theEvent.modifierFlags];
        }
        
        
        //  start the click event timer -- scott
        [clickEvents addObject:theEvent];
        clickTimer = nil;
        clickTimer = [NSTimer scheduledTimerWithTimeInterval:[NSEvent doubleClickInterval] target:self selector:@selector(handleClicks:) userInfo:nil repeats:NO];
    }
}

- (void)handleClicks:(NSTimer *)theTimer
{
    switch ([clickEvents count]) {
        case 1: {
            NSEvent *theEvent = [clickEvents lastObject];
            NSUInteger index = [self indexForItemAtLocation:theEvent.locationInWindow];
            [self handleSingleClickForItemAtIndex:index];
            break;
        }
            
        case 2: {
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
            
        case 3: {
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

- (NSUInteger)indexForItemAtLocation:(NSPoint)location
{
    NSPoint point = [self convertPoint:location fromView:nil];
    NSUInteger indexForItemAtLocation;
    
    NSUInteger columns = [self columnsInGridView];
    CGFloat space = 0;//(self.frame.size.width - (columns * self.itemSize.width)) / (columns + 1);
    
    NSUInteger currentColumn = floor(point.x / (self.itemSize.width+space));
    NSUInteger currentRow = floor((point.y-self.headerSpace) / self.itemSize.height);
    indexForItemAtLocation = currentRow * columns + currentColumn;
    indexForItemAtLocation = (indexForItemAtLocation > ([self.content count] - 1) ? NSNotFound : indexForItemAtLocation);
    
    // now check that we're inside of the contentFrame rect
    if (indexForItemAtLocation != NSNotFound)
    {
        PIXCollectionViewItem * gridViewItem = (PIXCollectionViewItem *)[self itemAtIndex:indexForItemAtLocation];
        PIXCollectionViewItemView * gridViewItemView = (PIXCollectionViewItemView *)gridViewItem.view;
        NSPoint pointInItemView = [gridViewItemView convertPoint:location fromView:nil];
        
        if(CGRectContainsPoint(gridViewItemView.contentFrame, pointInItemView))
        {
            return indexForItemAtLocation;
        }
    }
    
    return NSNotFound;
}

- (PIXItemPoint)locationForItemAtIndex:(NSUInteger)itemIndex
{
    NSUInteger columnsInGridView = [self columnsInGridView];
    NSUInteger row = floor(itemIndex / columnsInGridView) + 1;
    NSUInteger column = itemIndex - floor((row -1) * columnsInGridView) + 1;
    PIXItemPoint location = PIXMakeItemPoint(column, row);
    return location;
}

- (NSIndexSet *)indexesForVisibleItems
{
    __block NSMutableIndexSet *indexesForVisibleItems = [[NSMutableIndexSet alloc] init];
    
    NSRect visibleRect = [self visibleRect];
    NSInteger nCols = [self columnsInGridView];
    
    NSInteger nRows = visibleRect.origin.y/self.itemSize.height-1;
    if( nRows < 0 )
        nRows = 0;
    
    CGFloat Y = NSMaxY(visibleRect)+self.itemSize.height+5;
    while( Y > nRows*self.itemSize.height )
    {
        for( NSInteger i = 0 ; i < nCols ; i++ )
        {
            NSInteger idx = nRows*nCols+i;
            if( idx >= [self.content count] )
                break;
            [indexesForVisibleItems addIndex:nRows*nCols+i];
        }
        nRows++;
    }
    
    /*
    [keyedVisibleItems enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [indexesForVisibleItems addIndex:[(CNGridViewItem *)obj index]];
    }];*/
    return indexesForVisibleItems;
}

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
    
    // if we're out of range, find the closest item (by column for leap)
    if(indexForItemAtLocation > ([self.content count] - 1))
    {
        while(indexForItemAtLocation > ([self.content count] - 1))
        {
            
            // if we can go up a row, do that first
            if(currentRow > 0)
            {
                currentRow--;
                indexForItemAtLocation = currentRow * [self columnsInGridView] + currentColumn;
            }
            
            // otherwise, go up a column
            else
            {
                currentColumn--;
                indexForItemAtLocation = currentRow * [self columnsInGridView] + currentColumn;
            }
        }
        
        // if we still havent found the item (there are none)
        if(indexForItemAtLocation > ([self.content count] - 1))
        {
            indexForItemAtLocation = NSNotFound;
        }
    }
    //}
    
    return indexForItemAtLocation;
}

- (NSUInteger)columnsInGridView
{
    NSRect visibleRect  = [self clippedRect];
    NSUInteger columns = floorf((float)NSWidth(visibleRect) / self.itemSize.width);
    columns = (columns < 1 ? 1 : columns);
    return columns;
}

- (NSRect)clippedRect
{
    if([self respondsToSelector:@selector(preparedContentRect)])
    {
        CGRect prepped = [self preparedContentRect];
        
        if(prepped.size.width == self.bounds.size.width)
        {
            return prepped;
        }
    }
    
    return [[[self enclosingScrollView] contentView] bounds];
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
    
    
    double delayInSeconds = 0.05;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        /// inform the delegate
        [self gridView:self didDoubleClickItemAtIndex:selectedItemIndex inSection:0];
    });
    
}

- (void)reloadSelection
{
    // loop through all items on the screen and set their selection
    /*
    [[self indexesForVisibleItems] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        PIXCollectionViewItem * item = (PIXCollectionViewItem *)[self itemAtIndex:idx];
        item.selected = [self gridView:self itemIsSelectedAtIndex:idx inSection:0];
        
        if( item.selected )
            lastSelectedItemIndex = idx;
    }];
     */
    
    NSInteger nCnt = [self.content count];
    for( NSInteger idx = 0 ; idx < nCnt ; idx++ )
    {
        PIXCollectionViewItem * item = (PIXCollectionViewItem *)[self itemAtIndex:idx];
        item.selected = [self gridView:self itemIsSelectedAtIndex:idx inSection:0];
        
        if( item.selected )
            lastSelectedItemIndex = idx;
    }
}

- (void)selectItemAtIndexMouseDown:(NSUInteger)selectedItemIndex usingModifierFlags:(NSUInteger)modifierFlags
{
    if (selectedItemIndex == NSNotFound)
    {
        return;
    }
    
    
    PIXCollectionViewItem * gridViewItem = (PIXCollectionViewItem *)[self itemAtIndex:selectedItemIndex];
    
    /*
     if (lastSelectedItemIndex != NSNotFound && lastSelectedItemIndex != selectedItemIndex) {
     gridViewItem = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:lastSelectedItemIndex]];
     [self deSelectItem:gridViewItem];
     }*/
    
//    gridViewItem = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:selectedItemIndex]];
//    if (gridViewItem) {
    
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
//    }
}

- (void)selectItem:(PIXCollectionViewItem *)theItem
{
    NSUInteger index = [self.content indexOfObject:theItem.representedObject];
    
    /// inform the delegate
    [self gridView:self willSelectItemAtIndex:index inSection:0];
    
    theItem.selected = YES;
    
    /// inform the delegate
    [self gridView:self didSelectItemAtIndex:index inSection:0];
    
}

- (void)deSelectItem:(PIXCollectionViewItem *)theItem
{
    NSUInteger index = [self.content indexOfObject:theItem.representedObject];
    
    /// inform the delegate
    [self gridView:self willDeselectItemAtIndex:index inSection:0];
    
    theItem.selected = NO;
    
    /// inform the delegate
    [self gridView:self didDeselectItemAtIndex:index inSection:0];
}

- (void)drawSelectionFrameForMousePointerAtLocation:(NSPoint)location
{
    if (!selectionFrameView) {
        selectionFrameInitialPoint = location;
        selectionFrameView = [[PIXSelectionFrameView alloc] init];
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
        PIXCollectionViewItem * item = (PIXCollectionViewItem *)[self itemAtIndex:idx];
        PIXCollectionViewItemView * itemView = (PIXCollectionViewItemView *)item.view;
        //if (item) {
            
            // if the content rect of the item intersects the selection frame then mark it as selected
            
            CGRect contentFrameInMainView = [self convertRect:itemView.contentFrame fromView:itemView];
            
            if (CGRectIntersectsRect(contentFrameInMainView, selectionFrame))
            {
                item.selected = YES;
                [selectedItemsBySelectionFrame setObject:item forKey:[NSNumber numberWithInteger:idx]];
                
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
                
                [selectedItemsBySelectionFrame removeObjectForKey:[NSNumber numberWithInteger:idx]];
            }
        //}
    }];
    
}

- (void)selectItemAtIndexMouseUp:(NSUInteger)selectedItemIndex usingModifierFlags:(NSUInteger)modifierFlags
{
    if (selectedItemIndex == NSNotFound)
    {
        return;
    }
    
    
    PIXCollectionViewItem *gridViewItem = nil;
    
    if (lastSelectedItemIndex != NSNotFound && lastSelectedItemIndex != selectedItemIndex) {
        gridViewItem = (PIXCollectionViewItem *)[self itemAtIndex:lastSelectedItemIndex];
        [self deSelectItem:gridViewItem];
    }
    
    gridViewItem = (PIXCollectionViewItem *)[self itemAtIndex:selectedItemIndex];
    
    // if we're in multiselect mode or the user is holding down command (same action)
    if (self.allowsMultipleSelection || modifierFlags & NSCommandKeyMask) {
        if (shouldDeselectOnMouseUpIndex == selectedItemIndex) {
            [self deSelectItem:gridViewItem];
        }
    }
    
    // clear this flag out so we don't deslect again
    shouldDeselectOnMouseUpIndex = -1;
}

- (BOOL)isSubviewOfView:(NSView *)theView
{
    __block BOOL isSubView = NO;
    [[theView subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([self isEqualTo:(NSView *)obj]) {
            isSubView = YES;
            *stop = YES;
        }
    }];
    return isSubView;
}

- (BOOL)containsSubView:(NSView *)subview
{
    __block BOOL containsSubView = NO;
    [[self subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([subview isEqualTo:(NSView *)obj]) {
            containsSubView = YES;
            *stop = YES;
        }
    }];
    return containsSubView;
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
            
            // handle arrow keys as well
            if(pressedUnichar >= 63232 &&pressedUnichar <= 63235)
            {
                //localEvent = YES;
                
                switch (pressedUnichar) {
                    case 63232:
                        [self moveUp:event];
                        break;
                    case 63233:
                        [self moveDown:event];
                        break;
                    case 63234:
                        [self moveLeft:event];
                        break;
                    case 63235:
                        [self moveRight:event];
                        break;
                        
                    default:
                        break;
                }
                
                return;
            }
            
            if(pressedUnichar == '') // delete should delete items
            {
                [self deleteBackward:event];
                return;
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

- (void)deleteForward:(id)sender
{
    if([self.gridViewDelegate respondsToSelector:@selector(gridViewDeleteKeyPressed:)])
    {
        [self.gridViewDelegate gridViewDeleteKeyPressed:self];
    }
}

- (void)deleteBackward:(id)sender
{
    if([self.gridViewDelegate respondsToSelector:@selector(gridViewDeleteKeyPressed:)])
    {
        [self.gridViewDelegate gridViewDeleteKeyPressed:self];
    }
}

// return key pressed
- (void)insertNewline:(id)sender
{
    if( lastSelectedItemIndex != NSNotFound )
    {
        PIXCollectionViewItem * lastSelectedItem = (PIXCollectionViewItem *)[self itemAtIndex:lastSelectedItemIndex];
        if( lastSelectedItem.isSelected )
        {
            if([self.gridViewDelegate respondsToSelector:@selector(gridView:didKeyOpenItemAtIndex:inSection:)])
            {
                [self.gridViewDelegate gridView:self didKeyOpenItemAtIndex:lastSelectedItemIndex inSection:0];
            }
        }
    }
    
    /*
    if(lastSelectedItemIndex != NSNotFound &&
       [[keyedVisibleItems objectForKey:[NSNumber numberWithInteger:lastSelectedItemIndex]] selected])
    {
        if([self.delegate respondsToSelector:@selector(gridView:didKeyOpenItemAtIndex:inSection:)])
        {
            [self.delegate gridView:self didKeyOpenItemAtIndex:lastSelectedItemIndex inSection:0];
        }
    }
     */
}

- (void)moveRight:(id)sender
{
    NSUInteger newIndex = 0;
    
    if( lastSelectedItemIndex != NSNotFound && lastSelectedItemIndex < self.content.count)
    {
        PIXCollectionViewItem * lastSelectedItem = (PIXCollectionViewItem *)[self itemAtIndex:lastSelectedItemIndex];
        if( lastSelectedItem.isSelected )
        {
            PIXItemPoint lastSelectedPoint = [self locationForItemAtIndex:lastSelectedItemIndex];
            if(lastSelectedPoint.column < self.columnsInGridView)
            {
                lastSelectedPoint.column++;
                newIndex = lastSelectedPoint.column-1 + ((lastSelectedPoint.row-1) * self.columnsInGridView);
            }
            else
            {
                newIndex = lastSelectedPoint.column-1 + ((lastSelectedPoint.row-1) * self.columnsInGridView);
                newIndex++;
            }
            
            if(newIndex >= [self.content count])
            {
                newIndex = [self.content count]-1;
            }
        }
    }
    
    if([self.gridViewDelegate respondsToSelector:@selector(gridView:didKeySelectItemAtIndex:inSection:)])
    {
        [self.gridViewDelegate gridView:self didKeySelectItemAtIndex:newIndex inSection:0];
    }
    
    // scroll to keep the item visible
    [self scrollToAndReturnItemAtIndex:newIndex animated:YES];
    
    // do this after the delegate call because that will probably call reloadSelection
    lastSelectedItemIndex = newIndex;
}

- (void)moveLeft:(id)sender
{
    NSUInteger newIndex = 0;
    
    if( lastSelectedItemIndex != NSNotFound )
    {
        PIXCollectionViewItem * lastSelectedItem = (PIXCollectionViewItem *)[self itemAtIndex:lastSelectedItemIndex];
        if( lastSelectedItem.isSelected )
        {
            PIXItemPoint lastSelectedPoint = [self locationForItemAtIndex:lastSelectedItemIndex];
            if(lastSelectedPoint.column > 1)
            {
                lastSelectedPoint.column--;
                newIndex = lastSelectedPoint.column-1 + ((lastSelectedPoint.row-1) * self.columnsInGridView);
            }
            else
            {
                if( [self.gridViewDelegate respondsToSelector:@selector(gridViewDidPressLeftArrowKeyAtFirstColumn:)] )
                {
                    [self.gridViewDelegate gridViewDidPressLeftArrowKeyAtFirstColumn:self];
                    return;
                }

                if( lastSelectedPoint.row == 1 )
                    return;
                
                // if theres no responder for left then go up a row
                newIndex = lastSelectedPoint.column-1 + ((lastSelectedPoint.row-1) * self.columnsInGridView);
                newIndex--;
            }
        }
    }
    
    if([self.gridViewDelegate respondsToSelector:@selector(gridView:didKeySelectItemAtIndex:inSection:)])
    {
        [self.gridViewDelegate gridView:self didKeySelectItemAtIndex:newIndex inSection:0];
    }
    
    // scroll to keep the item visible
    [self scrollToAndReturnItemAtIndex:newIndex animated:YES];
    
    // do this after the delegate call because that will probably call reloadSelection
    lastSelectedItemIndex = newIndex;
}

- (void)moveUp:(id)sender
{
    NSUInteger newIndex = 0;
    
    if( lastSelectedItemIndex != NSNotFound )
    {
        PIXCollectionViewItem * lastSelectedItem = (PIXCollectionViewItem *)[self itemAtIndex:lastSelectedItemIndex];
        if( lastSelectedItem.isSelected )
        {
            PIXItemPoint lastSelectedPoint = [self locationForItemAtIndex:lastSelectedItemIndex];
            
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
    }
    
    if([self.gridViewDelegate respondsToSelector:@selector(gridView:didKeySelectItemAtIndex:inSection:)])
    {
        [self.gridViewDelegate gridView:self didKeySelectItemAtIndex:newIndex inSection:0];
    }
    
    // scroll to keep the item visible
    [self scrollToAndReturnItemAtIndex:newIndex animated:YES];
    
    // do this after the delegate call because that will probably call reloadSelection
    lastSelectedItemIndex = newIndex;
}

- (void)moveDown:(id)sender
{
    NSUInteger newIndex = 0;
    
    if( lastSelectedItemIndex != NSNotFound )
    {
        PIXCollectionViewItem * lastSelectedItem = (PIXCollectionViewItem *)[self itemAtIndex:lastSelectedItemIndex];
        if( lastSelectedItem.isSelected )
        {
            PIXItemPoint lastSelectedPoint = [self locationForItemAtIndex:lastSelectedItemIndex];
            
            if(lastSelectedPoint.row <= (int)([self.content count] / self.columnsInGridView))
            {
                lastSelectedPoint.row++;
            }
            else
            {
                return; // do nothing if we're at the top
            }
            
            newIndex = lastSelectedPoint.column-1 + ((lastSelectedPoint.row-1) * self.columnsInGridView);
            
            if(newIndex >= [self.content count])
            {
                newIndex = [self.content count]-1;
            }
            if(newIndex == lastSelectedItemIndex)
            {
                return; // do nothing if we're at the end
            }
        }
    }
    
    if([self.gridViewDelegate respondsToSelector:@selector(gridView:didKeySelectItemAtIndex:inSection:)])
    {
        [self.gridViewDelegate gridView:self didKeySelectItemAtIndex:newIndex inSection:0];
    }
    
    // scroll to keep the item visible
    [self scrollToAndReturnItemAtIndex:newIndex animated:YES];
    
    // do this after the delegate call because that will probably call reloadSelection
    lastSelectedItemIndex = newIndex;
}

#pragma mark - Delegate Calls
- (void)gridViewDidDeselectAllItems:(PIXGridView *)gridView
{
    //[nc postNotificationName:CNGridViewDidDeselectAllItemsNotification object:gridView userInfo:nil];
    if ([self.gridViewDelegate respondsToSelector:_cmd]) {
        [self.gridViewDelegate gridViewDidDeselectAllItems:gridView];
    }
    
    [self reloadSelection];
}

- (void)gridView:(PIXGridView*)gridView didShiftSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    /*[nc postNotificationName:CNGridViewDidSelectItemNotification
     object:gridView
     userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];*/
    if ([self.gridViewDelegate respondsToSelector:_cmd]) {
        [self.gridViewDelegate gridView:gridView didShiftSelectItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(PIXGridView*)gridView willSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
   /*[nc postNotificationName:CNGridViewWillSelectItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];*/
    if ([self.gridViewDelegate respondsToSelector:_cmd]) {
        [self.gridViewDelegate gridView:gridView willSelectItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(PIXGridView*)gridView didSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    /*[nc postNotificationName:CNGridViewDidSelectItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];*/
    if ([self.gridViewDelegate respondsToSelector:_cmd]) {
        [self.gridViewDelegate gridView:gridView didSelectItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(PIXGridView*)gridView willDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    /*[nc postNotificationName:CNGridViewWillDeselectItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];*/
    if ([self.gridViewDelegate respondsToSelector:_cmd]) {
        [self.gridViewDelegate gridView:gridView willDeselectItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(PIXGridView*)gridView didDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    /*[nc postNotificationName:CNGridViewDidDeselectItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];*/
    if ([self.gridViewDelegate respondsToSelector:_cmd]) {
        [self.gridViewDelegate gridView:gridView didDeselectItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(PIXGridView *)gridView didClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    /*[nc postNotificationName:CNGridViewDidClickItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];*/
    if ([self.gridViewDelegate respondsToSelector:_cmd]) {
        [self.gridViewDelegate gridView:gridView didClickItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(PIXGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    /*[nc postNotificationName:CNGridViewDidDoubleClickItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];*/
    if ([self.gridViewDelegate respondsToSelector:_cmd]) {
        [self.gridViewDelegate gridView:gridView didDoubleClickItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(PIXGridView *)gridView rightMouseButtonClickedOnItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event
{
    /*[nc postNotificationName:CNGridViewRightMouseButtonClickedOnItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];*/
    if ([self.gridViewDelegate respondsToSelector:_cmd]) {
        [self.gridViewDelegate gridView:gridView rightMouseButtonClickedOnItemAtIndex:index inSection:section andEvent:event];
    }
}

- (void)gridView:(PIXGridView *)gridView dragDidBeginAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event
{
    /*[nc postNotificationName:CNGridViewDragDidBeginNotification
     object:gridView
     userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:index] forKey:CNGridViewItemIndexKey]];*/
    if ([self.gridViewDelegate respondsToSelector:_cmd]) {
        [self.gridViewDelegate gridView:gridView dragDidBeginAtIndex:index inSection:section andEvent:event];
    }
}

- (BOOL)gridView:(PIXGridView *)gridView itemIsSelectedAtIndex:(NSInteger)index inSection:(NSInteger)section
{
    if ([self.gridViewDelegate respondsToSelector:_cmd]) {
        return [self.gridViewDelegate gridView:gridView itemIsSelectedAtIndex:index inSection:section];
    }
    return NO;
}

#pragma mark - Leap Responder
- (void)leapPointerPosition:(NSPoint)normalizedPosition
{
    if(self.window == nil) return;
    
    if(![self.window isKeyWindow]) return;
    
    
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
        lastSelectedItemIndex = index;
        
        if([self.gridViewDelegate respondsToSelector:@selector(gridView:didPointItemAtIndex:inSection:)])
        {
            [self.gridViewDelegate gridView:self didPointItemAtIndex:index inSection:0];
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

- (void)leapPointerSelect:(NSPoint)normalizedPosition
{
    if(self.window == nil) return;
    
    if(![self.window isKeyWindow]) return;
    
    [[NSSound soundNamed:@"click"] play];
    
    //static NSUInteger lastPointed = -1;
    
     //first, denormailize the point
//     NSPoint pointInView = NSMakePoint((self.clippedRect.size.width * normalizedPosition.x),
//     (self.clippedRect.size.height * normalizedPosition.y));
//     
//     NSUInteger index = [self indexForItemAtLocationNoSpace:pointInView];
    
    [self gridView:self didDoubleClickItemAtIndex:lastSelectedItemIndex inSection:0];
    
    //DLog(@"Index pointed at: %d", index);
    
    //CNGridViewItem * item = [keyedVisibleItems objectForKey:[NSNumber numberWithInteger:index]];
    //[item setSelected:YES];
//     if(index != lastPointed && index != NSNotFound)
//     {
//     lastPointed = index;
//     
//     if([self.delegate respondsToSelector:@selector(gridView:didPointItemAtIndex:inSection:)])
//     {
//     [self.delegate gridView:self didPointItemAtIndex:index inSection:0];
//     }
//     }
}

@end


@implementation PIXSelectionFrameView
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