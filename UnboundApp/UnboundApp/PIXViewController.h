//
//  PIXViewController.h
//  UnboundApp
//
//  Created by Bob on 12/14/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PIXNavigationController;

@interface PIXViewController : NSViewController
{
    
}

@property (weak, nonatomic) PIXNavigationController *navigationViewController;

-(void)setupToolbar;

-(void)willShowPIXView;

-(void)willHidePIXView;

@end
