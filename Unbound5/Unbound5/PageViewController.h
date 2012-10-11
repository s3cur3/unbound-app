//
//  PageViewController.h
//  Unbound4
//
//  Created by Bob on 10/1/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MainWindowController;
@class Album;
@class SearchItem;

@interface PageViewController : NSViewController <NSPageControllerDelegate>
{
    //IBOutlet NSPageController *pageController;
}

@property (assign) IBOutlet MainWindowController *parentWindowController;
@property (strong) IBOutlet NSPageController *pageController;
//@property (nonatomic, strong) IBOutlet NSURL *directoryURL;
@property (nonatomic, strong) IBOutlet Album *album;
@property (nonatomic, strong) IBOutlet SearchItem *initialSelectedItem;
@property (strong) NSMutableArray *pagerData;
//@property (strong) NSMutableArray *searchData;
@property (assign) id initialSelectedObject;


- (IBAction)goBack:sender;
- (IBAction)editPhoto:sender;

//-(PageViewController *) initWithURL:(NSURL *)aURL;

@end
