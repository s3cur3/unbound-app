//
//  PIXOutlineView.m
//  UnboundApp
//
//  Created by Bob on 3/28/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXOutlineView.h"
#import "PIXSidebarTableCellView.h"
#import "PIXSidebarViewController.h"
#import "PIXViewController.h"

@implementation PIXOutlineView

- (void)mouseDown:(NSEvent *)theEvent {
    [super mouseDown:theEvent];
    
//    // Only take effect for double clicks; remove to allow for single clicks
//    if (theEvent.clickCount < 2) {
//        return;
//    }
//    
//    // Get the row on which the user clicked
//    NSPoint localPoint = [self convertPoint:theEvent.locationInWindow
//                                   fromView:nil];
//    NSInteger row = [self rowAtPoint:localPoint];
//    
//    // If the user didn't click on a row, we're done
//    if (row < 0) {
//        return;
//    }
//    
//    // Get the view clicked on
//    NSTableCellView *view = [self viewAtColumn:0 row:row makeIfNecessary:NO];
//    
//    // If the field can be edited, pop the editor into edit mode
//    if (view.textField.isEditable) {
//        [[view window] makeFirstResponder:view.textField];
//    }
}

- (void)rightMouseDown:(NSEvent *)theEvent;
{
    [super rightMouseDown:theEvent];
    NSPoint selfPoint = [self convertPoint:theEvent.locationInWindow fromView:nil];
    NSInteger row = [self rowAtPoint:selfPoint];
    if (row>=0) {
        PIXSidebarTableCellView *aView = (PIXSidebarTableCellView *)[self viewAtColumn:0 row:row makeIfNecessary:NO];
        [aView drawFocusRingMask];
        [aView setNeedsDisplay:YES];
        PIXSidebarViewController *aVC = (PIXSidebarViewController *)self.delegate;
        NSMenu *contextMenu = [aVC menuForObject:aView.album];
        for (NSMenuItem * anItem in [contextMenu itemArray])
        {
            //[anItem setRepresentedObject:object];
            [anItem setTarget:aView];
        }
        contextMenu.delegate = aView;
        [NSMenu popUpContextMenu:contextMenu withEvent:theEvent forView:aView];
        DLog(@"%@", aView);
    }
    DLog(@"rightMouseDown : %@", theEvent);
}

@end
