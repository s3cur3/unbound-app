//
//  PIViewController.h
//  Unbound
//
//  Created by Bob on 11/7/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PINavigationViewController;

@interface PIViewController : NSViewController
{
    
}

@property (strong, nonatomic) PINavigationViewController *navigationViewController;

@property (strong) IBOutlet NSView* menuView;

+(BOOL)optionKeyIsPressed;

@end
