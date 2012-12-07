//
//  PIFileManager.m
//  Unbound
//
//  Created by Bob on 12/6/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIFileManager.h"
#import "AppDelegate.h"
#import "MainWindowController.h"
#import "FileSystemEventController.h"
#import "Album.h"

@implementation PIFileManager


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
    
    MainWindowController *mainWindowController = [AppDelegate mainWindowController] ;
    FileSystemEventController *fileSystemEventController = mainWindowController.fileSystemEventController;
    for (NSString *aPath in albumPaths)
    {
        Album *anAlbum = [[fileSystemEventController albumLookupTable] valueForKey:aPath];
        if (anAlbum!=nil) {
            [anAlbum updatePhotosFromFileSystem];
        }
    }
    
    //[self.album updatePhotosFromFileSystem];
    //self.browserData = nil;
    //[self.browserView reloadData];
    
    NSUndoManager *undoManager = [[AppDelegate applicationDelegate] undoManager];
    [undoManager registerUndoWithTarget:self selector:@selector(moveFiles:) object:undoArray];
    
}

@end
