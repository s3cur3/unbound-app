//
//  PIXAppDelegate.m
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXAppDelegate.h"
//#import "PIXAppDelegate+CoreDataUtils.h"
#import "PIXInfoWindowController.h"
#import "PIXMainWindowController.h"

#import "PIXNavigationController.h"
#import "Unbound-Swift.h"
 
#import "Preferences.h"
#import "PIXFileParser.h"
#import "PIXFileManager.h"
#import "PIXDefines.h"

#import "MASPreferencesWindowController.h"
#import "GeneralPreferencesViewController.h"
#import "AdvancedPreferencesViewController.h"
#import "DebugPrefrencesViewController.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#ifdef SPARKLE
#import <Sparkle/Sparkle.h>
#endif

//extern NSString *kLoadImageDidFinish;
//extern NSString *kSearchDidFinishNotification;

@interface PIXAppDelegate()
{
    BOOL suppressAlertsForFolderNA;
}

@property (readonly, strong, atomic) NSOperationQueue *backgroundSaveQueue;

#ifdef SPARKLE
@property (strong) SUUpdater * sparkleUpdater;
#endif

@end

@implementation PIXAppDelegate


@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize privateWriterContext = _privateWriterContext;

//static PIXAppDelegate * _sharedAppDelegate = nil;

+(PIXAppDelegate *) sharedAppDelegate;
{
    return (PIXAppDelegate *)[[NSApplication sharedApplication] delegate];
}

+(void)presentError:(NSError *)error
{
#ifdef DEBUG
    DLog(@"%@", error);
    NSLog(@"%@",[NSThread callStackSymbols]);
#endif
    if([[NSThread currentThread] isMainThread]) {
        [[NSApplication sharedApplication] presentError:error];
    } else {
        [[NSApplication sharedApplication] performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
    }
}

-(NSOperationQueue *)globalBackgroundSaveQueue;
{
    if (_backgroundSaveQueue == NULL)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _backgroundSaveQueue = [[NSOperationQueue alloc] init];
            [_backgroundSaveQueue setName:@"com.pixite.thumbnail.generator"];
            //[_backgroundSaveQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
            [_backgroundSaveQueue setMaxConcurrentOperationCount:1];
        });
        
    }
    return _backgroundSaveQueue;
}

//- (void)applicationDidFinishLaunching:(NSNotification *)notification
//{
//    Preferences * preferences = [Preferences instance];
//    NSAssert(preferences, @"Failed to create preferences");
//    self.dataSource = [PIXFileSystemDataSource sharedInstance];
//    NSAssert(self.dataSource, @"Failed to create dataSource");
//    if ([[NSUserDefaults standardUserDefaults] boolForKey:kAppFirstRun]==YES)
//    {
//        [self showIntroWindow:self];
//        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kAppFirstRun];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//    } else {
//        
//        [self showMainWindow:self];
//        [self performSelector:@selector(startFileSystemLoading) withObject:self afterDelay:0.1];
//    }
//}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [Fabric with:@[[Crashlytics class]]];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:kAppDidNotExitCleanly])
    {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Unbound Crashed";
        alert.informativeText = @"Unbound seems to have crashed the last time you launched it. Do you want to try again or reset all settings?";
        [alert addButtonWithTitle:@"Start Normally"];
        [alert addButtonWithTitle:@"Clear Settings"];
        NSModalResponse response = [alert runModal];
        if (response == NSModalResponseCancel) {
            [self clearAllSettings];
        }
    }
    
    // set the did not exit cleanly flag now, it will clear it at the end of 'applicationShouldTerminate'
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAppDidNotExitCleanly];
    
    //[(NSApplication *)[aNotification object] setDelegate:self];
    
    // Insert code here to initialize your application
    self.window.delegate = self;
    
    Preferences * preferences = [Preferences instance];
    NSAssert(preferences, @"Failed to create preferences");
    //self.dataSource = [PIXFileSystemDataSource sharedInstance];
    //NSAssert(self.dataSource, @"Failed to create dataSource");

    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photosFinishedLoading:) name:SearchDidFinishNotification object:self.spotLightFetchController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
    
    /*
    //Notification for spotlight fetches
    [[NSNotificationCenter defaultCenter] addObserverForName:kSearchDidFinishNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        //[[NSNotificationCenter defaultCenter] removeObserver:self name:kSearchDidFinishNotification object:nil];
        DLog(@"Finished loading photos");
        [self photosFinishedLoading:note];
        //[self updateAlbumsPhotos];
    }];
    */

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kAppFirstRun]==YES)
    {
        [self showIntroWindow:self];

    } else {
        
        [self startFileSystemLoading];
        [self showMainWindow:self];
    }
    
    //[self setupProgressIndicator];
    
    
    
    // show constraint debug info if debuging
#ifdef DEBUG
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
#endif

#ifdef SPARKLE
    self.showSparkleMenu = YES;
    self.sparkleUpdater = [SUUpdater new];
#endif
    
}

- (IBAction)checkForUpdates:(id)sender
{
    
#ifdef SPARKLE
    [self.sparkleUpdater checkForUpdates:sender];
#endif
}

- (IBAction)macAppStore:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"https://itunes.apple.com/us/app/unbound/id690375005?ls=1&mt=12#"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}



- (void)setupProgressIndicator
{
    NSProgressIndicator * indicator = [[NSProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, 18, 18)];
    [indicator setStyle:NSProgressIndicatorSpinningStyle];
    [indicator setIndeterminate:YES];
    
    [indicator setControlSize:NSSmallControlSize];
    [indicator sizeToFit];
    
    [indicator setDisplayedWhenStopped:YES];
    
    [indicator setUsesThreadedAnimation:YES];
    
    [indicator bind:@"animate"
           toObject:[PIXFileParser sharedFileParser]
        withKeyPath:@"isWorking"
            options: nil]; //@{NSValueTransformerNameBindingOption : NSNegateBooleanTransformerName}];
    
    //[self.progressItem setTitle:@"Hello"];
    [self.progressItem setView:indicator];
}


-(void)startFileSystemLoading
{
    self.fileParser = [PIXFileParser sharedFileParser];
    if (![self.fileParser canAccessObservedDirectories])
    {
        DLog(@"can't access observed directories");
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAppObservedDirectoryUnavailable];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return;
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kAppObservedDirectoryUnavailable];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    if (!self.isObservingFileSystem)
    {
        self.isObservingFileSystem = YES;
        //self.fileParser = [PIXFileParser sharedFileParser];
        [self.fileParser startObserving];
    }
    
    // if we never finished the last deep scan then restart it
    if([[NSUserDefaults standardUserDefaults] boolForKey:kDeepScanIncompleteKey])
    {
        [self.fileParser scanFullDirectory];
    }

}

#pragma mark - Menu Items
// -------------------------------------------------------------------------------
//	showIntroWindow:sender
// -------------------------------------------------------------------------------
- (IBAction)showIntroWindow:(id)sender
{
    PIXInfoWindowController * localIntroWindow = nil;
    
    if (self.introWindow == nil)
    {
        localIntroWindow = [[PIXInfoWindowController alloc] initWithWindowNibName:@"PIXInfoWindowController"];
    }
    
    [localIntroWindow showWindow:self];
    
    self.introWindow = localIntroWindow;
    
}

- (IBAction)showAboutWindow:(id)sender
{
    if (showAboutWindow == nil)
    {
        showAboutWindow = [[PIXAboutWindowController alloc] init];
    }
    [showAboutWindow showWindow:self];
}

- (IBAction)analogOceanWebsitePressed:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"http://www.analog-ocean.com"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)helpPressed:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"mailto:info@unboundformac.com?subject=Unbound%20for%20Mac%20Support"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction)requestFeaturePressed:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"https://unboundformac.fider.io/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction)chooseFolder:(id)sender
{
    if([[PIXFileParser sharedFileParser] userChooseFolderDialog])
    {
        [self showMainWindow:nil];
    }
}

- (IBAction)rescanPhotosPressed:(id)sender
{
    [[PIXFileParser sharedFileParser] rescanFiles];
}

-(IBAction)importPhotosPressed:(id)sender
{
    BOOL allowDirectories = NO;
    
    // if we're at the top level view then allow directories for import
    if([[[self.mainWindowController navigationViewController] viewControllerArray] count] == 1)
    {
        allowDirectories = YES;
    }
    
    [[PIXFileManager sharedInstance] importPhotosToAlbum:self.currentlySelectedAlbum allowDirectories:allowDirectories];
}




#pragma mark - MASPreferences Class methods:

- (IBAction)openPreferences:(id)sender
{
    NSWindowController * prefWindow = self.preferencesWindowController;
    [prefWindow showWindow:sender];
}

- (NSWindowController *)preferencesWindowController
{
    //if (_preferencesWindowController == nil)
    //{
        NSViewController *generalViewController = [[GeneralPreferencesViewController alloc] init];
        //NSViewController *advancedViewController = [[AdvancedPreferencesViewController alloc] init];
        

        NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, nil];
        
        
        BOOL debug = NO;
        // add the debug preferences pane if we're on a debug build
#ifdef DEBUG
        
        //debug = YES;
#endif
        
        if(debug || [NSEvent modifierFlags] & NSAlternateKeyMask)
        {
            NSViewController *debugController = [[DebugPrefrencesViewController alloc] init];
            controllers = [controllers arrayByAddingObject:debugController];
        }
        
        
        // To add a flexible space between General and Advanced preference panes insert [NSNull null]:
        //     NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, [NSNull null], advancedViewController, nil];
        
        NSString *title = NSLocalizedString(@"Preferences", @"Common title for Preferences window");
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
    //}
    return _preferencesWindowController;
}

NSString *const kFocusedAdvancedControlIndex = @"FocusedAdvancedControlIndex";

- (NSInteger)focusedAdvancedControlIndex
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kFocusedAdvancedControlIndex];
}

- (void)setFocusedAdvancedControlIndex:(NSInteger)focusedAdvancedControlIndex
{
    [[NSUserDefaults standardUserDefaults] setInteger:focusedAdvancedControlIndex forKey:kFocusedAdvancedControlIndex];
}


// -------------------------------------------------------------------------------
//	showMainWindow:sender
// -------------------------------------------------------------------------------
- (IBAction)showMainWindow:(id)sender
{
        
    if (self.mainWindowController == nil) {
        self.mainWindowController = [[PIXMainWindowController alloc] initWithWindowNibName:@"PIXMainWindow"];
        //mainWindowController = (PIXMainWindowController *)[self.window windowController];
    }
    self.mainWindowController.window.delegate = self;
    [self.mainWindowController showWindow:self];
}


- (NSError *)application:(NSApplication *)application willPresentError:(NSError *)error;
{
    DLog(@"willPresentError :  %@", error);
    return error;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender;
{
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification;
{
    [self.fileParser stopObserving];
    self.isObservingFileSystem = NO;
    self.fileParser = nil;
}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "com.pixite.UnboundCoreDataUtility" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    //return [[NSURL fileURLWithPath:NSHomeDirectory()] URLByAppendingPathComponent:@"files"];
    
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // THE BELOW CAN BE REMOVED AFTER A VERSION OR TWO
    // if we have the files in the wrong place delete them
    NSURL * badFileLocation = [[NSURL fileURLWithPath:NSHomeDirectory()] URLByAppendingPathComponent:@"files"];
    
    NSURL * badsqllocation = [badFileLocation URLByAppendingPathComponent:@"UnboundApp.sqlite"];
    
    if([fileManager fileExistsAtPath:[badsqllocation path]])
    {
        [fileManager removeItemAtPath:[[badFileLocation URLByAppendingPathComponent:@"UnboundApp.sqlite"] path]
                              error:nil];
        
        [fileManager removeItemAtPath:[[badFileLocation URLByAppendingPathComponent:@"thumbnails"] path]
                              error:nil];
        
        // delete the dir if empty
        NSArray *listOfFiles = [fileManager contentsOfDirectoryAtPath:badFileLocation.path error:nil];
        if([listOfFiles count] == 0)
        {
            [fileManager removeItemAtPath:badFileLocation.path error:nil];
        }
        
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [[PIXFileParser sharedFileParser] scanFullDirectory];
        });
        
    }
    
    // END CODE THAT SHOULD BE REMOVED
    
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    appSupportURL = [appSupportURL URLByAppendingPathComponent:@"Unbound"];
    
    
    return appSupportURL;
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PIXDataModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"com.pixite.unbound" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    /*NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"UnboundCoreDataUtility.storedata"];
     NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
     if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
     [[NSApplication sharedApplication] presentError:error];
     return nil;
     }*/
    
    
    NSMutableDictionary *options = [@{NSMigratePersistentStoresAutomaticallyOption : [NSNumber numberWithBool:YES],
                                    NSInferMappingModelAutomaticallyOption : [NSNumber numberWithBool:YES],
                                    NSSQLitePragmasOption : @{@"journal_mode": @"WAL"}} mutableCopy];

    
    long launchCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"PIX_PersistantStoreLaunchCount"];
    launchCount ++;
    
    [[NSUserDefaults standardUserDefaults] setInteger:launchCount forKey:@"PIX_PersistantStoreLaunchCount"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // only analyze every 10 launches
    if(launchCount % 10 == 0)
    {
        [options setObject:[NSNumber numberWithBool:YES] forKey:NSSQLiteAnalyzeOption];
    }
    
    // only vaccuum every 20 launches (offset this from analyze so they don't happen on the same launch.
    if(launchCount % 20 == 5)
    {
        [options setObject:[NSNumber numberWithBool:YES] forKey:NSSQLiteManualVacuumOption];
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"UnboundApp.sqlite"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:options error:&error]) {
        /*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
		 
		 Typical reasons for an error here include:
		 * The persistent store is not accessible
		 * The schema for the persistent store is incompatible with current managed object model
		 Check the error message to determine what the actual problem was.
		 */
        
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        
        // if there was an unrecoverable error delete the db and reload
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if (![fileManager removeItemAtPath:url.path error:&error]) {
            NSLog(@"Failed to remove database file: %@", url);
        }
        
        else {
            if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:options error:&error])
            {
                NSLog(@"Failed to create/open database file: %@", url);
                [[NSApplication sharedApplication] presentError:error];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
        
            // also delete the thumbnails
            [self clearThumbSorageDirectory];
            
            // and rescan the root directories
            [[PIXFileParser sharedFileParser] scanFullDirectory];
            
        });
    }
    
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}


-(NSURL *)thumbSorageDirectory
{
    return [[self applicationFilesDirectory] URLByAppendingPathComponent:@"/thumbnails/"];
}

-(BOOL)clearThumbSorageDirectory
{
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    NSURL * deleteingThumbsDir = [[self applicationFilesDirectory] URLByAppendingPathComponent:@"/thumbnails-deleting"];
    
    [fileManager moveItemAtURL:[self thumbSorageDirectory] toURL:deleteingThumbsDir error:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        // also delete the thumbnails
        [fileManager removeItemAtURL:deleteingThumbsDir error:nil];
        
    });
    
    return YES;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the database" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    
    
    // remove any old persistant stores
    
    
    // use the background saving context oulined here:
    // http://www.cocoanetics.com/2012/07/multi-context-coredata/
    
    // create new writer MOC
    _privateWriterContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_privateWriterContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
    [_privateWriterContext setUndoManager:nil];
    
    // overwrite the database with updates from this context
    //[_privateWriterContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
    
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setParentContext:_privateWriterContext];
    [_managedObjectContext setUndoManager:nil];
    
    // overwrite the database with updates from this context
    //[_managedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeContext:) name:NSManagedObjectContextDidSaveNotification object:nil];
    
    // do a quick test fetch to see if the db is malformed
    
    NSError * error = nil;
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kPhotoEntityName];
    [_managedObjectContext countForFetchRequest:fetchRequest error:&error];
    
    if(error)
    {
        [self clearDatabase];
        return [self managedObjectContext];
    }
   

    
    return _managedObjectContext;
}

-(void)saveDBToDiskWithRateLimit
{
    // cancel any previous delayed calls to this method
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveDBToDisk:) object:nil];
    
    [self performSelector:@selector(saveDBToDisk:)  withObject:nil afterDelay:5.0];
    
}

-(BOOL)saveDBToDisk:(NSError **)error
{
// rchang: this would return early and never advance to the later code.
// commenting it out appears to fix an issue where restarts were reverting to older captions
//    if (![self.managedObjectContext save:error])
//    {
//        DLog(@"ERROR SAVING IN MAIN THREAD: %@", [*error description])
//        return NO;
//    }
//    
//    return YES;
    // perform this on the main thread if needed
    if(![NSThread isMainThread])
        
    {
        [self performSelectorOnMainThread:@selector(saveDBToDisk:) withObject:nil waitUntilDone:NO];
        return YES;
    }
    
    if (![self.managedObjectContext save:error])
    {
        DLog(@"ERROR SAVING IN MAIN THREAD: %@", [*error description])
        return NO;
    }
        
    // now save to disk on a bg thread
    [self.privateWriterContext performBlock:^{
        if (![self.privateWriterContext save:error])
        {
            if(error!=nil) {
                DLog(@"ERROR SAVING IN BG THREAD: %@", [*error description])
            }
        }
    }];
    
    return YES;
}

-(NSManagedObjectContext *)threadSafePassThroughMOC
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
    
    //-------------------------------------------------------
    //    Setting the undo manager to nil means that:
    //
    //    - You don’t waste effort recording undo actions for changes (such as insertions) that will not be undone;
    //    - The undo manager doesn’t maintain strong references to changed objects and so prevent them from being deallocated
    //-------------------------------------------------------
    [context setUndoManager:nil];
    
    
    //set it to the App Delegates persistant store coordinator
    //[context setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
    
    [context setParentContext:self.managedObjectContext];
    
    // overwrite the database with updates from this context
    //[context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    
    return context;
}

-(NSManagedObjectContext *)threadSafeSideSaveMOC
{
    
    NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
    
    //-------------------------------------------------------
    //    Setting the undo manager to nil means that:
    //
    //    - You don’t waste effort recording undo actions for changes (such as insertions) that will not be undone;
    //    - The undo manager doesn’t maintain strong references to changed objects and so prevent them from being deallocated
    //-------------------------------------------------------
    [context setUndoManager:nil];
    
    
    //set it to the App Delegates persistant store coordinator
    //[context setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
    
    if(self.privateWriterContext)
    {
        [context setParentContext:self.privateWriterContext];
    }
    
    // overwrite the database with updates from this context
    //[context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    
    return context;
}

- (void)clearAllSettings
{
    NSDictionary * allObjects;
    NSString     * key;
    
    allObjects = [ [ NSUserDefaults standardUserDefaults ] dictionaryRepresentation ];
    
    for( key in allObjects )
    {
        [ [ NSUserDefaults standardUserDefaults ] removeObjectForKey: key ];
    }
    
    [ [ NSUserDefaults standardUserDefaults ] synchronize ];
    
    [self clearDatabase];
}

- (void)clearDatabase
{
    // pop to the root vc
    [[[self mainWindowController] navigationViewController] popToRootViewController];

    /*
    for(NSPersistentStore *aStore in _persistentStoreBackgroundCoordinator.persistentStores)
    {
        NSError * error = nil;
        [_persistentStoreBackgroundCoordinator removePersistentStore:aStore error:&error];
        
        if(error)
        {
            NSLog(@"Error removing persistant store: %@", error.description);
        }
    }
    
    for(NSPersistentStore *aStore in _persistentStoreCoordinator.persistentStores)
    {
        NSError * error = nil;
        [_persistentStoreCoordinator removePersistentStore:aStore error:&error];
        
        if(error)
        {
            NSLog(@"Error removing persistant store: %@", error.description);
        }
    }
     [self.managedObjectContext setParentContext:nil];
     */
    
    
    
    _managedObjectContext = nil;
    _privateWriterContext = nil;
    _persistentStoreCoordinator = nil;
    _persistentStoreBackgroundCoordinator = nil;
    
    [[PIXFileParser sharedFileParser] setParseContext:nil];
    
    NSURL *url = [[self applicationFilesDirectory] URLByAppendingPathComponent:@"UnboundApp.sqlite"];
    
    NSError * error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager removeItemAtPath:url.path error:&error]) {
        NSLog(@"Failed to remove database file: %@", url);
    }
    
    [self clearThumbSorageDirectory];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
}

-(void)mergeContext:(NSNotification *)notification
{    
    NSManagedObjectContext *postingContext = [notification object];
    
    // save the writer context in the bg
    
    if(postingContext.parentContext ==  self.privateWriterContext && postingContext != self.managedObjectContext)
    {
        [self.privateWriterContext performBlock:^{
            
            NSError * error = nil;
            if (![self.privateWriterContext save:&error])
            {
                DLog(@"ERROR SAVING IN BG THREAD: %@", [error description]);
            }
        }];
    }
    
    
    // merge the changes into main
    // Only interested in merging from master into main.
    if ([notification object] == self.privateWriterContext)
    {
        [self.managedObjectContext performBlock:^{
            [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
            
        }];
    }
    
    /*
    NSManagedObjectContext *postingContext = [notification object];
    if ([postingContext persistentStoreCoordinator] == [self persistentStoreCoordinator] &&
        postingContext.parentContext == nil &&
        postingContext != self.privateWriterContext) {
        // merge the changes
        
        //[[self managedObjectContext] reset];
        [self.managedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:) withObject:notification waitUntilDone:YES];
        
        // also save the context (so other bg threads get the changes)
        //[self.managedObjectContext performSelectorOnMainThread:@selector(save:) withObject:nil waitUntilDone:YES];
    }*/
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [self undoManager];
}

- (NSUndoManager *)undoManager
{
    //return [[self managedObjectContext] undoManager];
    if (_undoManager == nil) {
        _undoManager = [[NSUndoManager alloc] init];
    }
    return _undoManager;
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (!_managedObjectContext) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kAppDidNotExitCleanly];
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kAppDidNotExitCleanly];
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kAppDidNotExitCleanly];
        return NSTerminateNow;
    }
    
    __block NSError *error = nil;
    
    __block BOOL saveResult = YES;
    
    if (![self.managedObjectContext save:&error])
    {
        saveResult = NO;
    }
    
    // now save to disk on a bg thread
    [self.privateWriterContext performBlockAndWait:^{
        if (![self.privateWriterContext save:&error])
        {
            saveResult = NO;
        }
    }];
    
    /*
    if (!saveResult) {
        
        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }*/
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kAppDidNotExitCleanly];
    
    return NSTerminateNow;
}

#pragma mark - AlertView

// -------------------------------------------------------------------------------
//	handleResult:withResult
//
//	Used to handle the result for both sheet and modal alert cases.
// -------------------------------------------------------------------------------
-(void)handleResult:(NSAlert *)alert withResult:(NSInteger)result
{
    // suppression button only exists in 10.5 and later
    if ([alert showsSuppressionButton])
    {
        if ([[[alert suppressionButton] cell] state]) {
            DLog(@"suppress alert: YES");
            suppressAlertsForFolderNA = YES;
            [[NSUserDefaults standardUserDefaults] setBool:suppressAlertsForFolderNA forKey:kAppObservedDirectoryUnavailableSupressAlert];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
            suppressAlertsForFolderNA = NO;
            DLog(@"suppress alert: NO");
        }
    }

	// report which button was clicked
	switch(result)
	{
		case NSAlertDefaultReturn:
			DLog(@"result: NSAlertDefaultReturn");
            [self performSelector:@selector(openPreferences:) withObject:self.prefsMenuItem afterDelay:0.25f];

			break;
            
		case NSAlertAlternateReturn:
			DLog(@"result: NSAlertAlternateReturn");
            //[self rescanAction:nil];
            //User chose ignore
			break;
            
		case NSAlertOtherReturn:
			DLog(@"result: NSAlertOtherReturn");
            //User chose ignore
			break;
            
        default:
            break;
	}

}

// -------------------------------------------------------------------------------
//	alertDidEnd:returnCode:contextInfo
//
//	This method is called only when a the sheet version of this alert is dismissed.
// -------------------------------------------------------------------------------
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
#pragma unused (contextInfo)
	[[alert window] orderOut:self];
	[self handleResult:alert withResult:returnCode];
}


// -------------------------------------------------------------------------------
//	openAlert:
//
//	The user clicked the "Open…" button.
// -------------------------------------------------------------------------------
- (void)openAlert:(NSString *)title withMessage:(NSString *)message
{
    if (suppressAlertsForFolderNA ||
        [[NSUserDefaults standardUserDefaults] boolForKey:kAppObservedDirectoryUnavailableSupressAlert] == YES) {
        DLog(@"Alert suppression was checked - don't warn again.");
        return;
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:kAppFirstRun]) {
        DLog(@"Don't show alert on first run.");
        return;
    }
	NSString *useSecondButtonStr = @"Cancel";
    //Possibly offer ability to re-check from alert view?
	//NSString *useAlternateButtonStr = @"Re-scan";
    NSString *defaultButtonTitle = @"Open Preferences";
	
	NSAlert *testAlert = [NSAlert alertWithMessageText:message
                                         defaultButton:defaultButtonTitle
                                       alternateButton:useSecondButtonStr
                                           otherButton:nil
                             informativeTextWithFormat:@"%@", title];
    

	[testAlert setAlertStyle:NSWarningAlertStyle];
    
    NSImage* image = [NSImage imageNamed:@"icon.icns"];
    [testAlert setIcon: image];
	
	// determine if we should use the help button
//	[testAlert setShowsHelp:useHelpButtonState];
//	if (useHelpButtonState)
//		[testAlert setHelpAnchor:kHelpAnchor];	// use this anchor as a direction point to our help book
	
	[testAlert setDelegate:(id<NSAlertDelegate>)self];	// this allows "alertShowHelp" to be called when the user clicks the help button
    
	// note: accessoryView and suppression checkbox are available in 10.5 on up
    [testAlert setShowsSuppressionButton:YES];
    [[testAlert suppressionButton] setTitle:@"Don't ask again"];
    
    [testAlert beginSheetModalForWindow:[self window]
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:nil];
}


//TODO: possibly add a link to the help file in certain Alert Views
// -------------------------------------------------------------------------------
//	alertShowHelp
//
//	The delegate method for displaying alert help.
//// -------------------------------------------------------------------------------
//- (BOOL)alertShowHelp:(NSAlert *)alert
//{
//	// get the localized name of our help book
//    //
//    // to make this work, the help book name needs to be defined in your InfoPlist.strings
//    // file with an entry for "CFBundleHelpBookName"
//    //
//    NSString *helpBookName = [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleHelpBookName"];
//
//	[[NSHelpManager sharedHelpManager] openHelpAnchor:[alert helpAnchor] inBook:helpBookName];
//
//	return YES;
//}

// -------------------------------------------------------------------------------
//	rescanAction:
//
//	The user clicked the "Rescan" button from the Alert View - UNUSED.
// -------------------------------------------------------------------------------
//- (IBAction)rescanAction:(id)sender
//{
//	DLog(@"Re-scan button was clicked.");
//    self.fileParser = [PIXFileParser sharedFileParser];
//    if (![self.fileParser canAccessObservedDirectories])
//    {
//        [self.fileParser incrementWorking];
//        double delayInSeconds = 2.0;
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//            [self openAlert:@"Re-scan Failed" withMessage:kRootFolderUnavailableDetailMessage];
//            [self.fileParser decrementWorking];
//        });
//    } else {
//        [self startFileSystemLoading];
//    }
//}


@end
