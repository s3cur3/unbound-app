//
//  AppDelegate.h
//  Unbound4
//
//  Created by Bob on 10/1/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MainWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (strong) IBOutlet MainWindowController *mainWindowController;
@property (strong,nonatomic) NSMutableArray *imagesArray;
@property (strong,nonatomic) NSMutableArray *subdirectoryArray;
@property (strong,nonatomic) NSString *currentFilePath;

+ (AppDelegate *) applicationDelegate;
-(void) loadDataWithPath:(NSString *)path;
-(void) loadDataFromDefaults;

@end
