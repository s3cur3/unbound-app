//
//  PageViewController.h
//  Unbound4
//
//  Created by Bob on 10/1/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MainViewController;

@interface PageViewController : NSViewController
{
    //IBOutlet NSPageController *pageController;
}

@property (assign) IBOutlet MainViewController *parentViewController;
@property (assign) IBOutlet NSPageController *pageController;


- (IBAction)goBack:sender;

@end
