//
//  PIXAppDelegate.h
//  UnboundCoreDataUtility
//
//  Created by Bob on 1/4/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SpotlightFetchController;
@class PIXLoadingWindowController;
@class PIXPhotoStreamWindowController;
@class PIXAlbumWindowController;@class PIXBCAlbumWindowController ;

@interface PIXAppDelegate : NSObject <NSApplicationDelegate>
{
    BOOL loadingWasCanceled;
    @public
    PIXLoadingWindowController *loadingWindow;
    PIXPhotoStreamWindowController *browserWindow;
    PIXAlbumWindowController *albumsWindow;
    PIXBCAlbumWindowController *collectionsWindow;
}

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (readonly, strong, strong) IBOutlet SpotlightFetchController *spotLightFetchController;

@property (nonatomic, retain) NSArray *photoFiles;
@property (nonatomic, retain) NSArray *currentBatch;
@property (nonatomic, retain) NSDate *fetchDate;

@property (nonatomic, retain) NSArray *albumFolders;

- (IBAction)saveAction:(id)sender;

- (IBAction)showLoadingWindow:(id)sender;
- (IBAction)showAlbumsWindow:(id)sender;

-(NSOperationQueue *) globalBackgroundSaveQueue;

+(PIXAppDelegate *) sharedAppDelegate;

+(void)presentError:(NSError *)error;

@end
