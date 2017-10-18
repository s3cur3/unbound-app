//
//  PIXViewController.h
//  UnboundApp
//
//  Created by Bob on 12/14/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PIXMiniExifViewController;

@class NavigationController;

@interface PIXViewController : NSViewController
{
    
}

@property (weak, nonatomic) NavigationController *navigationViewController;
@property (strong, nonatomic) PIXMiniExifViewController * miniExifViewController;

+(BOOL)optionKeyIsPressed;

-(NSMenu *)menuForObject:(id)object;

-(NSMenu *)menuForObjects:(NSArray *)objects selectedObject:(id)selectdObject;

-(void)setupToolbar;

-(void)willShowPIXView;

-(void)willHidePIXView;

@end
