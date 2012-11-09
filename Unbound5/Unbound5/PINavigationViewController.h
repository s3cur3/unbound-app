//
//  PINavigationViewController.h
//  Unbound
//
//  Created by Bob on 11/7/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PIViewController;

@interface PINavigationViewController : NSViewController
{
    
}

@property (weak, nonatomic) IBOutlet NSWindow *mainWindow;

- (IBAction)backPressed:(id)sender;

-(void)pushViewController:(PIViewController *)aViewController;
-(void)popViewController;
-(NSArray *) viewControllerArray;

@end
