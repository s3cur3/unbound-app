//
//  PIXViewController.m
//  UnboundApp
//
//  Created by Bob on 12/14/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXViewController.h"
#import "PIXNavigationController.h"

@interface PIXViewController ()

@end

@implementation PIXViewController

+(BOOL)optionKeyIsPressed
{
    if(( [NSEvent modifierFlags] & NSAlternateKeyMask ) != 0 ) {
        return YES;
    } else {
        return NO;
    }
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)setupToolbar
{
    NSArray * items = @[self.navigationViewController.backButton];
    
    [self.navigationViewController setToolbarItems:items];
     
}

-(void)willShowPIXView
{
    
}

-(void)willHidePIXView
{
    
} 

@end
