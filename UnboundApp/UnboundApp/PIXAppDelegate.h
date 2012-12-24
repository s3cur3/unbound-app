//
//  PIXAppDelegate.h
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PIXInfoWindowController;
@class PIXMainWindowController;
@class PIXFileSystemDataSource;

@interface PIXAppDelegate : NSObject <NSApplicationDelegate>
{
    PIXMainWindowController *mainWindowController;
    PIXInfoWindowController *showIntroWindow;
}

+(PIXAppDelegate *) sharedAppDelegate;
+(void)presentError:(NSError *)error;

- (IBAction)showMainWindow:(id)sender;
- (IBAction)showIntroWindow:(id)sender;

-(void)startFileSystemLoading;

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, strong) PIXFileSystemDataSource *dataSource;

@end
