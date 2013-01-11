//
//  PIXImageBrowserView.h
//  Unbound
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <Cocoa/Cocoa.h>

@interface PIXImageBrowserView : IKImageBrowserView
{
    NSRect lastVisibleRect;
}

// for binding
//-(BOOL)showTitles;
//-(void)setShowTitles:(BOOL)showTitles;

// event methods
//-(void)keyDown:(NSEvent *)theEvent;
//-(void)otherMouseDown:(NSEvent *)theEvent;

@end
