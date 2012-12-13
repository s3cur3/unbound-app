//
//  ModifierSwitchedEvent.m
//  Unbound
//
//  Created by Scott Sykora on 12/12/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "ModifierSwitchedEvent.h"

@implementation ModifierSwitchedEvent

- (NSUInteger)modifierFlags
{
    
        return ([super modifierFlags] ^ (NSUInteger)NSCommandKeyMask);
    
}

@end
