//
//  IKBController.h
//  IKBrowserViewDND
//
//  Created by David Gohara on 2/26/08.
//  Copyright 2008 SmackFu-Master. All rights reserved.
//  http://smackfumaster.com
//

#import <Cocoa/Cocoa.h>
@class IKImageBrowserView;
@class MainViewController;

@interface IKBController : NSObject {

    IBOutlet MainViewController * mainView;
	//BrowserView
	//IBOutlet IKImageBrowserView * browserView;
	NSMutableArray * browserData;
	
}

@property(readwrite,retain) NSMutableArray * browserData;
@property IBOutlet IKImageBrowserView * browserView;

-(void)updateBrowserView;

@end
