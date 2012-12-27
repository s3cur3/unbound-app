//
//  PIXNavigationController.h
//  UnboundApp
//
//  Created by Bob on 12/14/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PIXViewController;

@interface PIXNavigationController : NSViewController <NSToolbarDelegate>

@property (weak, nonatomic) IBOutlet NSWindow *mainWindow;
@property (weak, nonatomic) IBOutlet NSToolbar * toolbar;

@property (strong, nonatomic) IBOutlet NSToolbarItem * backButton;
@property (strong, nonatomic) IBOutlet NSToolbarItem * middleSpacer;

@property (weak) IBOutlet NSProgressIndicator *activitySpinner;
- (IBAction)backPressed:(id)sender;

-(void)pushViewController:(PIXViewController *)aViewController;
-(void)popViewController;
-(NSArray *) viewControllerArray;

<<<<<<< HEAD
-(void)setToolbarItems:(NSArray *)items;
=======
-(void)startSpinner;
-(void)stopSpinner;
>>>>>>> 5032d17966749e7905101d99756417c57c85163a

@end
