//
//  PIXFileManager.m
//  UnboundApp
//
//  Created by Bob on 1/31/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXFileManager.h"
#import "PIXAppDelegate.h"
//#import "PIXAppDelegate+CoreDataUtils.h"
#import "PIXFileParser.h"
//#import "MainWindowController.h"
//#import "FileSystemEventController.h"
//#import "Album.h"
#import "PIXAlbum.h"
#import "PIXPhoto.h"
#import <CoreFoundation/CoreFoundation.h>
#import "PIXDefines.h"
#import "PIXMainWindowController.h"

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
    
    /* this was deprecated, replaced it with the code below
    [panel beginSheetForDirectory:@"/Applications"
                             file:nil
                            types:nil
                   modalForWindow:[[PIXAppDelegate sharedAppDelegate] window]
                    modalDelegate:self
                   didEndSelector:@selector(chooseAppSheetClosed:returnCode:contextInfo:)
                      contextInfo:nil];
    */
    
    
    [panel setDirectoryURL:[NSURL fileURLWithPath:@"/Applications"]];
    [panel beginSheetModalForWindow:[[[PIXAppDelegate sharedAppDelegate] mainWindowController] window] completionHandler:^(NSInteger result) {
        
        NSArray *someFilePaths = [self.selectedFilePaths copy];
        self.selectedFilePaths = nil;
        if (result == NSOKButton)
        {
            [panel close];
            
            [self openFileWithPaths:someFilePaths withApplication:[[panel URL] path]];
            //[self openSelectedFileWithApplication:[panel filename]];
        }
    }];
}
/*
- (void)chooseAppSheetClosed:(NSOpenPanel *)panel returnCode:(int)code contextInfo:(NSNumber *)useOptions
{
    NSArray *someFilePaths = [self.selectedFilePaths copy];
    self.selectedFilePaths = nil;
    if (code == NSOKButton)
    {
		[panel close];
        
        [self openFileWithPaths:someFilePaths withApplication:[[panel URL] path]];
        //[self openSelectedFileWithApplication:[panel filename]];
    }
}*/

/// construct menu item for app
- (NSMenuItem *)menuItemForOpenWithForApplication:(NSString *)appName appPath:(NSString *)appPath filePaths:(NSArray *)filePaths
{
    NSMenuItem *newAppItem = [[NSMenuItem alloc] init];
    [newAppItem setTitle:appName];
    [newAppItem setTarget:self];
    [newAppItem setAction:@selector(openWithApplicationSelected:)];
    NSDictionary *pathsDict = @{@"appPath" : appPath, @"filePaths": filePaths};
    [newAppItem setRepresentedObject:pathsDict];
    //[newAppItem setRepresentedObject:appPath];
    [newAppItem setImage:[[NSWorkspace sharedWorkspace] iconForFile:appPath]];
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
- (NSMenu *)openWithMenuItemForFiles:(NSArray *)filePaths
{
    NSMenu *subMenu = [[NSMenu alloc] init];
    NSString *filePath = [filePaths lastObject];
    if (filePath==nil) {
        return nil;
    }
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    CFArrayRef cfArrayOfApps = LSCopyApplicationURLsForURL((__bridge CFURLRef)fileURL, kLSRolesAll);
    CFIndex maxCount = 12;
    NSMutableSet *alreadyAdded = [NSMutableSet setWithCapacity:maxCount];
	if (cfArrayOfApps != nil)
	{
		CFIndex count = CFArrayGetCount(cfArrayOfApps);
        if (count > maxCount) {
            count = maxCount;
        }
        //get and add default app
        CFURLRef defaultApp;
        LSGetApplicationForURL((__bridge CFURLRef)fileURL, kLSRolesAll, NULL, &defaultApp);
        if (!defaultApp) {
            NSLog(@"There is no default App for %@", filePath);
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
        
        [albumPaths addObject:restorePath];
        
        DLog(@"Restored file from '%@'", recyclerPath);
    }
    
    for (NSString *albumPath in albumPaths)
    {
        [[PIXFileParser sharedFileParser] scanPath:albumPath withRecursion:PIXFileParserRecursionNone];
    }
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
    NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
    //TODO: find a better way of dealing with the 'redo' action for recycled items
    [undoManager performSelector:@selector(removeAllActions) withObject:nil afterDelay:0.1f];
}

-(void)recyclePhotos:(NSArray *)items
{
    NSMutableArray *urlsToDelete = [NSMutableArray arrayWithCapacity:[items count]];

    for (id anItem in items)
    {
        NSString *path = [anItem path];
        NSURL *deleteURL = [NSURL fileURLWithPath:path isDirectory:NO];
        [urlsToDelete addObject:deleteURL];
    }
#ifdef DEBUG_DELETE_ITEMS
    NSURL *failURL = [NSURL fileURLWithPath:@"/tmp/bafdlsjkfasfasdss.txt"];
    [urlsToDelete addObject:failURL];
#endif
    DLog(@"About to recycle the following items : %@", urlsToDelete);
    [[NSWorkspace sharedWorkspace] recycleURLs:urlsToDelete completionHandler:^(NSDictionary *newURLs, NSError *error) {
        //
        if (nil==error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSMutableSet *albumsToUpdate = [[NSMutableSet alloc] init];
                
                for (PIXPhoto *anItem in items)
                {
                    [albumsToUpdate addObject:[(PIXPhoto *)anItem album]];
                    [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] deleteObject:anItem];
                }
                
                for (PIXAlbum *anAlbum in albumsToUpdate)
                {
                    //[anAlbum updateAlbumBecausePhotosDidChange];
                    [[PIXFileParser sharedFileParser] scanPath:anAlbum.path withRecursion:PIXFileParserRecursionNone];
                    [anAlbum flush];
                }
                
                [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] save:nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
                
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
                return;
            }
            
            NSMutableSet *albumsToUpdate = [[NSMutableSet alloc] init];
            NSMutableSet *photosToDelete = [[NSMutableSet alloc] init];
            for (id anItem in sucessfullyDeletedItems)
            {
                DLog(@"Item at '%@' was recycled", anItem);
                NSString *aPhotoPath = [anItem path];
                [photosToDelete addObject:aPhotoPath];
            }
            NSArray *photosWithPaths = [[PIXFileParser sharedFileParser] fetchPhotosWithPaths:[photosToDelete allObjects]];
            for (PIXPhoto *aPhoto in photosWithPaths)
            {
                [albumsToUpdate addObject:aPhoto.album];
                [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] deleteObject:aPhoto];
            }

            for (PIXAlbum *anAlbum in albumsToUpdate)
            {
                //[anAlbum updateAlbumBecausePhotosDidChange];
                [[PIXFileParser sharedFileParser] scanPath:anAlbum.path withRecursion:PIXFileParserRecursionNone];
                [anAlbum flush];
            }

            [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] save:nil];
            
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
        if ([isDirectory boolValue] == YES) {
            DLog(@"found subdirectory at : %@", url.path);
            return NO;
        }
        
        //If a non-image file is found, do not delete
        if ([self isImageFile:url.path]==NO)
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

//-(BOOL)renameAlbumWithObjectID:(NSManagedObjectID *)anAlbumID withName:(NSString *)aNewName
//{
//    NSError *error = nil;
//    PIXAlbum *anAlbum = (PIXAlbum *)[[[PIXAppDelegate sharedAppDelegate] managedObjectContext] existingObjectWithID:anAlbumID error:&error];
//    
//    if (anAlbum==nil) {
//        NSString *errMsg = [NSString stringWithFormat:@"Unable to undo album rename operation.\n(%@)", error];
//        NSRunCriticalAlertPanel(errMsg, @"Undo Failed", @"OK", @"Cancel", nil);
//        return NO;
//    }
//    return [self renameAlbum:anAlbum withName:aNewName];
//}

-(BOOL)renameAlbumWithPath:(NSString *)anAlbumPath withName:(NSString *)aNewName
{
    NSManagedObjectContext *context = [[PIXAppDelegate sharedAppDelegate] managedObjectContext];
    PIXAlbum *anAlbum = (PIXAlbum *)[[PIXFileParser sharedFileParser] fetchAlbumWithPath:anAlbumPath inContext:context];
    
    if (anAlbum==nil) {
        NSString *errMsg = [NSString stringWithFormat:@"Unable to undo album rename operation.\n(%@)", anAlbumPath];
        NSRunAlertPanel(errMsg, @"Undo Failed", @"OK", nil, nil);
        return NO;
    }
    return [self renameAlbum:anAlbum withName:aNewName];
}

-(BOOL)renameAlbum:(PIXAlbum *)anAlbum withName:(NSString *)aNewName
{
    if ([aNewName length]==0 || [aNewName isEqualToString:anAlbum.title])
    {
        DLog(@"renaming to empty string or same name disallowed.");
        return NO;
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
        NSString *errMsg = [NSString stringWithFormat:@"\"%@\" is an invalid name for a folder.", aNewName];
        NSRunAlertPanel(@"Invalid Folder Name", errMsg, @"OK", nil, nil);
        return NO;
    }
    
    
    NSString *parentFolderPath = [anAlbum.path stringByDeletingLastPathComponent];
    NSString *oldAlbumName = [anAlbum.path lastPathComponent];
    NSString *newFilePath = [parentFolderPath stringByAppendingPathComponent:aNewName];
    if ([[NSFileManager defaultManager]
         fileExistsAtPath: newFilePath])
    {
        NSString *errMsg = [NSString stringWithFormat:@"There's already a directory with the name \"%@\" at this album's location. Please enter a new name.", aNewName];
        NSRunAlertPanel(@"Duplicate Album Name", errMsg, @"OK", nil, nil);
        return NO;
    }

    BOOL success = [[NSFileManager defaultManager] moveItemAtPath:anAlbum.path toPath:newFilePath error:&error];
    if (!success)
    {
        [[NSApplication sharedApplication] presentError:error];
        return NO;
    }
    
    [anAlbum setPath:newFilePath];
    for (PIXPhoto *aPhoto in anAlbum.photos)
    {
        NSString *photoFileName = [aPhoto.path lastPathComponent];
        NSString *newPhotoPath = [NSString stringWithFormat:@"%@/%@", anAlbum.path, photoFileName];
        aPhoto.path = newPhotoPath;
    }
    
    if (![[[PIXAppDelegate sharedAppDelegate] managedObjectContext] save:&error]) {
        DLog(@"%@", error);
        [[NSApplication sharedApplication] presentError:error];
        return NO;
    }
    NSString *oldAlbumPath = [NSString stringWithFormat:@"%@/%@", parentFolderPath, oldAlbumName];
    //[[PIXFileParser sharedFileParser] scanPath:parentFolderPath withRecursion:PIXFileParserRecursionFull];
    [[PIXFileParser sharedFileParser] scanPath:oldAlbumPath withRecursion:PIXFileParserRecursionFull];
    [[PIXFileParser sharedFileParser] scanPath:anAlbum.path withRecursion:PIXFileParserRecursionSemi];
    //[[PIXFileParser sharedFileParser] scanFullDirectory];
    
    
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
        NSString *errMsg = [NSString stringWithFormat:@"Unable to undo photo rename operation.\n(%@)", aPhotoPath];
        NSRunAlertPanel(errMsg, @"Undo Failed", @"OK", nil, nil);
        return NO;
    }
    return [self renamePhoto:aPhoto withName:aNewName];
}

-(BOOL)renamePhoto:(PIXPhoto *)aPhoto withName:(NSString *)aNewName;
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
        
        
        
        
        [alert setAlertStyle: NSWarningAlertStyle];
        
        //			alertResult = NSRunAlertPanel(
        //                                              @"Output file already exists.",
        //                                              [NSString stringWithFormat:@"\"%@\" already exists. Do you want to replace it?",
        //                                               name],
        //                                              @"Cancel All",
        //                                              @"Yes to All",
        //                                              nil
        //                                              );
        
    
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
        NSString *errMsg = [NSString stringWithFormat:@"\"%@\" is an invalid name for a file.", aNewName];
        NSRunAlertPanel(@"Invalid File Name", errMsg, @"OK", nil, nil);
        return NO;
    }
    
    
    NSString *parentFolderPath = [aPhoto.album path];
    NSString *oldPhotoName = aPhoto.name;
    NSString *newFilePath = [parentFolderPath stringByAppendingPathComponent:aNewName];
    
    if ([[NSFileManager defaultManager]
         fileExistsAtPath: newFilePath])
    {
        NSString *errMsg = [NSString stringWithFormat:@"There's already a photo with the name \"%@\" at this album's location. Please enter a new name.", aNewName];
        NSRunAlertPanel(@"Duplicate Photo Name", errMsg, @"OK", nil, nil);
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
        
        [albumPaths addObject:restorePath];
        
        DLog(@"Restored file from '%@'", recyclerPath);
    }
    
    for (NSString *albumPath in albumPaths)
    {
        [[PIXFileParser sharedFileParser] scanPath:albumPath withRecursion:PIXFileParserRecursionFull];
    }
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
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
    
    
    DLog(@"About to recycle the following items : %@", urlsToDelete);
    [[NSWorkspace sharedWorkspace] recycleURLs:urlsToDelete completionHandler:^(NSDictionary *newURLs, NSError *error) {
        //
        if (nil==error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
//                NSMutableSet *albumsToUpdate = [[NSMutableSet alloc] init];
//                
//                for (PIXPhoto *anItem in items)
//                {
//                    [albumsToUpdate addObject:[(PIXPhoto *)anItem album]];
//                    [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] deleteObject:anItem];
//                }
//                
//                for (PIXAlbum *anAlbum in albumsToUpdate)
//                {
//                    [anAlbum updateAlbumBecausePhotosDidChange];
//                    [anAlbum flush];
//                }
                
                [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] save:nil];
                
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
            
            [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] save:nil];
            
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
            return YES;
        }
    }
    return NO;
}

//TODO: background thread these operations
-(void)moveFiles:(NSArray *)items
{
    DLog(@"moving %ld files...", items.count);
    NSString *aDestinationPath = [[items lastObject] valueForKey:@"destination"];
    NSURL *destinationURL = [NSURL fileURLWithPath:aDestinationPath isDirectory:YES];
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
        
        NSString *fullDestPath = [NSString stringWithFormat:@"%@/%@", dest, filename];
        NSError *error = nil;
        if (![[NSFileManager defaultManager] moveItemAtPath:src toPath:fullDestPath error:&error])
        {
            DLog(@"%@", error);
            [[NSApplication sharedApplication] presentError:error];
        }
        
//        [[NSWorkspace sharedWorkspace]
//         performFileOperation:NSWorkspaceMoveOperation
//         source: [src stringByDeletingLastPathComponent]
//         destination:dest
//         files:[NSArray arrayWithObject:[src lastPathComponent]]
//         tag:nil];
    }
    
    //[[[PIXAppDelegate sharedAppDelegate] dataSource] startLoadingAllAlbumsAndPhotosInObservedDirectories];
    //    MainWindowController *mainWindowController = [AppDelegate mainWindowController] ;
    //    FileSystemEventController *fileSystemEventController = mainWindowController.fileSystemEventController;
    for (NSString *albumPath in albumPaths)
    {
        if (![albumPath isEqualToString:[self trashFolderPath]] && [self directoryIsSubpathOfObservedDirectories:albumPath]) {
            [[PIXFileParser sharedFileParser] scanPath:albumPath withRecursion:PIXFileParserRecursionNone];
        }
    }
    
    NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
    [undoManager registerUndoWithTarget:self selector:@selector(moveFiles:) object:undoArray];
}

//TODO: background thread these operations
-(void)copyFiles:(NSArray *)items;
{
    DLog(@"copying %ld files...", items.count);
    
    NSString *aDestinationPath = [[items lastObject] valueForKey:@"destination"];
    NSURL *destinationURL = [NSURL fileURLWithPath:aDestinationPath isDirectory:YES];
    //NSArray *srcPaths = [items valueForKey:@"source"];
//    NSMutableArray *srcFileNames = [NSMutableArray arrayWithCapacity:srcPaths.count];
//    for (NSString *srcPath in srcPaths)
//    {
//        [srcFileNames addObject:[srcPath stringByDeletingLastPathComponent]];
//    }
    NSArray *newItems = [self userValidatedFiles:items forDestination:destinationURL];
    if (newItems.count == 0) {
        return;
    } else {//if (newItems.count != items.count) {
        //Update items based on user's replace preferences
        DLog(@"\nOld destinations : %@", [items valueForKey:@"destination"]);
        DLog(@"\nNew destinations : %@", [newItems valueForKey:@"destination"]);
    }
    items = newItems;

    NSString *trashFolder = [[PIXFileManager sharedInstance] trashFolderPath];
    NSMutableArray *undoArray = [NSMutableArray arrayWithCapacity:items.count];
    NSMutableSet *albumPaths = [[NSMutableSet alloc] init];
    for (id aDict in items)
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
        
        
        //[albumPaths addObject:[src stringByDeletingLastPathComponent]];
        [albumPaths addObject:dest];
        
        NSString *undoSrc = [NSString stringWithFormat:@"%@/%@", dest, filename];
        //NSString *undoDest = [src stringByDeletingLastPathComponent];
        
        [undoArray addObject:@{@"source" : undoSrc, @"destination" : trashFolder}];
        
        
        if (!destintationWasRenamed)
        {
            [[NSWorkspace sharedWorkspace]
             performFileOperation:NSWorkspaceCopyOperation
             source: [src stringByDeletingLastPathComponent]
             destination:dest
             files:[NSArray arrayWithObject:[src lastPathComponent]]
             tag:nil];
        } else {
            NSString *fullDestPath = [NSString stringWithFormat:@"%@/%@", dest, filename];
            NSError *error = nil;
            [[NSFileManager defaultManager] copyItemAtPath:src toPath:fullDestPath error:&error];
        }
    }
    
    for (NSString *albumPath in albumPaths)
    {
        if (![albumPath isEqualToString:trashFolder] && [self directoryIsSubpathOfObservedDirectories:albumPath]) {
            [[PIXFileParser sharedFileParser] scanPath:albumPath withRecursion:PIXFileParserRecursionNone];
        }
    }
    
    NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
    [undoManager registerUndoWithTarget:self selector:@selector(moveFiles:) object:undoArray];
}





//----------------------------------------------------------------------------------------
#pragma mark	-
#pragma mark	Helpers

//- (BOOL)checkOutputPath:(NSString *)finalOutputPath
//{
//	if ([[NSFileManager defaultManager] fileExistsAtPath:[self finalOutputPath]]) {
//		
//		// Overwrite existing file
//		if (overwriteStrategy == UCExistingOverwrite)
//			return YES;
//		
//		// Find sequentually numbered unused name
//		else if (overwriteStrategy == UCExistingNumberSequentially) {
//			
//			pathNumbering = 0;
//			NSString *newPath;
//			
//			do {
//				pathNumbering++;
//				newPath = [self finalOutputPath];
//			} while ([[NSFileManager defaultManager] fileExistsAtPath:newPath]);
//            
//            // Open choose dialog
////		} else if (overwriteStrategy == UCExistingChooseNew) {
////			
////			return [self chooseNewOutputPath];
////            
////            // Display an error
//		} else if (overwriteStrategy == UCExistingError) {
//			
//			NSInteger reply = NSRunAlertPanel(
//                                              @"Output file already exists.",
//                                              [NSString stringWithFormat:@"\"%@\" already exists. Do you want to replace it?",
//                                               [outputPath lastPathComponent]],
//                                              @"Abort",
//                                              @"Replace",
//                                              nil
//                                              );
//			
//			if (reply == NSAlertDefaultReturn)
//				return NO;
//		}
//	}
//	[self updateOutputPath];
//	return YES;
//}

- (NSString*)finalOutputPath:(NSString *)outputPath
{
	if (pathNumbering > 0) {
		
		NSString *basePath = [outputPath stringByDeletingPathExtension];
		NSString *extension = [outputPath pathExtension];
		return [NSString stringWithFormat:@"%@ %u.%@", basePath, pathNumbering, extension];
        
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
//		if (yesToAll)
//		{
//			[validatedFiles addObject: item];
//            
//			continue;
//		}
        
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
                    [alert setInformativeText:[NSString stringWithFormat:@"An item named \"%@\" and %ld others already exist in this location. Do you want to replace them with the ones you’re moving?", name, dupeCount-1]];
                } else {
                    [alert addButtonWithTitle: @"Keep Both"];
                    [alert addButtonWithTitle: @"Cancel"];
                    [alert addButtonWithTitle: @"Skip"];
                    
                    [alert setMessageText: [NSString stringWithFormat: @"An item named \"%@\" ", name]];
                    [alert setInformativeText:@"already exists in this location. Do you want to replace it with the one you’re moving?"];
                }
                
                [alert setAlertStyle: NSWarningAlertStyle];
                
                //			alertResult = NSRunAlertPanel(
                //                                              @"Output file already exists.",
                //                                              [NSString stringWithFormat:@"\"%@\" already exists. Do you want to replace it?",
                //                                               name],
                //                                              @"Cancel All",
                //                                              @"Yes to All",
                //                                              nil
                //                                              );
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
        isImageFile = UTTypeConformsTo((__bridge CFStringRef)utiValue, kUTTypeImage);
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
        if (([[path stringByDeletingLastPathComponent] isEqualToString:destPath] == NO) &&
        ([self isImageFile:path]==YES) && ([path isEqualToString:destPath]==NO))
        {
            [pathsToPaste addObject:@{@"source" : path, @"destination" : destPath}];
        }
    }
    return pathsToPaste;
}


NSString * UserHomeDirectory();

-(NSString *)trashFolderPath;
{
    NSString *trashFolderPathString = [NSString stringWithFormat:@"%@/.Trash", UserHomeDirectory()];
    return trashFolderPathString;
}

-(NSString *)defaultPhotosPath
{
    NSArray *observedDirectories = [[[PIXFileParser sharedFileParser] observedDirectories] valueForKey:@"path"];
    for (NSString *observedPath in observedDirectories)
    {
        if ([[observedPath lastPathComponent] isEqualToString:@"Photos"]==YES) {
            return observedPath;
        }
    }
    if (observedDirectories.count>0) {
        return [observedDirectories objectAtIndex:0];
    }
    //TODO: present an error here?
    return [observedDirectories lastObject];
}

-(PIXAlbum *)createAlbumWithName:(NSString *)aName;
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
    
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
