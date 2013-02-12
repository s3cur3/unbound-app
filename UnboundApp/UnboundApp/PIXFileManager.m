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
#import "Album.h"
#import "PIXFileSystemDataSource.h"
#import <CoreFoundation/CoreFoundation.h>

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
    [[NSWorkspace sharedWorkspace] openFile:filePath withApplication:appPath];
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
    NSString *filePath = [pathsDict valueForKey:@"filePath"];
    if (!appPath) {
        NSLog(@"Could get app path from nsmenuitem represented object");
        return;
    }
    [self openFileWithPath:filePath withApplication:appPath];
    //[self openSelectedFileWithApplication:appPath];
}

- (void)openWithApplicationOtherSelected:(id)sender
{
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
    if (code == NSOKButton)
    {
		[panel close];
        [self openSelectedFileWithApplication:[panel filename]];
    }
}

/// construct menu item for app
- (NSMenuItem *)menuItemForOpenWithForApplication:(NSString *)appName appPath:(NSString *)appPath filePath:(NSString *)filePath
{
    NSMenuItem *newAppItem = [[NSMenuItem alloc] init];
    [newAppItem setTitle:appName];
    [newAppItem setTarget:self];
    [newAppItem setAction:@selector(openWithApplicationSelected:)];
    NSDictionary *pathsDict = @{@"appPath" : appPath, @"filePath": filePath};
    [newAppItem setRepresentedObject:pathsDict];
    //[newAppItem setRepresentedObject:appPath];
    [newAppItem setImage:[[NSWorkspace sharedWorkspace] iconForFile:appPath]];
    return newAppItem;
}

/// this method return open with menu for specified file
- (NSMenu *)openWithMenuItemForFile:(NSString *)filePath
{
    NSMenu *subMenu = [[NSMenu alloc] init];
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
            NSMenuItem *newAppItem = [self menuItemForOpenWithForApplication:defaultAppName appPath:defaultAppPath filePath:filePath];
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
                        NSMenuItem *newAppItem = [self menuItemForOpenWithForApplication:appName appPath:[appURL path] filePath:filePath];
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
        [subMenu addItem:otherAppItem];
        
        CFRelease(cfArrayOfApps);
    }
    return subMenu;
}

-(void)moveFiles:(NSArray *)items
{
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
    //    for (NSString *aPath in albumPaths)
    //    {
    //        PIXAlbum *anAlbum = [[fileSystemEventController albumLookupTable] valueForKey:aPath];
    //        if (anAlbum!=nil) {
    //            [anAlbum updatePhotosFromFileSystem];
    //        }
    //    }
    
    NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
    [undoManager registerUndoWithTarget:self selector:@selector(moveFiles:) object:undoArray];
}
-(void)copyFiles:(NSArray *)items;
{
    NSString *trashFolder = @"~/.Trash";//[[PIXAppDelegate sharedAppDelegate] trashFolderPath];
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
    
    [[[PIXAppDelegate sharedAppDelegate] dataSource] startLoadingAllAlbumsAndPhotosInObservedDirectories];
//    MainWindowController *mainWindowController = [AppDelegate mainWindowController] ;
//    FileSystemEventController *fileSystemEventController = mainWindowController.fileSystemEventController;
//    for (NSString *aPath in albumPaths)
//    {
//        PIXAlbum *anAlbum = [[fileSystemEventController albumLookupTable] valueForKey:aPath];
//        if (anAlbum!=nil) {
//            [anAlbum updatePhotosFromFileSystem];
//        }
//    }
    
    NSUndoManager *undoManager = [[PIXAppDelegate sharedAppDelegate] undoManager];
    [undoManager registerUndoWithTarget:self selector:@selector(moveFiles:) object:undoArray];
}

@end
