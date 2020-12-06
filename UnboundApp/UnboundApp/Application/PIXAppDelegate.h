//
//  PIXAppDelegate.h
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PIXInfoWindowController;
@class MainWindowController;
@class PIXAboutWindowController;
@class PIXFileParser;
@class PIXAlbum;

@interface PIXAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSAlertDelegate>
{
    //Used to indiciate that core data loading should cease
    BOOL loadingWasCanceled;
    
    @public
    
    PIXInfoWindowController *showIntroWindow;
    PIXAboutWindowController *showAboutWindow;

}

+(PIXAppDelegate *) sharedAppDelegate;
+(void)presentError:(NSError *)error;

- (IBAction)showMainWindow:(id)sender;
- (IBAction)showIntroWindow:(id)sender;
- (IBAction)showAboutWindow:(id)sender;
- (IBAction)analogOceanWebsitePressed:(id)sender;
- (IBAction)helpPressed:(id)sender;
- (IBAction)chooseFolder:(id)sender;
- (IBAction)rescanPhotosPressed:(id)sender;
- (IBAction)importPhotosPressed:(id)sender;
- (IBAction)purchaseOnlinePressed:(id)sender;
- (IBAction)showHomepagePressed:(id)sender;

@property BOOL isDebugBuild;
@property BOOL isOwned;

@property (nonatomic, strong) IBOutlet NSMenuItem * progressItem;
// for MASPreferences class:
@property (nonatomic, strong) MainWindowController *mainWindowController;
@property (nonatomic, strong) NSWindowController * introWindow;

@property (nonatomic, strong) NSWindowController *preferencesWindowController;
@property (nonatomic) NSInteger focusedAdvancedControlIndex;
- (IBAction)openPreferences:(id)sender;
@property (weak) IBOutlet NSMenuItem *prefsMenuItem;

@property (weak) PIXAlbum * currentlySelectedAlbum;

-(void)startFileSystemLoading;

@property (assign) BOOL isObservingFileSystem;

@property (nonatomic,strong) NSDate *startDate;

@property (assign) IBOutlet NSWindow *window;

//Core Data
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreBackgroundCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext *privateWriterContext;

// this returns a newly created MOC (Managed Object Context) to do work in the background. This will be a child context where changes are saved directly into the main thread MOC (pass through)
-(NSManagedObjectContext *)threadSafePassThroughMOC;

// this returns a newly created MOC (Managed Object Context) to do work in the background. This will be a child context where changes are saved to the background writer MOC and then merged up to the main thread MOC (side save)
-(NSManagedObjectContext *)threadSafeSideSaveMOC;



// this will save the db to the disk in the background after a 1second delay.
// If it is called again within one second it will cancel the last call and only save once
// this should be used when a loop or when save could be called a bunch of times in quick succession
-(void)saveDBToDiskWithRateLimit;


// this will save the db to the disk in the background
// note error and return value will only be populated if this is called from the main thread
-(BOOL)saveDBToDisk:(NSError **)error;

//The file parsing system (keeps file system in sync)
@property (nonatomic, strong) PIXFileParser *fileParser;

@property (strong, nonatomic) IBOutlet NSUndoManager *undoManager;


//find or create helpers
@property (nonatomic, retain) NSArray *photoFiles;
@property (nonatomic, retain) NSArray *albumFolders;
@property (nonatomic, retain) NSArray *currentBatch;
@property (nonatomic, retain) NSDate *fetchDate;

//Used to load/save thumbs and other things in background
-(NSOperationQueue *) globalBackgroundSaveQueue;

- (NSURL *)applicationFilesDirectory;
- (NSURL *)thumbSorageDirectory;

//NSWindowDelegate methods
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window;

- (void)clearDatabase;

- (void)openAlert:(NSString *)title withMessage:(NSString *)message;

@end
