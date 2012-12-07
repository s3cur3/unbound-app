//
//  AppDelegate.h
//  Unbound5
//
//  Created by Bob on 10/4/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PIFileManager;
@class MainWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) NSUndoManager *undoManager;
@property (readonly, strong, nonatomic) PIFileManager *sharedFileManager;

- (IBAction)saveAction:(id)sender;
- (IBAction)showPreferences:(id)sender;

+(AppDelegate *)applicationDelegate;
+(MainWindowController *)mainWindowController;
-(void)updatePhotoSearchURL:(NSURL *)aURL;

-(NSURL *)trashFolderURL;
-(NSString *)trashFolderPath;

@end
