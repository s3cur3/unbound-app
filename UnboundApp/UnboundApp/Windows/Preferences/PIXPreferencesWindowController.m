//
// Created by Ryan Harter on 3/10/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

#import "PIXPreferencesWindowController.h"
#import "GeneralPreferencesViewController.h"
#import "PIXInterfacePreferencesViewController.h"


@implementation PIXPreferencesWindowController

- (instancetype)init; {
    NSString *title = NSLocalizedString(@"preferences.window.title", @"Preferences window title");

    NSArray *controllers = @[
            [[GeneralPreferencesViewController alloc] init],
            [[PIXInterfacePreferencesViewController alloc] init]
    ];

    return [[PIXPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
}

@end