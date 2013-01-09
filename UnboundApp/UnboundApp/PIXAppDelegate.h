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
@class PIXLoadingWindowController;
@class PIXFileSystemDataSource;

@interface PIXAppDelegate : NSObject <NSApplicationDelegate>
{
    //Used to indiciate that core data loading should cease
    BOOL loadingWasCanceled;
    
    @public
    PIXLoadingWindowController *loadingWindow;
    PIXMainWindowController *mainWindowController;
    PIXInfoWindowController *showIntroWindow;

}

+(PIXAppDelegate *) sharedAppDelegate;
+(void)presentError:(NSError *)error;

- (IBAction)showMainWindow:(id)sender;
- (IBAction)showIntroWindow:(id)sender;
- (IBAction)showLoadingWindow:(id)sender;

-(void)startFileSystemLoading;

@property (assign) IBOutlet NSWindow *window;

//Core Data
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

//The old fileManager loading system
@property (nonatomic, strong) PIXFileSystemDataSource *dataSource;


//find or create helpers
@property (nonatomic, retain) NSArray *photoFiles;
@property (nonatomic, retain) NSArray *albumFolders;
@property (nonatomic, retain) NSArray *currentBatch;
@property (nonatomic, retain) NSDate *fetchDate;

//Used to load/save thumbs and other things in background
-(NSOperationQueue *) globalBackgroundSaveQueue;



@end
