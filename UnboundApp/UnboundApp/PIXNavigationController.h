//
//  PIXNavigationController.h
//  UnboundApp
//
//  Created by Bob on 12/14/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PIXViewController;

@interface PIXNavigationController : NSViewController

@property (weak, nonatomic) IBOutlet NSWindow *mainWindow;

@property (weak) IBOutlet NSProgressIndicator *activitySpinner;
- (IBAction)backPressed:(id)sender;

-(void)pushViewController:(PIXViewController *)aViewController;
-(void)popViewController;
-(NSArray *) viewControllerArray;

-(void)startSpinner;
-(void)stopSpinner;

@end
