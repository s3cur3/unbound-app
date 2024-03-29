//
//  PIXFileManager.m
//  UnboundApp
//
//  Created by Bob on 1/31/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXFileManager.h"
#import "PIXAppDelegate.h"
#import "PIXFileParser.h"
#import "PIXAlbum.h"
#import "PIXPhoto.h"
#import "PIXDefines.h"
#import "PIXPhotoUtils.h"
#import "Unbound-Swift.h"

#import "PIXProgressWindowController.h"

//#define DEBUG_DELETE_ITEMS 1

enum {
	PIXFileOverwriteDuplicate,
	PIXFileRenameDuplicateSequentially,
	PIXFileSkipDuplicate,
	PIXFileDuplicateError
};
typedef NSUInteger PIXOverwriteStrategy;


@interface PIXFileManager()
{
    PIXOverwriteStrategy overwriteStrategy;
    unsigned pathNumbering;
}

@property (nonatomic, strong) NSArray *selectedFilePaths;

- (BOOL)isImageFile:(NSString *)path;

@end

@implementation PIXFileManager

+ (PIXFileManager *)sharedInstance
{
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)openSelectedFileWithApplication:(NSString *)appPath
{
//    NSString *filePath = <get file path, e.g. from selected table row>
//    [[NSWorkspace sharedWorkspace] openFile:filePath withApplication:appPath];
}

- (void)openFileWithPath:(NSString *)filePath withApplication:(NSString *)appPath
{
    //NSString *filePath = <get file path, e.g. from selected table row>
    //[[NSWorkspace sharedWorkspace] openFile:filePath withApplication:appPath];
    return [self openFileWithPaths:@[filePath] withApplication:appPath];
}

- (void)openFileWithPaths:(NSArray *)filePaths withApplication:(NSString *)appPath
{
    //NSString *filePath = <get file path, e.g. from selected table row>
    for (NSString *filePath in filePaths) {
        [[NSWorkspace sharedWorkspace] openFile:filePath withApplication:appPath];
    }
    
}

/// menu item action
- (void)openWithApplicationSelected:(id)sender
{
    if (![sender isKindOfClass:[NSMenuItem class]]) {
        NSLog(@"Sender should be nsmenuitem");
        return;
    }
    
    NSMenuItem *menuItem = (NSMenuItem *)sender;
    NSDictionary *pathsDict = [menuItem representedObject];
    NSString *appPath = [pathsDict valueForKey:@"appPath"]; //[menuItem representedObject];
    NSArray *filePaths = [pathsDict valueForKey:@"filePaths"];
    if (!appPath) {
        NSLog(@"Could get app path from nsmenuitem represented object");
        return;
    }
    [self openFileWithPaths:filePaths withApplication:appPath];
    //[self openSelectedFileWithApplication:appPath];
}

- (void)openWithApplicationOtherSelected:(id)sender
{
    
    NSDictionary *infoDict = [sender representedObject];
    NSArray *filePathsArray = [infoDict objectForKey:@"filePaths"];
    self.selectedFilePaths = filePathsArray;
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];

    [panel setDirectoryURL:[NSURL fileURLWithPath:@"/Applications"]];
    [panel beginSheetModalForWindow:[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] completionHandler:^(NSInteger result) {
        
        NSArray *someFilePaths = [self.selectedFilePaths copy];
        self.selectedFilePaths = nil;
        if (result == NSModalResponseOK)
        {
            [panel close];
            
            [self openFileWithPaths:someFilePaths withApplication:[[panel URL] path]];
            //[self openSelectedFileWithApplication:[panel filename]];
        }
    }];
}

/// construct menu item for app
- (NSMenuItem *)menuItemForOpenWithForApplication:(NSString *)appName appPath:(NSString *)appPath filePaths:(NSArray<NSString *> *)filePaths
{
    NSMenuItem *newAppItem = [[NSMenuItem alloc] init];
    [newAppItem setTitle:appName];
    [newAppItem setTarget:self];
    [newAppItem setAction:@selector(openWithApplicationSelected:)];
    NSDictionary *pathsDict = @{@"appPath" : appPath, @"filePaths": filePaths};
    [newAppItem setRepresentedObject:pathsDict];
    //[newAppItem setRepresentedObject:appPath];
    NSImage *icon = [NSWorkspace.sharedWorkspace iconForFile:appPath];
    icon.size = NSMakeSize(16.0, 16.0);
    newAppItem.image = icon;
    return newAppItem;
}

-(NSString *)defaultAppNameForOpeningFileWithPath:(NSString *)filePath
{
    NSString *defaultAppPath = [self defaultAppPathForOpeningFileWithPath:filePath];
    //NSString *defaultAppName = [[[defaultAppPath lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@" (default)"];
    NSString *defaultAppName = [[defaultAppPath lastPathComponent] stringByDeletingPathExtension];
    return defaultAppName;
}

-(NSString *)defaultAppPathForOpeningFileWithPath:(NSString *)filePath
{
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    //get and add default app
    CFURLRef defaultApp;
    LSGetApplicationForURL((__bridge CFURLRef)fileURL, kLSRolesAll, NULL, &defaultApp);
    if (!defaultApp) {
        NSLog(@"There is no default App for %@", filePath);
        return nil;
    }
    NSString *defaultAppPath = [(__bridge NSURL *)defaultApp path];
    return defaultAppPath;
}

/// this method return open with menu for specified file
- (NSMenu *)openWithMenuItemForFile:(NSString *)filePath
{
    return [self openWithMenuItemForFiles:@[filePath]];
}

/// this method return open with menu for specified files
- (NSMenu *)openWithMenuItemForFiles:(NSArray<NSString *> *)filePaths {
    NSMenu *subMenu = [[NSMenu alloc] init];
    NSURL *fileURL = [NSURL fileURLWithPath:filePaths.lastObject];
    CFArrayRef cfArrayOfApps = LSCopyApplicationURLsForURL((__bridge CFURLRef)fileURL, kLSRolesAll);
    CFIndex maxCount = 12;
    NSMutableSet *alreadyAdded = [NSMutableSet setWithCapacity:(NSUInteger) maxCount];
	if (cfArrayOfApps != nil)
	{
		CFIndex count = CFArrayGetCount(cfArrayOfApps);
        if (count > maxCount) {
            count = maxCount;
        }
        //get and add default app
        CFURLRef defaultApp = LSCopyDefaultApplicationURLForURL((__bridge CFURLRef)fileURL, kLSRolesAll, NULL);
        if (!defaultApp) {
            NSLog(@"There is no default App for %@", fileURL);
            NSMenuItem *noneItem = [[NSMenuItem alloc] init];
            [noneItem setTitle:@"<None>"];
            [noneItem setEnabled:NO];
            [subMenu addItem:noneItem];
            [subMenu addItem:[NSMenuItem separatorItem]];
        }
        else {
            NSString *defaultAppPath = [(__bridge NSURL *)defaultApp path];
            NSString *defaultAppName = [[[defaultAppPath lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@" (default)"];
            NSMenuItem *newAppItem = [self menuItemForOpenWithForApplication:defaultAppName appPath:defaultAppPath filePaths:filePaths];
            [subMenu addItem:newAppItem];
            [subMenu addItem:[NSMenuItem separatorItem]];
            if (count != 0) {
                for (int index = 0; index < count; ++index)
                {
                    NSURL *appURL = (NSURL *)CFArrayGetValueAtIndex(cfArrayOfApps, index);
                    if ([appURL isFileURL])
                    {
                        NSString *appName = [[[appURL path] lastPathComponent] stringByDeletingPathExtension];
                        if ([alreadyAdded containsObject:appName]) {
                            appName = [appName stringByAppendingFormat:@" (%@)", [[[NSBundle bundleWithPath:defaultAppPath] infoDictionary] valueForKey:@"CFBundleVersion"]];
                        }
                        NSMenuItem *newAppItem = [self menuItemForOpenWithForApplication:appName appPath:[appURL path] filePaths:filePaths];
                        [alreadyAdded addObject:appName];
                        [subMenu addItem:newAppItem];
                    }
                }
                [subMenu addItem:[NSMenuItem separatorItem]];
            }
        }


        NSMenuItem *otherAppItem = [[NSMenuItem alloc] init];
        [otherAppItem setTitle:@"Other…"];
        [otherAppItem setTarget:self];
        [otherAppItem setAction:@selector(openWithApplicationOtherSelected:)];
        NSDictionary *pathsDict = @{@"filePaths": filePaths};
        [otherAppItem setRepresentedObject:pathsDict];
        [subMenu addItem:otherAppItem];
        
        CFRelease(cfArrayOfApps);
    }
    return subMenu;
}


-(void)undoRecyclePhotos:(NSDictionary *)newURLs
{
    //NSWorkspaceDidPerformFileOperationNotification
    NSMutableSet *filePaths = [NSMutableSet set];
    NSURL *restorePathURL = nil;
    for (restorePathURL in [newURLs allKeys])
    {
        NSURL *recyclerPathURL = [newURLs objectForKey:restorePathURL];
        NSString *restorePath = [restorePathURL.path stringByDeletingLastPathComponent];
        NSString *recyclerPath = [recyclerPathURL.path stringByDeletingLastPathComponent];
        NSString *fileName = [recyclerPathURL.path lastPathComponent];
        
        DLog(@"Restoring file to '%@'", restorePath);
        if (![[NSWorkspace sharedWorkspace]
         performFileOperation:NSWorkspaceMoveOperation
         source: recyclerPath
         destination:restorePath
         files:[NSArray arrayWithObject:fileName]
         tag:nil])
        {
            DLog(@"Unable to restore from Trash");
            continue;
        }
        
        if(restorePath)
        {
            restorePath = [restorePath stringByAppendingPathComponent:fileName];
            [filePaths addObject:restorePath];
        }
        
        DLog(@"Restored file from '%@'", recyclerPath);
        
        
    }
    
    for (NSString *filePath in filePaths)
    {
        [[PIXFileParser sharedFileParser] scanFile:[NSURL fileURLWithPath:filePath]];
    }

    NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
    //TODO: find a better way of dealing with the 'redo' action for recycled items
    [undoManager performSelector:@selector(removeAllActions) withObject:nil afterDelay:0.1f];
}

-(void)recyclePhotos:(NSArray *)items
{
    NSMutableArray *urlsToDelete = [NSMutableArray arrayWithCapacity:[items count]];
    
    NSManagedObjectContext * context = [[PIXAppDelegate sharedAppDelegate] managedObjectContext];

    for (id anItem in items)
    {
        NSString *path = [anItem path];
        NSURL *deleteURL = [NSURL fileURLWithPath:path isDirectory:NO];
        
        if(deleteURL)
        {
            [urlsToDelete addObject:deleteURL];
        }
    }
    
    // Delete the items from the db ahead of time (the actul file deletion will happen after a dispatch)
    NSMutableSet *albumsToUpdate = [[NSMutableSet alloc] init];
    
    for (PIXPhoto *anItem in items)
    {
        PIXAlbum * album = [anItem album];
        
        if(album)
        {
            [albumsToUpdate addObject:album];
        }
        
        // delete the photos from the database
        [context deleteObject:anItem];
    }
    
    NSError * error_ignored = nil;
    [context save:&error_ignored];

    for(PIXAlbum * album in albumsToUpdate)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:album userInfo:nil];
    }
    
    DLog(@"About to recycle the following items : %@", urlsToDelete);

    [[NSWorkspace sharedWorkspace] recycleURLs:urlsToDelete completionHandler:^(NSDictionary *newURLs, NSError *error) {
        if (nil==error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                /*
                // scan the paths just to make sure everything worked
                for (PIXAlbum *anAlbum in albumsToUpdate)
                {
                    [[PIXFileParser sharedFileParser] scanPath:anAlbum.path withRecursion:PIXFileParserRecursionNone];
                    [anAlbum flush];
                }
                
                [[PIXAppDelegate sharedAppDelegate] saveDBToDisk:nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
                 */
                
                NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];

                [undoManager registerUndoWithTarget:[PIXFileManager sharedInstance] selector:@selector(undoRecyclePhotos:) object:newURLs];
                [undoManager setActionIsDiscardable:YES];
                NSUInteger deletionCount = [newURLs count];
                NSString *undoMessage = @"Delete Photo";
                if (deletionCount>1) {
                    undoMessage = [NSString stringWithFormat:@"Delete %ld Photos", deletionCount];
                }
                [undoManager setActionName:undoMessage];
            });
        } else {
            //Some photos coudln't be deleted. Present the error and setup undo operation for items that were succesfully deleted
            [[NSApplication sharedApplication] presentError:error];
            NSArray *sucessfullyDeletedItems = [newURLs allKeys];
            NSUInteger itemDeletionCount = [sucessfullyDeletedItems count];
            
            if (itemDeletionCount == 0) {
                //No items were deleted so no need to setup undo operation
                //[[[PIXAppDelegate sharedAppDelegate] managedObjectContext] discardEditing];
                
                // rescan the albums so they're correct
                for (PIXAlbum *anAlbum in albumsToUpdate)
                {
                    //[anAlbum updateAlbumBecausePhotosDidChange];
                    [[PIXFileParser sharedFileParser] scanPath:anAlbum.path withRecursion:PIXFileParserRecursionNone];
                    [anAlbum flush];
                }
                
                
                return;
            }
            
#warning albumsToUpdate will always be empty below... WTF?
            NSMutableSet *albumsToUpdate = [[NSMutableSet alloc] init];
            NSMutableSet *photosToDelete = [[NSMutableSet alloc] init];
            for (id anItem in sucessfullyDeletedItems)
            {
                DLog(@"Item at '%@' was recycled", anItem);
                NSString *aPhotoPath = [anItem path];
                
                if(aPhotoPath)
                {
                    [photosToDelete addObject:aPhotoPath];
                }
            }

            // rescan the albums so they're correct
            for (PIXAlbum *anAlbum in albumsToUpdate)
            {
                //[anAlbum updateAlbumBecausePhotosDidChange];
                [[PIXFileParser sharedFileParser] scanPath:anAlbum.path withRecursion:PIXFileParserRecursionNone];
                [anAlbum flush];
            }

            [[PIXAppDelegate sharedAppDelegate] saveDBToDisk:nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
            
            NSString *undoMessage = @"Delete Photo";
            if (itemDeletionCount>1) {
                undoMessage = [NSString stringWithFormat:@"Delete %ld Items", itemDeletionCount];
            }
            
            NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
            [undoManager registerUndoWithTarget:[PIXFileManager sharedInstance] selector:@selector(undoRecyclePhotos:) object:newURLs];
            [undoManager setActionIsDiscardable:YES];
            [undoManager setActionName:undoMessage];
        }
        
}];
    
    DLog(@"Completed file deletion");
}

+ (BOOL)fileIsMetadataFile:(NSURL *)url
{
#if ONLY_LOAD_ALBUMS_WITH_IMAGES
    return NO;
#endif
    
    BOOL isUnboundMetadataFile = NO;
    if ([url.path.lastPathComponent isEqualToString:kUnboundAlbumMetadataFileName] ||
        [url.path.lastPathComponent isEqualToString:@".DS_Store"])
    {
        isUnboundMetadataFile = YES;
    }
    return isUnboundMetadataFile;
    
}

- (void) duplicatePhotos:(NSSet<PIXPhoto *> *)selectedPhotos
{
    NSMutableArray *urlsToDuplicate = [NSMutableArray arrayWithCapacity:[selectedPhotos count]];

    for (PIXPhoto* photo in selectedPhotos)
    {
        NSString *path = [photo path];
        NSURL *dupeURL = [NSURL fileURLWithPath:path isDirectory:NO];

        if(dupeURL)
        {
            [urlsToDuplicate addObject:dupeURL];
        }
    }

    [self duplicatePhotoURLs:urlsToDuplicate];
}

/*
 The issue addressed below is that `NSUndoManager` only understands that an undo action you register is actually
 a "redo" if you register while it is still executing a previous undo. And conversely, if you want undo to work
 after redoing, again it needs to be set up in the same runloop. So we must register the undo action immediately,
 and then update its context object with the necessary information once we have it.
 */

- (void) duplicatePhotoURLs:(NSArray<NSURL *> *)urlsToDuplicate
{
    // must set this up in the same runloop we are called in for undo/redo to work properly
    NSMutableDictionary<NSURL *,NSURL *> *duplicatedURLMap = [[NSMutableDictionary alloc] init];
    NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
    [undoManager registerUndoWithTarget:[PIXFileManager sharedInstance] selector:@selector(undoDuplicatePhotos:) object:duplicatedURLMap];
    [undoManager setActionIsDiscardable:YES];
    [undoManager setActionName:NSLocalizedString(@"undo.duplicate_photo", @"Duplicate Photo")];

    [[NSWorkspace sharedWorkspace] duplicateURLs:urlsToDuplicate completionHandler:^(NSDictionary *newURLs, NSError *error) {
        if (error != nil) {
            //Some photos couldn't be duplicated. Present the error.
            [[NSApplication sharedApplication] presentError:error];
        }

        NSArray *sucessfullyDuplicatedItems = [newURLs allKeys];

        NSMutableSet<NSURL *> *changedDirectories = [[NSMutableSet alloc] init];

        for (NSURL* url in sucessfullyDuplicatedItems) {
            NSURL* parentDir = url.URLByDeletingLastPathComponent;
            [changedDirectories addObject:parentDir];
        }

        // apparently we must manually rescan or the app will not notice the new file
        for (NSURL* url in changedDirectories) {
            [[PIXFileParser sharedFileParser] scanURLForChanges:url withRecursion:PIXFileParserRecursionNone];
        }

        [duplicatedURLMap addEntriesFromDictionary:newURLs];
    }];
}

- (void) undoDuplicatePhotos:(NSDictionary<NSURL *,NSURL *> *)duplicationURLs {
    NSArray<NSURL*> *urlsToDelete = [duplicationURLs allValues];

    // must set this up in the same runloop we are called in for undo/redo to work properly
    NSMutableArray<NSURL*> *reduplicableURLs = [[NSMutableArray alloc] init];
    NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
    [undoManager registerUndoWithTarget:[PIXFileManager sharedInstance] selector:@selector(duplicatePhotoURLs:) object:reduplicableURLs];
    [undoManager setActionIsDiscardable:YES];
    [undoManager setActionName:NSLocalizedString(@"undo.duplicate_photo", @"Duplicate Photo")];

    [[NSWorkspace sharedWorkspace] recycleURLs:urlsToDelete completionHandler:^(NSDictionary<NSURL *,NSURL *> *newURLs, NSError *error) {
        if (error != nil) {
            //Some photos couldn't be un-duplicated. Present the error.
            [[NSApplication sharedApplication] presentError:error];
        }

        NSArray *sucessfullyDeletedItems = [newURLs allKeys];

        NSMutableSet<NSURL *> *changedDirectories = [[NSMutableSet alloc] init];

        for (NSURL* url in sucessfullyDeletedItems) {
            NSURL* parentDir = url.URLByDeletingLastPathComponent;
            [changedDirectories addObject:parentDir];
        }

        // rescan or the app will not notice the new file
        for (NSURL* url in changedDirectories) {
            [[PIXFileParser sharedFileParser] scanURLForChanges:url withRecursion:PIXFileParserRecursionNone];
        }

        NSArray<NSURL*> *dupeURLs = [[duplicationURLs keysOfEntriesPassingTest:^BOOL(NSURL * _Nonnull key, NSURL * _Nonnull obj, BOOL * _Nonnull stop) {
            return [sucessfullyDeletedItems containsObject:obj];
        }] allObjects];

        [reduplicableURLs addObjectsFromArray:dupeURLs];
    }];
}

- (void) deleteItemsWorkflow:(NSSet *)selectedItems
{
    // if we have nothing to delete then do nothing
    if([selectedItems count] == 0) return;
    
    NSMutableArray *itemsToDelete = [[selectedItems allObjects] mutableCopy];

    NSManagedObject *object = [itemsToDelete lastObject];
    NSString *objectType = @"Item";
    
    NSString * suppressKey = nil;
    
    if([object isKindOfClass:[PIXPhoto class]])
    {
        objectType = PHOTO;
        suppressKey = @"PIX_supressPhotoDeleteWarning";
    } else if([object isKindOfClass:[PIXAlbum class]]) {
        objectType = ALBUM;
        suppressKey = @"PIX_supressAlbumDeleteWarning";
    }
	NSString * deleteString = [itemsToDelete count] > 1 ?
							  [NSString stringWithFormat:@"%ld %@s", [itemsToDelete count], objectType] :
							  objectType;
    
    NSString *warningTitle = [NSString stringWithFormat:@"Delete %@?", deleteString];
    NSString *warningButtonConfirm = [NSString stringWithFormat:@"Delete %@", deleteString];
    NSString *warningMessage = [NSString stringWithFormat:@"The %@ will be deleted from your file system and moved to the trash.\n\nAre you sure you want to continue?", deleteString.lowercaseString];
    
    if([object isKindOfClass:[PIXAlbum class]])
    {
        if([itemsToDelete count] > 1)
        {
            warningMessage = @"The albums and their corresponding folders will be deleted from your file system and moved to the trash.\n\nAre you sure you want to continue?";
        }
        
        else
        {
            PIXAlbum * album = (PIXAlbum *)object;
            
            warningMessage = [NSString stringWithFormat:@"The album and its corresponding folder will be deleted from your file system and moved to the trash.\n\n%@\n\nAre you sure you want to continue?", album.path];
            
            
        }
    }
    
    
    NSAlert *alert = nil;
    
    // suppress the alert if they've ticked the box
    BOOL suppressAlert = [[NSUserDefaults standardUserDefaults] boolForKey:suppressKey];

    if(!suppressAlert)
    {
        alert = [[NSAlert alloc] init];
        [alert setMessageText:warningTitle];
        [alert addButtonWithTitle:warningButtonConfirm];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setInformativeText:warningMessage];
        [alert setShowsSuppressionButton:YES];
        [[alert suppressionButton] setTitle:@"Don't warn me again."];
    }
    
    if (suppressAlert || [alert runModal] == NSAlertFirstButtonReturn) {
        
        if ([[alert suppressionButton] state] == NSControlStateValueOn) {
            // Suppress this alert from now on.
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:suppressKey];
        }
        
        
        if ([[itemsToDelete lastObject] class] == [PIXAlbum class]) {
            [self recycleAlbums:itemsToDelete];
        } else {
            [self recyclePhotos:itemsToDelete];
        }
        
    } else {
        // User clicked cancel, they do not want to delete the files
    }
    
}



-(BOOL)shouldDeleteAlbumAtPath:(NSString *)directoryPath
{
    NSURL *directoryURL = [NSURL fileURLWithPath:directoryPath isDirectory:YES];
    NSFileManager *localFileManager=[[NSFileManager alloc] init];
	NSDirectoryEnumerator *enumerator =
    [localFileManager enumeratorAtURL:directoryURL
                                             includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey,
                                                                         NSURLIsDirectoryKey,nil]
                                                                options:(/*NSDirectoryEnumerationSkipsHiddenFiles |*/ NSDirectoryEnumerationSkipsPackageDescendants)
                                                           errorHandler:^(NSURL *errUrl, NSError *error) {
                                                               // Handle the error.
                                                               [PIXAppDelegate presentError:error];
                                                               // Return YES if the enumeration should continue after the error.
                                                               return YES;
                                                           }];
    
    
    NSURL *url;
    while (url = [enumerator nextObject]) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            DLog(@"error on getResourceValue for file %@ : %@", url.path, error);
            [[NSApplication sharedApplication] presentError:error];
        }
        
        if ([PIXFileManager fileIsMetadataFile:url]) {
            continue;
        }
        
        //if a subdirectory is found, then do not delete
        if([isDirectory boolValue]) {
            DLog(@"found subdirectory at : %@", url.path);
            return NO;
        }
        
        //If a non-image file is found, do not delete
        if(![self isImageFile:url.path])
        {
            return NO;
        }
    }
    return YES;
    
}

-(BOOL)undoRenameAlbum:(NSDictionary *)userInfo
{
    //NSManagedObjectID *albumID = [userInfo objectForKey:@""];
    NSString *path = [userInfo objectForKey:@"path"];
    NSString *name = [userInfo objectForKey:@"name"];
    return [self renameAlbumWithPath:path withName:name];
    //return [self renameAlbumWithObjectID:albumID withName:name];
}

-(BOOL)undoRenamePhoto:(NSDictionary *)userInfo
{
    //NSManagedObjectID *albumID = [userInfo objectForKey:@""];
    NSString *path = [userInfo objectForKey:@"path"];
    NSString *name = [userInfo objectForKey:@"name"];
    return [self renamePhotoWithPath:path withName:name];
    //return [self renameAlbumWithObjectID:albumID withName:name];
}

-(BOOL)renameAlbumWithPath:(NSString *)anAlbumPath withName:(NSString *)aNewName
{
    NSManagedObjectContext *context = [[PIXAppDelegate sharedAppDelegate] managedObjectContext];
    PIXAlbum *anAlbum = (PIXAlbum *)[[PIXFileParser sharedFileParser] fetchAlbumWithPath:anAlbumPath inContext:context];
    
    if (anAlbum==nil) {
        alert(@"Undo Failed", [NSString stringWithFormat:@"Unable to undo album rename operation.\n(%@)", anAlbumPath]);
        return NO;
    }
    return [self renameAlbum:anAlbum withName:aNewName];
}

-(BOOL)renameAlbum:(PIXAlbum *)anAlbum withName:(NSString *)aNewName
{
    
    if([anAlbum isReallyDeleted]) return NO;
    
    if ([aNewName length]==0 || [aNewName isEqualToString:anAlbum.title])
    {
        DLog(@"renaming to empty string or same name disallowed.");
        return NO;
    }
    
    // validate filename
    NSError *error = NULL;
    // after looking into this, it seems macosx supports all unicode characters in filenames. I'll test for / and leave this in just in case we want to add more.
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[/]"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:aNewName
                                                        options:0
                                                          range:NSMakeRange(0, [aNewName length])];
    
    if(numberOfMatches != 0)
    {
        alert(@"Invalid Folder Name", [NSString stringWithFormat:@"\"%@\" is an invalid name for a folder.", aNewName]);
        return NO;
    }
    
    
    NSString *oldAlbumPath = [anAlbum.path copy];
    
    NSString *parentFolderPath = [anAlbum.path stringByDeletingLastPathComponent];
    NSString *oldAlbumName = [anAlbum.path lastPathComponent];
    NSString *newFilePath = [parentFolderPath stringByAppendingPathComponent:aNewName];
    if ([[NSFileManager defaultManager] fileExistsAtPath: newFilePath])
    {
        alert(@"Duplicate Album Name", [NSString stringWithFormat:@"There's already a directory with the name \"%@\" at this album's location. Please enter a different name.", aNewName]);
        return NO;
    }

    BOOL success = [[NSFileManager defaultManager] moveItemAtPath:anAlbum.path toPath:newFilePath error:&error];
    if (!success)
    {
        [[NSApplication sharedApplication] presentError:error];
        return NO;
    }
    
    // fetch any photos and albums with this path or subpath and change them:
    
    // first fetch albums
    NSManagedObjectContext * context = anAlbum.managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:kPhotoEntityName inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path == %@ || path contains %@", oldAlbumPath, [oldAlbumPath stringByAppendingString:@"/"]];
    [fetchRequest setPredicate:predicate];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    
    for (PIXPhoto *aPhoto in fetchedObjects)
    {
        
        NSString *newPhotoPath = [aPhoto.path stringByReplacingOccurrencesOfString:oldAlbumPath withString:newFilePath];
        //DLog(@"changing photo path from %@ to %@", aPhoto.path, newPhotoPath);
        aPhoto.path = newPhotoPath;
    }
    
    [fetchRequest setEntity:[NSEntityDescription entityForName:kAlbumEntityName inManagedObjectContext:context]];
    fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
     
     for (PIXAlbum *eachAlbum in fetchedObjects)
     {
         
         NSString *newAlbumPath = [eachAlbum.path stringByReplacingOccurrencesOfString:oldAlbumPath withString:newFilePath];
         //DLog(@"changing album path from %@ to %@", eachAlbum.path, newAlbumPath);
         eachAlbum.path = newAlbumPath;
     }
     
    if (![[[PIXAppDelegate sharedAppDelegate] managedObjectContext] save:&error]) {
        DLog(@"%@", error);
        [[NSApplication sharedApplication] presentError:error];
        return NO;
    }
    
    // save all the way back to the persistant store
    [[PIXAppDelegate sharedAppDelegate] saveDBToDisk:nil];
    
    for (PIXAlbum *eachAlbum in fetchedObjects)
    {
        [eachAlbum flush];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
    
    
    NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
    //NSDictionary *undoInfo = @{@"albumID" : anAlbum.objectID, @"name" : oldAlbumName};
    NSDictionary *undoInfo = @{@"path" : [anAlbum.path copy], @"name" : [oldAlbumName copy]};
    [undoManager registerUndoWithTarget:self selector:@selector(undoRenameAlbum:) object:undoInfo];
    [undoManager setActionName:@"Rename Album"];
    [undoManager setActionIsDiscardable:YES];
    
    return YES;
}

-(BOOL)renamePhotoWithPath:(NSString *)aPhotoPath withName:(NSString *)aNewName
{
    NSArray * photos = (NSArray *)[[PIXFileParser sharedFileParser] fetchPhotosWithPaths:@[aPhotoPath]];
    
    PIXPhoto * aPhoto = [photos lastObject];
    
    if (aPhoto==nil) {
        alert(@"Undo Failed", [NSString stringWithFormat:@"Unable to undo photo rename operation.\n(%@)", aPhotoPath]);
        return NO;
    }
    return [self renamePhoto:aPhoto withName:aNewName];
}

-(BOOL)renamePhoto:(PIXPhoto *)aPhoto withName:(NSString *)aNewName
{
    if ([aNewName length]==0 || [aNewName isEqualToString:aPhoto.name])
    {
        DLog(@"renaming to empty string or same name disallowed.");
        return NO;
    }
    
    // check if the extention is changing
    
    NSString * oldExtension = [aPhoto.path pathExtension];
    NSString * newExtension = [aNewName pathExtension];
    
    if(![oldExtension isEqualToString:newExtension])
    {
        NSAlert* alert = [[NSAlert alloc] init];
        NSUInteger alertResult;
        
        
        
        //[alert setInformativeText: @"Do you want to replace it?"];
        
        if([newExtension isEqualToString:@""])
        {
            [alert addButtonWithTitle:@"Don't Remove"];
            [alert addButtonWithTitle:@"Remove"];
            
            
            [alert setMessageText: [NSString stringWithFormat: @"Are you sure you want to remove the extension \".%@\"?", oldExtension]];
            [alert setInformativeText:@"If you make this change, your document may open in a different application."];
        }
        
        else if([oldExtension isEqualToString:@""])
        {
            [alert addButtonWithTitle:@"Don't Add"];
            [alert addButtonWithTitle:@"Add"];
            
            
            [alert setMessageText: [NSString stringWithFormat: @"Are you sure you want to add the extension \".%@\"?", newExtension]];
            [alert setInformativeText:@"If you make this change, your document may open in a different application."];
        }

        else
        {
            [alert addButtonWithTitle:[NSString stringWithFormat:@"Keep .%@", oldExtension]];
            [alert addButtonWithTitle:[NSString stringWithFormat:@"Use .%@", newExtension]];
            
            
            [alert setMessageText: [NSString stringWithFormat: @"Are you sure you want to change the extension from \".%@\" to \".%@\"?", oldExtension, newExtension]];
            [alert setInformativeText:@"If you make this change, your document may open in a different application."];
        }
        
        
        
        
        [alert setAlertStyle: NSAlertStyleWarning];
        alertResult = [alert runModal];
        
        if (alertResult == NSAlertFirstButtonReturn)	// Keep
        {
            // change the name back if they chose keep
            aNewName = [[aNewName stringByDeletingPathExtension] stringByAppendingPathExtension:oldExtension];
            
            // if they're the same now do nothing
            if([aNewName isEqualToString:aPhoto.name])
            {
                return NO;
            }
            
        }
    }
    
    // validate filename
    NSError *error = NULL;
    
    // after looking into this, it seems macosx supports all unicode characters in filenames. I'll test for / and leave this in just in case we want ot add more.
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[/]"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:aNewName
                                                        options:0
                                                          range:NSMakeRange(0, [aNewName length])];
    
    if(numberOfMatches != 0)
    {
        alert(@"Invalid File Name", [NSString stringWithFormat:@"\"%@\" is an invalid name for a file.", aNewName]);
        return NO;
    }
    
    
    NSString *parentFolderPath = [aPhoto.album path];
    NSString *oldPhotoName = aPhoto.name;
    NSString *newFilePath = [parentFolderPath stringByAppendingPathComponent:aNewName];
    
    if ([[NSFileManager defaultManager]
         fileExistsAtPath: newFilePath])
    {
        alert(@"Duplicate Photo Name", [NSString stringWithFormat:@"There's already a photo with the name \"%@\" at this album's location. Please enter a different name.", aNewName]);
        return NO;
    }
    
    BOOL success = [[NSFileManager defaultManager] moveItemAtPath:aPhoto.path toPath:newFilePath error:&error];
    if (!success)
    {
        [[NSApplication sharedApplication] presentError:error];
        return NO;
    }
    
    [aPhoto setName:aNewName];
    [aPhoto setPath:newFilePath];
    
    if (![[[PIXAppDelegate sharedAppDelegate] managedObjectContext] save:&error]) {
        DLog(@"%@", error);
        [[NSApplication sharedApplication] presentError:error];
        return NO;
    }
    

    [[PIXFileParser sharedFileParser] scanPath:parentFolderPath withRecursion:PIXFileParserRecursionNone];
    
    
    NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
    //NSDictionary *undoInfo = @{@"albumID" : anAlbum.objectID, @"name" : oldAlbumName};
    NSDictionary *undoInfo = @{@"path" : [aPhoto path], @"name" : [oldPhotoName copy]};
    [undoManager registerUndoWithTarget:self selector:@selector(undoRenamePhoto:) object:undoInfo];
    [undoManager setActionName:@"Rename Photo"];
    [undoManager setActionIsDiscardable:YES];
    
    // update any views that watch this photo
    [[NSNotificationCenter defaultCenter] postNotificationName:PhotoThumbDidChangeNotification object:self];
    
    return YES;
}

-(void)undoRecycleAlbums:(NSDictionary *)newURLs
{
    //TODO: consider use this notification for progress bar if many files are to be restored
    //NSWorkspaceDidPerformFileOperationNotification
    NSMutableSet *albumPaths = [NSMutableSet set];
    NSURL *restorePathURL = nil;
    for (restorePathURL in [newURLs allKeys])
    {
        NSURL *recyclerPathURL = [newURLs objectForKey:restorePathURL];
        NSString *restorePath = [restorePathURL.path stringByDeletingLastPathComponent];
        NSString *recyclerPath = [recyclerPathURL.path stringByDeletingLastPathComponent];
        NSString *fileName = [recyclerPathURL.path lastPathComponent];
        
        DLog(@"Restoring file to '%@'", restorePath);
        if (![[NSWorkspace sharedWorkspace]
              performFileOperation:NSWorkspaceMoveOperation
              source: recyclerPath
              destination:restorePath
              files:[NSArray arrayWithObject:fileName]
              tag:nil])
        {
            DLog(@"Unable to restore from Trash");
            continue;
        }
        
        if(restorePath)
        {
            [albumPaths addObject:restorePath];
        }
        
        DLog(@"Restored file from '%@'", recyclerPath);
    }
    
    for (NSString *albumPath in albumPaths)
    {
        [[PIXFileParser sharedFileParser] scanPath:albumPath withRecursion:PIXFileParserRecursionFull];
    }
    
    NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
    //TODO: find a better way of dealing with the 'redo' action for recycled items
    [undoManager performSelector:@selector(removeAllActions) withObject:nil afterDelay:0.1f];
}

-(void)recycleAlbums:(NSArray *)items
{
    NSMutableArray *urlsToDelete = [NSMutableArray arrayWithCapacity:[items count]];

    for (PIXAlbum * anAlbum in items)
    {
        NSString *albumPath = anAlbum.path;
        if ([self shouldDeleteAlbumAtPath:albumPath]==YES) {
            NSString *path = [anAlbum path];
            NSURL *deleteURL = [NSURL fileURLWithPath:path isDirectory:YES];
            [urlsToDelete addObject:deleteURL];
        } else {
            for (PIXPhoto *anItem in [[anAlbum sortedPhotos] copy])
            {
                NSString *path = [anItem path];
                NSURL *deleteURL = [NSURL fileURLWithPath:path isDirectory:NO];
                [urlsToDelete addObject:deleteURL];
            }
            
            //Delete the unbound metadata file if we are not deleting the directory
            NSString *unboundFilePath = [NSString stringWithFormat:@"%@/%@", albumPath,kUnboundAlbumMetadataFileName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:unboundFilePath]) {
                NSURL *ubMetadataFileURL = [NSURL fileURLWithPath:unboundFilePath];
                [urlsToDelete addObject:ubMetadataFileURL];
            }
            //[self recyclePhotos:[anAlbum.photos array]];
            //[urlsToDelete addObjectsFromArray:[[anAlbum.photos array] copy]];
        }
        //[[PIXAppDelegate sharedAppDelegate] deleteAlbumWithPath:anAlbum.path];
        [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] deleteObject:anAlbum];
    }
    
    // create a progress sheet if we're recycling more than 5 items
    PIXProgressWindowController * progressSheet = nil;
    if([urlsToDelete count] > 5)
    {
        progressSheet = [[PIXProgressWindowController alloc] initWithWindowNibName:@"PIXProgressWindowController"];
        
        progressSheet.messageText = @"Moving Files to the Trash";
        [progressSheet.progressBar startAnimation:self];
        
        NSWindow * mainWindow = [[[PIXAppDelegate sharedAppDelegate] mainWindowController] window];
        [[NSApplication sharedApplication] beginSheet:progressSheet.window modalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
        
        [progressSheet.progressBar setIndeterminate:YES];
        [progressSheet.progressBar startAnimation:self];
    }

    DLog(@"About to recycle the following items : %@", urlsToDelete);
    [[NSWorkspace sharedWorkspace] recycleURLs:urlsToDelete completionHandler:^(NSDictionary *newURLs, NSError *error) {
		if(progressSheet != nil)
		{
			[NSApp endSheet:[progressSheet window] returnCode:NSModalResponseOK];
			[[progressSheet window] orderOut:self];
		}

        //
        if (nil==error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[PIXAppDelegate sharedAppDelegate] saveDBToDisk:nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
                
                NSMutableSet *albumPaths = [NSMutableSet new];
                for (NSURL *restorePathURL in [newURLs allKeys])
                {
                    NSString *restorePath = [restorePathURL.path stringByDeletingLastPathComponent];
                    [albumPaths addObject:restorePath];
                }
                NSUInteger albumDeletionCount = [[albumPaths allObjects] count];
                NSString *undoMessage = @"Delete Album";
                if (albumDeletionCount>1) {
                    undoMessage = [NSString stringWithFormat:@"Delete %ld Albums", albumDeletionCount];
                } 
                
                NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
                [undoManager registerUndoWithTarget:[PIXFileManager sharedInstance] selector:@selector(undoRecycleAlbums:) object:newURLs];
                [undoManager setActionIsDiscardable:YES];
                [undoManager setActionName:undoMessage];
            });
            
        } else {
            //Some albums/photos coudln't be deleted. Present the error and setup undo operation for items that were succesfully deleted
            [[NSApplication sharedApplication] presentError:error];
            
            NSArray *sucessfullyDeletedItems = [newURLs allKeys];
            NSUInteger itemDeletionCount = [sucessfullyDeletedItems count];
            
            if (itemDeletionCount == 0) {
                //No items were deleted so no need to setup undo operation
                [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] discardEditing];
                return;
            }
            
            [[PIXAppDelegate sharedAppDelegate] saveDBToDisk:nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
            
            NSString *undoMessage = @"Delete Item";
            if (itemDeletionCount>1) {
                undoMessage = [NSString stringWithFormat:@"Delete %ld Items", itemDeletionCount];
            }
            
            NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
            [undoManager registerUndoWithTarget:[PIXFileManager sharedInstance] selector:@selector(undoRecycleAlbums:) object:newURLs];
            [undoManager setActionIsDiscardable:YES];
            [undoManager setActionName:undoMessage];
        }
        
    }];
}

-(BOOL)directoryIsSubpathOfObservedDirectories:(NSString *)aDirectoryPath
{
    
    
    NSArray *observedDirectories = [[[PIXFileParser sharedFileParser] observedDirectories] valueForKey:@"path"];
    for (NSString *observedPath in observedDirectories)
    {
        if ([aDirectoryPath hasPrefix:observedPath]==YES) {
            
            // if we're dragging from something that is inside a package then it's not observed
            
            NSURL * subURL = [NSURL fileURLWithPath:aDirectoryPath];
            
            // while we're still in the observedPath check all parent folders and see if they are a package
            while ([subURL.path hasPrefix:observedPath]==YES) {
                
                NSNumber * isPackage;
                
                [subURL getResourceValue:&isPackage forKey:NSURLIsPackageKey error:nil];
                
                if([isPackage boolValue])
                {
                    // return no, this file is not observed
                    return NO;
                }
                
                subURL = [subURL URLByDeletingLastPathComponent];
                
            }
            
            return YES;
        }
    }
    return NO;
}

#pragma mark -
#pragma mark Photo import

-(IBAction)importPhotosToAlbum:(PIXAlbum *)album allowDirectories:(BOOL)allowDirectories
{
    NSOpenPanel * panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:allowDirectories];
    [panel setAllowsMultipleSelection:YES];
    
    // if we have an album to import photos into...    
    if(album && ![album isReallyDeleted]) {
        panel.prompt = @"Copy Into Album";
        NSString * dest = [FileUtilsBridge formatUrlForDisplay:album.filePathURL];
        if(allowDirectories) {
            panel.message = [NSString stringWithFormat:@"Choose photos or folders to copy into %@. Selecting folders will create new albums with the same name.", dest];
        } else {
            panel.message = [NSString stringWithFormat:@"Choose photos to copy into %@", dest];
        }
        
        [panel setCanChooseFiles:YES];
        [panel setAllowedFileTypes:@[@"public.image"]];
    }
    else
    {
        album = nil;
        NSString * firstLibraryDir = [FileUtilsBridge formatUrlForDisplay:PIXFileParser.sharedFileParser.observedDirectories[0]];
        panel.prompt = [NSString stringWithFormat:@"Copy Folder(s) into %@", firstLibraryDir];
        panel.defaultButtonCell.title = [NSString stringWithFormat:@"Copy Into %@", firstLibraryDir];
        [panel setCanChooseFiles:NO];
    }
    
    NSWindow * mainWindow = [[[PIXAppDelegate sharedAppDelegate] mainWindowController] window];
    [panel beginSheetModalForWindow:mainWindow completionHandler:^(NSInteger result) {
        
        // if the user pressed ok, then copy the files into the correct folder
        if(result == NSModalResponseOK)
        {
            // go through selected items and create the copy items array
            BOOL containsDirectories = NO;
                        
            
            NSMutableArray * items = [[NSMutableArray alloc] initWithCapacity:[panel.URLs count]];
            
            for(NSURL * aURL in panel.URLs)
            {
                // if the user is importing from the observed directory alert them and stop the import
                if([self directoryIsSubpathOfObservedDirectories:[aURL path]])
                {
                    NSAlert* alert = [[NSAlert alloc] init];
                    [alert addButtonWithTitle:@"OK"];
                    [alert setMessageText: @"Cannot copy from main photos folder"];
                    [alert setInformativeText:@"The files you chose to copy are already accessible in Unbound."];
                    [alert beginSheetModalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
                     
                     // don't do anything if the user did this
                     [items removeAllObjects];
                     break;
                }
                
                NSNumber * isFolder = [NSNumber numberWithBool:NO];
                [aURL getResourceValue:&isFolder forKey:NSURLIsDirectoryKey error:NULL];
                
                if([isFolder boolValue])
                {
                    containsDirectories = YES;
                    [items addObject:@{@"source" : [aURL path], @"destination" : [self defaultPhotosPath], @"isDirectory": [NSNumber numberWithBool:YES]}];
                }
                
                else
                {
                    [items addObject:@{@"source" : [aURL path], @"destination" : [album path]}];
                }
                
            }
            
            if([items count] > 0)
            {
                // if we're adding directories then navigate to the root view
                if(containsDirectories)
                {
                    [[[[PIXAppDelegate sharedAppDelegate] mainWindowController] navigationViewController] popToRootViewController];
                }
                
                [self copyFiles:items];
            }
        }
        
    }];
}

//TODO: background thread these operations
-(void)moveFiles:(NSArray *)items
{
    DLog(@"moving %ld files...", items.count);
    NSString *aDestinationPath = [[items lastObject] valueForKey:@"destination"];
    NSURL *destinationURL = [NSURL fileURLWithPath:aDestinationPath isDirectory:YES];
    
    BOOL hadLockedFiles = NO;
    NSMutableArray * validatedFiles = [NSMutableArray new];
    // remove any locked files
    for(id file in items)
	{
        NSString *sourcePath = [file objectForKey:@"source"];
        
        NSError * error;
        NSDictionary *attributes =  [[NSFileManager defaultManager] attributesOfItemAtPath:sourcePath error:&error];
        BOOL isLocked = [[attributes objectForKey:@"NSFileImmutable"] boolValue];
        if(!isLocked)
        {
            [validatedFiles addObject:file];
        }
        else
        {
            hadLockedFiles = YES;
        }
    }
    
    if(hadLockedFiles)
    {
        // alert the user if some of the files were locked
        
        NSAlert* alert = [[NSAlert alloc] init];
        alert.messageText = @"Unable to Move Locked Files";
        alert.informativeText = @"Some of the files you tried to move are currently locked. These files will not be moved.";
        
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Cancel Move"];
        
        if([alert runModal] == NSAlertSecondButtonReturn)
        {
            return;
        }
    }

    items = validatedFiles;

    NSArray *newItems = [self userValidatedFiles:items forDestination:destinationURL];
    if (newItems.count == 0) {
        return;
    } else {
        DLog(@"\nOld destinations : %@", [items valueForKey:@"destination"]);
        DLog(@"\nNew destinations : %@", [newItems valueForKey:@"destination"]);
    }
    items = newItems;
    
    NSMutableArray *undoArray = [NSMutableArray arrayWithCapacity:items.count];
    NSMutableSet *albumPaths = [[NSMutableSet alloc] init];
    
    NSMutableSet * changedAlbums = [[NSMutableSet alloc] init];
    
    NSManagedObjectContext * context = [[PIXAppDelegate sharedAppDelegate] managedObjectContext];
    for (id aDict in items)
    {
        NSString *src = [aDict valueForKey:@"source"];
        NSString *dest = [aDict valueForKey:@"destination"];
        NSString *filename = [src lastPathComponent];
        //BOOL destintationWasRenamed = NO; // this was never used. Commenting out
        //There was a conflicting filename at destination, so file will be renamed.
        if ([aDict objectForKey:@"destinationFileName"]!=nil) {
            //destintationWasRenamed = YES; this was never read (analyzer warning)
            filename = [aDict objectForKey:@"destinationFileName"];
        }
        
        [albumPaths addObject:[src stringByDeletingLastPathComponent]];
        [albumPaths addObject:dest];
        
        NSString *undoSrc = [NSString stringWithFormat:@"%@/%@", dest, filename];
        NSString *undoDest = [src stringByDeletingLastPathComponent];
        
        [undoArray addObject:@{@"source" : undoSrc, @"destination" : undoDest}];
        
        
        // if we have the source photo in the database update it now
        PIXPhoto * srcPhoto = [[[PIXFileParser sharedFileParser] fetchPhotosWithPaths:@[src]] lastObject];
        PIXAlbum * dstAlbum = [[[PIXFileParser sharedFileParser] fetchAlbumsWithPaths:@[dest]] lastObject];
        if(srcPhoto && dstAlbum)
        {
            [changedAlbums addObject:srcPhoto.album];
            [changedAlbums addObject:dstAlbum];
            
            // delete the source photo since it's getting moved somewhere else
            
            NSString * fullDestPath = [dest stringByAppendingPathComponent:srcPhoto.name];
            srcPhoto.path = fullDestPath;
            
            [srcPhoto.album removePhotosObject:srcPhoto];
            
            srcPhoto.album = dstAlbum;
            
        }
    }
    
    // save the context so the db is updated
    
    NSError * error = nil;
    [context save:&error];
    
    //issue a notification to update the ui
    
    // update any albums views
    [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
    
    for(PIXAlbum * anAlbum in changedAlbums)
    {
        [anAlbum flush];
    }

    // now do the actual file moves in the background
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        // move the files
        for (id aDict in items)
        {
            NSString *src = [aDict valueForKey:@"source"];
            NSString *dest = [aDict valueForKey:@"destination"];
            NSString *filename = [src lastPathComponent];
            
            NSString *fullDestPath = [NSString stringWithFormat:@"%@/%@", dest, filename];
            NSError * move_error = nil;
            if(![[NSFileManager defaultManager] moveItemAtPath:src toPath:fullDestPath error:&move_error])
            {
                DLog(@"%@", move_error);
				[PIXAppDelegate presentError:move_error];
            }
        }
        
        // and re-scan the albums in case we screwed up
        for (NSString *albumPath in albumPaths)
        {
            if (![albumPath isEqualToString:[self trashFolderPath]] && [self directoryIsSubpathOfObservedDirectories:albumPath]) {
                [[PIXFileParser sharedFileParser] scanPath:albumPath withRecursion:PIXFileParserRecursionNone];
            }
        }
        
        NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
        [undoManager registerUndoWithTarget:self selector:@selector(moveFiles:) object:undoArray];
        [undoManager setActionName:@"Move Files"];
    });
}


//TODO: background thread these operations
-(void)copyFiles:(NSArray *)items
{
    // present a progress sheet while copying files (this can be slow with lots of files)
    
    PIXProgressWindowController * progressSheet = [[PIXProgressWindowController alloc] initWithWindowNibName:@"PIXProgressWindowController"];
    
    progressSheet.messageText = @"Copying Files";
    [progressSheet.progressBar startAnimation:self];
    
    NSWindow * mainWindow = [[[PIXAppDelegate sharedAppDelegate] mainWindowController] window];
    [[NSApplication sharedApplication] beginSheet:progressSheet.window modalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
    
    if(items.count > 2)
    {
        [progressSheet.progressBar setIndeterminate:NO];
    }
    else
    {
        [progressSheet.progressBar setIndeterminate:YES];
        [progressSheet.progressBar startAnimation:self];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        DLog(@"copying %ld files...", items.count);

        NSString *aDestinationPath = [[items lastObject] valueForKey:@"destination"];
        NSURL *destinationURL = [NSURL fileURLWithPath:aDestinationPath isDirectory:YES];
        //NSArray *srcPaths = [items valueForKey:@"source"];
        //    NSMutableArray *srcFileNames = [NSMutableArray arrayWithCapacity:srcPaths.count];
        //    for (NSString *srcPath in srcPaths)
        //    {
        //        [srcFileNames addObject:[srcPath stringByDeletingLastPathComponent]];
        //    }
        NSArray *validatedItems = [self userValidatedFiles:items forDestination:destinationURL];
        if (validatedItems.count == 0) {
            [NSApp endSheet:[progressSheet window] returnCode:NSModalResponseOK];
            [[progressSheet window] orderOut:self];
            return;
        } else {//if (newItems.count != items.count) {
            //Update items based on user's replace preferences
            DLog(@"\nOld destinations : %@", [items valueForKey:@"destination"]);
            DLog(@"\nNew destinations : %@", [validatedItems valueForKey:@"destination"]);
        }
        
        
        NSString *trashFolder = [[PIXFileManager sharedInstance] trashFolderPath];
        
        // use these to keep track of which albums to refresh
        NSMutableSet *albumPaths = [[NSMutableSet alloc] init];
        NSMutableSet *recursiveAlbumPaths = [[NSMutableSet alloc] init];
        
        float itemCount = validatedItems.count;
        float currentItem = 0;
		
        for (id aDict in validatedItems)
        {
            BOOL destintationWasRenamed = NO;
            NSString *src = [aDict valueForKey:@"source"];
            NSString *dest = [aDict valueForKey:@"destination"];
            NSString *filename = [src lastPathComponent];
            
            
            if ([aDict objectForKey:@"destinationFileName"]!=nil)
            {
                destintationWasRenamed = YES;
                filename = [aDict objectForKey:@"destinationFileName"];
            }
            
            NSString *fullDestPath = [dest stringByAppendingPathComponent:filename];
            if([[aDict objectForKey:@"isDirectory"] boolValue])
            {
                [recursiveAlbumPaths addObject:fullDestPath];
            }
            else
            {
                [albumPaths addObject:dest];
            }

            if (!destintationWasRenamed)
            {
                [[NSWorkspace sharedWorkspace]
                 performFileOperation:NSWorkspaceCopyOperation
                 source: [src stringByDeletingLastPathComponent]
                 destination:dest
                 files:[NSArray arrayWithObject:[src lastPathComponent]]
                 tag:nil];
            } else {
                NSError *error = nil;
                [[NSFileManager defaultManager] copyItemAtPath:src toPath:fullDestPath error:&error];
            }
        
            currentItem++;
            progressSheet.progress = currentItem/itemCount;
        }
        
        for (NSString *albumPath in albumPaths)
        {
            if (![albumPath isEqualToString:trashFolder] && [self directoryIsSubpathOfObservedDirectories:albumPath]) {
                [[PIXFileParser sharedFileParser] scanPath:albumPath withRecursion:PIXFileParserRecursionNone];
            }
        }
        
        for (NSString *albumPath in recursiveAlbumPaths)
        {
            if (![albumPath isEqualToString:trashFolder] && [self directoryIsSubpathOfObservedDirectories:albumPath]) {
                [[PIXFileParser sharedFileParser] scanPath:albumPath withRecursion:PIXFileParserRecursionFull];
            }
        }
        
        NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
        [undoManager registerUndoWithTarget:self selector:@selector(undoCopyFiles:) object:validatedItems];
        [undoManager setActionName:@"Copy Files"];
        
        [NSApp endSheet:[progressSheet window] returnCode:NSModalResponseOK];
        [[progressSheet window] orderOut:self];
    });
    
}

// undo copy will just delete the items (no move to trash in this case (was causing conflicts))
-(void)undoCopyFiles:(NSArray *)items
{
    NSMutableSet *albumPaths = [[NSMutableSet alloc] init];
    
    for (id aDict in items)
    {        
        NSString *src = [aDict valueForKey:@"source"];
        NSString *dest = [aDict valueForKey:@"destination"];
        NSString *filename = [src lastPathComponent];
        
        [albumPaths addObject:dest];
        
        if ([aDict objectForKey:@"destinationFileName"]!=nil)
        {
            filename = [aDict objectForKey:@"destinationFileName"];
        }
        
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:[dest stringByAppendingPathComponent:filename] error:&error];
        
        if(error)
        {
            NSLog(@"Error undoing copy: %@", [error description]);
        }
        
        
        
    }
    
    for (NSString *albumPath in albumPaths)
    {
        if ([self directoryIsSubpathOfObservedDirectories:albumPath]) {
            [[PIXFileParser sharedFileParser] scanPath:albumPath withRecursion:PIXFileParserRecursionNone];
        }
    }
    
    
    NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
    [undoManager registerUndoWithTarget:self selector:@selector(copyFiles:) object:items];
    [undoManager setActionName:@"Copy Files"];
}



//----------------------------------------------------------------------------------------
#pragma mark	-
#pragma mark	Helpers

- (NSString*)finalOutputPath:(NSString *)outputPath
{
	if (pathNumbering > 0) {
		
		NSString *basePath = [outputPath stringByDeletingPathExtension];
		NSString *extension = [outputPath pathExtension];
        
        // if we have an extention, add it
        if(extension.length)
        {
            return [NSString stringWithFormat:@"%@ %u.%@", basePath, pathNumbering, extension];
        }
        
        else
        {
            return [NSString stringWithFormat:@"%@ %u", basePath, pathNumbering];
        }
        
	} else
		return outputPath;
}

-(NSUInteger)calculateNumberOfDuplicates:(NSArray *)files
{
    NSUInteger dupeCount = 0;
    NSString *destFolder = [[files lastObject] objectForKey:@"destination"];

    if (destFolder != nil)
    {
        //NSURL *destFolderURL = [NSURL fileURLWithPath:destFolder isDirectory:YES];
        
        for(id file in files)
        {
            NSString *aFileName = [[file objectForKey:@"source"] lastPathComponent];
            NSString *destPath = [destFolder stringByAppendingPathComponent:aFileName];
            if ([[NSFileManager defaultManager]
                 fileExistsAtPath: destPath])
            {
                dupeCount++;
            }
        }
    }
    return dupeCount;
}

- (NSArray*) userValidatedFiles: (NSArray*) files
                 forDestination:     (NSURL*)   destinationURL
{
    overwriteStrategy = PIXFileDuplicateError;
	NSMutableArray* validatedFiles = [NSMutableArray array];
	BOOL yesToAll = NO;
    
	for(id file in files)
	{
        NSString *sourcePath = [file objectForKey:@"source"];
		NSString* const name = [sourcePath lastPathComponent];
        NSString *destPath = [[destinationURL path] stringByAppendingPathComponent: name];
		if ([[NSFileManager defaultManager]
             fileExistsAtPath: destPath])
		{
            if (!yesToAll)
            {
                NSUInteger dupeCount = [self calculateNumberOfDuplicates:files];
                NSAlert* alert = [[NSAlert alloc] init];
                NSUInteger alertResult;
                
                
                //[alert setInformativeText: @"Do you want to replace it?"];
                if (dupeCount > 1) {
                    [alert addButtonWithTitle: @"Keep All"];
                    [alert addButtonWithTitle: @"Cancel"];
                    [alert addButtonWithTitle: @"Skip All"];
                    

                    [alert setMessageText: [NSString stringWithFormat: @"%ld Duplicate File Names", dupeCount]];
                    [alert setInformativeText:[NSString stringWithFormat:@"An item named \"%@\" and %ld others already exist in this location. Do you want to keep both these files and the ones you are moving?", name, dupeCount-1]];
                } else {
                    [alert addButtonWithTitle: @"Keep Both"];
                    [alert addButtonWithTitle: @"Cancel"];
                    [alert addButtonWithTitle: @"Skip"];
                    
                    [alert setMessageText: [NSString stringWithFormat: @"An item named \"%@\" ", name]];
                    [alert setInformativeText:@"already exists in this location. Do you want to keep both this file and the one you are moving?"];
                }
                
                [alert setAlertStyle: NSAlertStyleWarning];
                alertResult = [alert runModal];
                
                if (alertResult == NSAlertFirstButtonReturn)	// Keep
                {
                    overwriteStrategy = PIXFileRenameDuplicateSequentially;
                    yesToAll = YES;

                }
                else if (alertResult == NSAlertSecondButtonReturn)		// Cancel All
                {
                    return [NSArray array];
                } else if (alertResult == NSAlertThirdButtonReturn)	// Skip
                {
                    overwriteStrategy = PIXFileSkipDuplicate;
                    yesToAll = YES;
                    // don't add
                } 
            }
			
            if (overwriteStrategy == PIXFileRenameDuplicateSequentially) {
                pathNumbering = 0;
                NSString *newPath;
                
                do {
                    pathNumbering++;
                    newPath = [self finalOutputPath:destPath];
                } while ([[NSFileManager defaultManager] fileExistsAtPath:newPath]);
                NSMutableDictionary *newFileDict = [NSMutableDictionary dictionaryWithDictionary:file];
                [newFileDict setObject:[newPath lastPathComponent] forKey:@"destinationFileName"];
                [validatedFiles addObject:newFileDict];
            } else if (overwriteStrategy == PIXFileSkipDuplicate) {
                continue;
            } else if (overwriteStrategy == PIXFileOverwriteDuplicate) {
                //TODO: implememnt overwrite strategy
                DLog(@"No overwrite strategy implemented yet");
            } else {
                DLog(@"No overwrite strategy specified!");
            }


            
		}
		else
		{
			[validatedFiles addObject:file];
		}
	}
    
	return validatedFiles;
}

// -------------------------------------------------------------------------------
//	isImageFile:filePath
//
//	Uses LaunchServices and UTIs to detect if a given file path is an image file.
// -------------------------------------------------------------------------------
- (BOOL)isImageFile:(NSString *)path
{
    NSURL *url = [NSURL fileURLWithPath:path];
    BOOL isImageFile = NO;
    
    NSString *utiValue;
    [url getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:nil];
    if (utiValue)
    {
        isImageFile = UTTypeConformsTo((__bridge CFStringRef)utiValue, kUTTypeImage) ||
                      UTTypeConformsTo((__bridge CFStringRef)utiValue, kUTTypeMovie);
    }
    return isImageFile;
}

-(NSArray *)itemsForDraggingInfo:(id <NSDraggingInfo>) draggingInfo forDestination:(NSString *)destPath
{
    //Get the files from the drop
	NSArray * files = [[draggingInfo draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    NSMutableArray *pathsToPaste = [NSMutableArray arrayWithCapacity:[files count]];
    for (NSString * path in files)
    {
		if(![[path stringByDeletingLastPathComponent] isEqualToString:destPath] &&
		   [self isImageFile:path] && ![path isEqualToString:destPath])
		{
            [pathsToPaste addObject:@{@"source" : path, @"destination" : destPath}];
        }
    }
    return pathsToPaste;
}

-(NSString *)trashFolderPath
{
    NSString *trashFolderPathString = [NSString stringWithFormat:@"%@/.Trash", UserHomeDirectory()];
    return trashFolderPathString;
}

-(NSString *)defaultPhotosPath
{
    NSArray *observedDirectories = [[[PIXFileParser sharedFileParser] observedDirectories] valueForKey:@"path"];
    for (NSString *observedPath in observedDirectories)
    {
        if ([[observedPath lastPathComponent] isEqualToString:@"Photos"]) {
            return observedPath;
        }
    }
    if (observedDirectories.count>0) {
        return [observedDirectories objectAtIndex:0];
    }
    //TODO: present an error here?
    return [observedDirectories lastObject];
}

-(PIXAlbum *)createAlbumWithName:(NSString *)aName
{
    return [self createAlbumAtPath:nil withName:aName];
}

-(PIXAlbum *)createAlbumAtPath:(NSString *)aPath withName:(NSString *)aName
{
    NSString *newAlbumPath = nil;
    if (!aPath) {
        NSString *defaultPhotosPathString = [self defaultPhotosPath];
        aPath = defaultPhotosPathString;
    }
    newAlbumPath = [NSString stringWithFormat:@"%@/%@",aPath, aName];
    
    int i = 2;
    // loop until we have an album name that doesn't already exits
    while([[NSFileManager defaultManager] fileExistsAtPath:newAlbumPath])
    {
        newAlbumPath = [NSString stringWithFormat:@"%@/%@ %d",aPath, aName, i];
        i++;
    }
    
    
    //TODO: error handling
    NSError *error;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:newAlbumPath withIntermediateDirectories:YES attributes:nil error:&error])
    {
        [[NSApplication sharedApplication] presentError:error];
        //TODO: try and offer some course of action based on error failure reason
        return nil;
    }
    
    NSManagedObjectContext *aContext = [[PIXAppDelegate sharedAppDelegate] managedObjectContext];
    PIXAlbum *newAlbum = [NSEntityDescription insertNewObjectForEntityForName:kAlbumEntityName inManagedObjectContext:aContext];
    newAlbum.path = newAlbumPath;
    //[[Album alloc] initWithFilePath:newAlbumPath];
    
    [newAlbum setAlbumDate:[NSDate date]];
    [newAlbum setDateLastUpdated:[NSDate date]];
    
    [newAlbum updateUnboundFile];
    
    [aContext save:nil];
    [[PIXAppDelegate sharedAppDelegate] saveDBToDisk:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:AlbumCreatedNotification object:self userInfo:@{@"album": newAlbum}];
    return newAlbum;
}

-(void)setDesktopImage:(PIXPhoto *)aPhoto
{
    NSDictionary *screenOptions = [[NSWorkspace sharedWorkspace] desktopImageOptionsForScreen:[NSScreen mainScreen]];
    NSError *error = nil;
    
    NSURL *aURL = [aPhoto filePath];
    
    [[NSWorkspace sharedWorkspace] setDesktopImageURL:aURL
                                            forScreen:[NSScreen mainScreen]
                                              options:screenOptions
                                                error:&error];
    if (error)
    {
        [NSApp presentError:error];
    }
}

@end
