//
//  PIXHUDMessageController.h
//  UnboundApp
//
//  Created by Scott Sykora on 4/8/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PIXHUDMessageView : NSView

@end

@interface PIXHUDMessageWindow : NSPanel

@end

@interface PIXHUDMessageController : NSWindowController

+(PIXHUDMessageController *)windowWithTitle:(NSString *)title andIcon:(NSImage *)icon;

-(void)presentInParentWindow:(NSWindow *)parentWindow forTimeInterval:(NSTimeInterval)timeInterval;

-(void)rewakeForTimeInterval:(NSTimeInterval)timeInterval;


@end

