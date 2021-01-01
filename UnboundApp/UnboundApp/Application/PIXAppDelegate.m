//
//  PIXAppDelegate.m
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXAppDelegate.h"
//#import "PIXAppDelegate+CoreDataUtils.h"
#import "Unbound-Swift.h"

#import "Preferences.h"
#import "PIXFileParser.h"
#import "PIXFileManager.h"
#import "PIXDefines.h"

//extern NSString *kLoadImageDidFinish;
//extern NSString *kSearchDidFinishNotification;

@interface PIXAppDelegate()
{
    BOOL suppressAlertsForFolderNA;
}

@property (readonly, strong, atomic) NSOperationQueue *backgroundSaveQueue;

@end

@implementation PIXAppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize privateWriterContext = _privateWriterContext;

static PIXAppDelegate * _sharedAppDelegate = nil;

+(PIXAppDelegate *) sharedAppDelegate
{
	assert(_sharedAppDelegate);
    return _sharedAppDelegate;
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

-(NSOperationQueue *)globalBackgroundSaveQueue
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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	_sharedAppDelegate = (PIXAppDelegate *)[[NSApplication sharedApplication] delegate];

	BOOL showCrashDialog = [[NSUserDefaults standardUserDefaults] boolForKey:kAppDidNotExitCleanly];
    if(showCrashDialog)
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
	[[NSUserDefaults standardUserDefaults] setBool:showCrashDialog forKey:kAppShowedCrashDialog];
    
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

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kAppFirstRun])
    {
        [self showLibraryPicker:self];

    } else {
        
        [self startFileSystemLoading];
        [self showMainWindow:self];
    }
    
    //[self setupProgressIndicator];
    
    
    
    // show constraint debug info if debuging
#ifdef DEBUG
    self.isDebugBuild = YES;
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
#endif

    [NSValueTransformer setValueTransformer:[TextColorForThemeTransformer newInstance]
                                    forName:@"TextColorForThemeTransformer"];
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

    // Files may have changed since we were last open, so scan the directory each load.
    [self.fileParser scanFullDirectory];
}

#pragma mark - Menu Items
- (IBAction)showLibraryPicker:(id)sender
{
    if (self.libraryPickerWindow == nil)
    {
		self.libraryPickerWindow = [LibraryPickerObjCBridge makeLibraryPicker];
    }
    [self.libraryPickerWindow showWindow:self];
}

- (IBAction)showAboutWindow:(id)sender
{
    if (showAboutWindow == nil)
    {
        showAboutWindow = [[PIXAboutWindowController alloc] init];
    }
    [showAboutWindow showWindow:self];
}

- (IBAction)leaveAReview:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kReviewUrl]];
}

- (IBAction)helpPressed:(id)sender
{
    NSURL * url = [NSURL URLWithString:kSupportUrl];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)requestFeaturePressed:(id)sender
{
    NSURL * url = [NSURL URLWithString:kFeatureRequestUrl];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)rescanPhotosPressed:(id)sender
{
    [[PIXFileParser sharedFileParser] rescanFiles];
}

-(IBAction)importPhotosPressed:(id)sender
{
    BOOL allowDirectories = YES;
    [[PIXFileManager sharedInstance] importPhotosToAlbum:self.currentlySelectedAlbum allowDirectories:allowDirectories];
}

- (IBAction)purchaseOnlinePressed:(id)sender {
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:kUpgradeTrialUrl]];
}

- (IBAction)showHomepagePressed:(id)sender {
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:kHomepageUrl]];
}

#pragma mark - MASPreferences Class methods:

- (IBAction)openPreferences:(id)sender
{
    [self.preferencesWindowController showWindow:sender];
}

- (NSWindowController *)preferencesWindowController {
    if (_preferencesWindowController == nil) {
        _preferencesWindowController = [PreferencesWindowController create];
    }
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
        self.mainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindowController"];
    }
    self.mainWindowController.window.delegate = self;
    [self.mainWindowController showWindow:self];
}

- (NSError *)application:(NSApplication *)application willPresentError:(NSError *)error
{
    DLog(@"willPresentError :  %@", error);
    return error;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self.fileParser stopObserving];
    self.isObservingFileSystem = NO;
    self.fileParser = nil;
}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "com.pixite.UnboundCoreDataUtility" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"Unbound"];
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
    
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
			NSFileManager *fileManager = [NSFileManager defaultManager];
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
				[PIXAppDelegate presentError:error];
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

-(BOOL)wantDarkMode
{
    return [[self mainWindowController] wantDarkMode];
}

-(void)saveDBToDiskWithRateLimit
{
    // cancel any previous delayed calls to this method
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveDBToDisk:) object:nil];
    
    [self performSelector:@selector(saveDBToDisk:)  withObject:nil afterDelay:5.0];
    
}

-(BOOL)saveDBToDisk:(id)sender
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
    
	NSError * ctxError = nil;
    if (![self.managedObjectContext save:&ctxError])
    {
        DLog(@"ERROR SAVING IN MAIN THREAD: %@", [ctxError description])
        return NO;
    }
        
    // now save to disk on a bg thread
    [self.privateWriterContext performBlock:^{
		NSError * writeError = nil;
        if (![self.privateWriterContext save:&writeError] && writeError != nil)
        {
			DLog(@"ERROR SAVING IN BG THREAD: %@", [writeError description])
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
//    [context setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
    
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

    if (self.privateWriterContext) {
        [context setParentContext:self.privateWriterContext];
    } else {
        [context setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
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
    [[[self mainWindowController] navigationViewController] popToRootViewController];
    
	// This is kind of hairy.
	// Deletions are broken into 3 stages.
	// 1. We perform the actual deletion in our writer context (in memory only).
	// 2. We merge those changes into the managed object context we give out to the rest of the app.
	//    This is basically a cache flush for the reader context---without it, the other context will
	//    keep the now-deleted objects around in memory, maybe until restart (!!).
	// 3. We write the changes to disk
	//
	// More info here: https://stackoverflow.com/questions/53823083/why-entries-are-not-deleted-until-app-is-restarted-or-i-execute-my-nsbatchdelete
	// And from Apple: https://developer.apple.com/library/archive/featuredarticles/CoreData_Batch_Guide/BatchDeletes/BatchDeletes.html
	NSManagedObjectContext * moc = [self managedObjectContext];
	for(NSString * entity in @[kPhotoEntityName, kAlbumEntityName]) {
		// 1. Do the deletion
		NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entity];
		NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
		[delete setResultType:NSBatchDeleteResultTypeObjectIDs];
		NSError *deleteError = nil;
		id resultIds = [_persistentStoreCoordinator executeRequest:delete withContext:_privateWriterContext error:&deleteError];
		
		// 2. Sync the changes across everyone who might have held onto it in memory
		if(resultIds) {
			[NSManagedObjectContext mergeChangesFromRemoteContextSave:@{NSDeletedObjectsKey: [resultIds result]} intoContexts:@[moc]];
		} else {
			NSLog(@"Error running deletion on %@: %@", entity, [deleteError description]);
		}
		
		// 3. Write the changes to disk before continuing
		NSError * saveError = nil;
		[_privateWriterContext save:&saveError];
		if(saveError) {
			NSLog(@"Error saving %@: %@", entity, [saveError description]);
		}
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
    NSString *defaultButtonTitle = @"Open preferences.window.title";
	
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

@end
