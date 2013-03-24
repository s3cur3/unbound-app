//
//  PIXPageHUDWindow.h
//  UnboundApp
//
//  Created by Scott Sykora on 3/17/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PIXPageHUDWindow : NSPanel

@property (nonatomic) BOOL hasMouse;

-(void)setParentView:(NSView *)view;

-(void)showAnimated:(BOOL)animated;
-(void)hideAnimated:(BOOL)animated;

-(void)positionWindowWithSize:(NSSize)size animated:(BOOL)animated;

@end
