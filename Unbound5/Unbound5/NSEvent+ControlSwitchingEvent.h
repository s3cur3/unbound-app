//
//  NSEvent+ControlSwitchingEvent.h
//  Unbound
//
//  Created by Scott Sykora on 12/12/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSEvent (ControlSwitchingEvent)

- (NSUInteger)switchedModifierFlags;
-(void)switchModifiers;

@end
