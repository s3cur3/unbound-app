//
// Created by Ryan Harter on 3/10/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

#import "PIXInterfacePreferencesViewController.h"


@implementation PIXInterfacePreferencesViewController

- (id)init
{
    return [super initWithNibName:@"PIXInterfacePreferencesView" bundle:nil];
}

#pragma mark - MASPreferencesViewController Methods

- (NSString *)viewIdentifier {
    return @"InterfacePreferences";
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNameColorPanel];
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"preferences.interface.title", "Interface");
}

#pragma mark - IBActions

-(IBAction)themeChanged:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"backgroundThemeChanged" object:nil];
}


@end