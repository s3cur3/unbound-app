//
//  PIXFileManager.m
//  UnboundApp
//
//  Created by Bob on 1/31/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXFileManager.h"
#import "PIXAppDelegate.h"
#import "PIXAppDelegate+CoreDataUtils.h"
//#import "MainWindowController.h"
//#import "FileSystemEventController.h"
//#import "Album.h"
#import "PIXAlbum.h"
#import "PIXPhoto.h"
#import "PIXFileSystemDataSource.h"
#import <CoreFoundation/CoreFoundation.h>
#import "PIXDefines.h"

@interface PIXFileManager()

@property (nonatomic, strong) NSArray *selectedFilePaths;

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
    
    [panel beginSheetForDirectory:@"/Applications"
                             file:nil
                            types:nil
                   modalForWindow:[[PIXAppDelegate sharedAppDelegate] window]
                    modalDelegate:self
                   didEndSelector:@selector(chooseAppSheetClosed:returnCode:contextInfo:)
                      contextInfo:nil];
}

- (void)chooseAppSheetClosed:(NSOpenPanel *)panel returnCode:(int)code contextInfo:(NSNumber *)useOptions
{
    NSArray *someFilePaths = [self.selectedFilePaths copy];
    self.selectedFilePaths = nil;
    if (code == NSOKButton)
    {
		[panel close];
        
        [self openFileWithPaths:someFilePaths withApplication:[panel filename]];
        //[self openSelectedFileWithApplication:[panel filename]];
    }
}

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
    CFIndex maxCount = 10;
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
        [[PIXFileSystemDataSource sharedInstance] shallowScanURL:[NSURL fileURLWithPath:albumPath isDirectory:YES]];
    }
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
    NSUndoManager *undoManager = [[[PIXAppDelegate sharedAppDelegate] window] undoManager];
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
                
                [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] save:nil];
                
                for (PIXAlbum *anAlbum in albumsToUpdate)
                {
                    [anAlbum updateAlbumBecausePhotosDidChange];
                    [anAlbum flush];
                }
                
                [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] save:nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
                
                NSUndoManager *undoManager = [[[PIXAppDelegate sharedAppDelegate] window] undoManager];

                [undoManager registerUndoWithTarget:[PIXFileManager sharedInstance] selector:@selector(undoRecyclePhotos:) object:newURLs];
                [undoManager setActionIsDiscardable:YES];
            });



        } else {
            [[NSApplication sharedApplication] presentError:error];
            NSArray *sucessfullyDeletedItems = [newURLs allKeys];
            //TODO: handle this error properly
            for (id anItem in sucessfullyDeletedItems)
            {
                DLog(@"Item at '%@' was recycled", anItem);
            }
        }
        
    }];
    
    DLog(@"Completed file deletion");
}

-(BOOL)directoryIsSubpathOfObservedDirectories:(NSString *)aDirectoryPath
{
    NSArray *observedDirectories = [[[PIXFileSystemDataSource sharedInstance] observedDirectories] valueForKey:@"path"];
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
    NSMutableArray *undoArray = [NSMutableArray arrayWithCapacity:items.count];
    NSMutableSet *albumPaths = [[NSMutableSet alloc] init];
    for (id aDict in items)
    {
        NSString *src = [aDict valueForKey:@"source"];
        NSString *dest = [aDict valueForKey:@"destination"];
        
        [albumPaths addObject:[src stringByDeletingLastPathComponent]];
        [albumPaths addObject:dest];
        
        NSString *undoSrc = [NSString stringWithFormat:@"%@/%@", dest, [src lastPathComponent]];
        NSString *undoDest = [src stringByDeletingLastPathComponent];
        
        [undoArray addObject:@{@"source" : undoSrc, @"destination" : undoDest}];
        
        [[NSWorkspace sharedWorkspace]
         performFileOperation:NSWorkspaceMoveOperation
         source: [src stringByDeletingLastPathComponent]
         destination:dest
         files:[NSArray arrayWithObject:[src lastPathComponent]]
         tag:nil];
    }
    
    //[[[PIXAppDelegate sharedAppDelegate] dataSource] startLoadingAllAlbumsAndPhotosInObservedDirectories];
    //    MainWindowController *mainWindowController = [AppDelegate mainWindowController] ;
    //    FileSystemEventController *fileSystemEventController = mainWindowController.fileSystemEventController;
    for (NSString *albumPath in albumPaths)
    {
        if (![albumPath isEqualToString:[self trashFolderPath]] && [self directoryIsSubpathOfObservedDirectories:albumPath]) {
            [[PIXFileSystemDataSource sharedInstance] shallowScanURL:[NSURL fileURLWithPath:albumPath isDirectory:YES]];
        }
    }
    
    NSUndoManager *undoManager = [[[PIXAppDelegate sharedAppDelegate] window] undoManager];
    [undoManager registerUndoWithTarget:self selector:@selector(moveFiles:) object:undoArray];
}

//TODO: background thread these operations
-(void)copyFiles:(NSArray *)items;
{
    DLog(@"copying %ld files...", items.count);
    NSString *trashFolder = [[PIXFileManager sharedInstance] trashFolderPath];
    NSMutableArray *undoArray = [NSMutableArray arrayWithCapacity:items.count];
    NSMutableSet *albumPaths = [[NSMutableSet alloc] init];
    for (id aDict in items)
    {
        NSString *src = [aDict valueForKey:@"source"];
        NSString *dest = [aDict valueForKey:@"destination"];
        
        //[albumPaths addObject:[src stringByDeletingLastPathComponent]];
        [albumPaths addObject:dest];
        
        NSString *undoSrc = [NSString stringWithFormat:@"%@/%@", dest, [src lastPathComponent]];
        //NSString *undoDest = [src stringByDeletingLastPathComponent];
        
        [undoArray addObject:@{@"source" : undoSrc, @"destination" : trashFolder}];
        
        [[NSWorkspace sharedWorkspace]
         performFileOperation:NSWorkspaceCopyOperation
         source: [src stringByDeletingLastPathComponent]
         destination:dest
         files:[NSArray arrayWithObject:[src lastPathComponent]]
         tag:nil];
    }
    
    for (NSString *albumPath in albumPaths)
    {
        if (![albumPath isEqualToString:trashFolder] && [self directoryIsSubpathOfObservedDirectories:albumPath]) {
            [[PIXFileSystemDataSource sharedInstance] shallowScanURL:[NSURL fileURLWithPath:albumPath isDirectory:YES]];
        }
    }
    
    NSUndoManager *undoManager = [[[PIXAppDelegate sharedAppDelegate] window] undoManager];
    [undoManager registerUndoWithTarget:self selector:@selector(moveFiles:) object:undoArray];
}

NSString * UserHomeDirectory();

-(NSString *)trashFolderPath;
{
    NSString *trashFolderPathString = [NSString stringWithFormat:@"%@/.Trash", UserHomeDirectory()];
    return trashFolderPathString;
}

@end
