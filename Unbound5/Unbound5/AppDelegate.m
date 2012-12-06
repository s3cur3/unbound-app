//
//  AppDelegate.m
//  Unbound5
//
//  Created by Bob on 10/4/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "MainWindowController.h"
#import "PreferencesWindowController.h"
#import "Preferences.h"
#import "Utils.h"
#import "SimpleProfiler.h"

@implementation AppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize window = _window;

+(AppDelegate *)applicationDelegate;
{
    return (AppDelegate *)[[NSApplication sharedApplication] delegate];
}

// -------------------------------------------------------------------------------
//	applicationShouldTerminateAfterLastWindowClosed:sender
//
//	NSApplication delegate method placed here so the sample conveniently quits
//	after we close the window.
// -------------------------------------------------------------------------------
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

-(void)updatePhotoSearchURL:(NSURL *)aURL
{
    DLog(@"updatePhotoSearchURL");
    MainWindowController *windowController = (MainWindowController *)[self.window delegate];
    [[NSUserDefaults standardUserDefaults] setValue:aURL.path forKey:@"searchLocationKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [windowController awakeFromNib];
    [windowController startLoading];
}

-(IBAction)showPreferences:(id)sender
{
	[[PreferencesWindowController instance] runModal];
}

/*
 To reset defaults for testing:
 
   defaults read com.pixite.Unbound5
   defaults delete com.pixite.Unbound5
   defaults read com.pixite.Unbound5
 */
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    
    IKImageBrowserView *mImageBrowser = [(MainWindowController *)[self.window delegate] browserView];
    
    
    Preferences * preferences = [Preferences instance];
    [preferences bind:mImageBrowser
                  key:@"zoomValue"
                   to:@"thumbnailSize"
       withUnarchiver:NO];
    
    [preferences bind:mImageBrowser
                  key:@"showTitles"
                   to:@"showTitles"
       withUnarchiver:NO];
    
    
    DLog(@"Application will finish launching.");
    
    
    [self checkCreateTrashFolder];
    
    /*if ([[NSUserDefaults standardUserDefaults] valueForKey:@"searchLocationKey"]==nil)
    {
        [(MainWindowController *)[self.window delegate] startLoading];
    }*/
    [(MainWindowController *)[self.window delegate] startLoading];
}

-(NSURL *)trashFolderURL
{
    NSString *trashURL = [[NSUserDefaults standardUserDefaults] valueForKey:@"PI_TRASH_PATH"];
    if (!trashURL) {
        [self checkCreateTrashFolder];
        trashURL = [[NSUserDefaults standardUserDefaults] valueForKey:@"PI_TRASH_PATH"];
    }
    return [NSURL fileURLWithPath:trashURL];
}

-(NSString *)trashFolderPath
{
    NSString *trashURL = [[NSUserDefaults standardUserDefaults] valueForKey:@"PI_TRASH_PATH"];
    if (!trashURL) {
        [self checkCreateTrashFolder];
        trashURL = [[NSUserDefaults standardUserDefaults] valueForKey:@"PI_TRASH_PATH"];
    }
    return trashURL;
}

-(void)checkCreateTrashFolder
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSURL *trashURL = [applicationFilesDirectory URLByAppendingPathComponent:@"Unbound.trash"];
    NSError *error = nil;
    
    //NSDictionary *properties = [trashURL resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    BOOL isDir;
    if (![fileManager fileExistsAtPath:trashURL.path isDirectory:&isDir]) {
        BOOL ok = NO;
        ok = [fileManager createDirectoryAtPath:[trashURL path] withIntermediateDirectories:YES attributes:nil error:&error];
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return;
        } /*else {
            [[NSUserDefaults standardUserDefaults] setValue:trashURL.path forKey:@"PI_TRASH_PATH"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }*/
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:trashURL.path forKey:@"PI_TRASH_PATH"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    DLog(@"Application did finish launching.");
    
}

-(void)applicationWillTerminate:(NSNotification *)notification
{
    IKImageBrowserView *mImageBrowser = [(MainWindowController *)[self.window delegate] browserView];
    [mImageBrowser unbind:@"zoomValue"];
    [mImageBrowser unbind:@"showTitles"];
	//[mImageBrowser unbind:@"backgroundColor"];
    
	// cleanup
	[Preferences destroy];
	[[SimpleProfiler instance] log];
	[SimpleProfiler destroyInstance];
}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "com.pixite.Unbound5" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.pixite.Unbound5"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Unbound5" withExtension:@"momd"];
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
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"Unbound5.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
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
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
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
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

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
    }

    return NSTerminateNow;
}

@end
