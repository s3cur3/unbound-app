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

-(void)keyDown:(NSEvent *)theEvent
{
    
    if ([theEvent type] == NSKeyDown)
    {
        NSString* pressedChars = [theEvent characters];
        if ([pressedChars length] == 1)
        {
            PIXSidebarViewController *sidebar = (PIXSidebarViewController *)self.delegate;
            unichar pressedUnichar = [pressedChars characterAtIndex:0];
            if(pressedUnichar == 63235) // right arrow goes to grid view
            {
                
                if([sidebar respondsToSelector:@selector(moveRight:)])
                {
                    [sidebar moveRight:theEvent];
                    return;
                }
            }
            
            // escape or space goes back to stacks view
            if(pressedUnichar == ' ' || pressedUnichar == 0x001B)
            {
                if([sidebar respondsToSelector:@selector(cancelOperation:)])
                {
                    [sidebar cancelOperation:theEvent];
                    return;
                }
            }
            
            if(pressedUnichar == 'f') // f should togge fullscreen
            {
                [self.window toggleFullScreen:theEvent];
                return;
            }
        }
    }
    
    [super keyDown:theEvent];

}

@end
