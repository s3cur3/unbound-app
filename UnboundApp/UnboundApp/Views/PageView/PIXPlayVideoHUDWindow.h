//
//  PIXPlayVideoHUDWindow.h
//  UnboundApp
//
//  Created by Bob on 7/18/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PIXPlayVideoHUDWindow : NSPanel

//@property (nonatomic) BOOL hasMouse;
//
-(void)setParentView:(NSView *)view;
//
//-(void)showAnimated:(BOOL)animated;
//-(void)hideAnimated:(BOOL)animated;
//
-(void)positionWindowWithSize:(NSSize)size animated:(BOOL)animated;

@end
