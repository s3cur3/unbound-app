//
//  ModifierSwitchedEvent.m
//  Unbound
//
//  Created by Scott Sykora on 12/12/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXModifierSwitchedEvent.h"

@implementation PIXModifierSwitchedEvent

- (NSEventModifierFlags)modifierFlags
{
    
        return ([super modifierFlags] ^ (NSUInteger)NSCommandKeyMask);
    
}

@end
