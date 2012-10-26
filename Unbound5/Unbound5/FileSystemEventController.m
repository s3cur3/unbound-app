//
//  FileSystemEventController.m
//  Unbound5
//
//  Created by Bob on 10/17/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "FileSystemEventController.h" 
#import "Album.h"
#import "MainWindowController.h"

/*NSString *searchLocationKey  = @"searchLocationKey";
NSString *dropboxHomeLocationKey  = @"dropboxHomeLocationKey";
NSString *dropboxHomeStringKey = @"dropboxHomeStringKey";*/

@implementation FileSystemEventController



-(id)initWithPath:(NSURL *)aFilePathURL
      dropboxHome:(NSURL *)dropboxURL
{
    self = [super init];
    if (self)
    {
        self.rootFilePathURL = aFilePathURL;
        self.dropboxHome = dropboxURL;
        self.albumLookupTable = [NSMutableDictionary dictionaryWithCapacity:100];
    }
    return self;
}

-(id)initWithPath:(NSURL *)aFilePathURL
      albumsTable:(NSMutableDictionary *)anAlbumsDict;
{
    self = [super init];
    if (self)
    {
        self.rootFilePathURL = aFilePathURL;
        self.albumLookupTable = anAlbumsDict;
    }
    return self;
}

-(NSArray *) observedDirectories;
{
    if ([self.rootFilePathURL.path isEqualToString:self.dropboxHome.path])
    {
        return [NSArray arrayWithObject:self.dropboxHome];
    } else {
        NSString *dropboxHomePath = [[NSUserDefaults standardUserDefaults] valueForKey:dropboxHomeStringKey];
        NSString *aPath = [NSString stringWithFormat:@"%@/Camera Uploads", dropboxHomePath];
        self.cameraUploadsLocation = [NSURL fileURLWithPath:aPath];
        return [NSArray arrayWithObjects:self.rootFilePathURL, self.cameraUploadsLocation, nil];
        //return [NSArray arrayWithObjects:self.rootFilePathURL, nil];
    }
}

-(void)updateAlbumsForURL:(NSURL *)url
{
    NSError *error;
    NSNumber *isDirectory = nil;
    if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
        // handle error
        DLog(@"error on getResourceValue for file %@ : %@", url.path, error);
    }
    else if ([isDirectory boolValue]) {
        Album *anAlbum = [self.albumLookupTable valueForKey:url.path];
        if (!anAlbum)
        {
            anAlbum = [[Album alloc] initWithFilePath:url.path];
            [anAlbum updatePhotosFromFileSystem];
            if (anAlbum.photos.count!=0)
            {
                [self.albumLookupTable setValue:anAlbum forKey:url.path];
                [self.albums addObject:anAlbum];
                dispatch_async(dispatch_get_main_queue(),^(void){
                    NSDictionary *aDict = [NSDictionary dictionaryWithObject:self.albums forKey:@"albums"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"AlbumsUpdatedLoading" object:self userInfo:aDict];
                });
            }
        }
        //anAlbum.dateLastScanned = scanDate;
    }
}

//TODO: add recursive flag
-(void)updateAlbumsAtPath:(NSURL *)filePath
              scanSubdirs:(BOOL)shouldScanSubDirs
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^(void){
        
        //NSDate *scanDate = [NSDate date];
        if (self.albums == nil) {
            self.albums = [NSMutableArray arrayWithCapacity:100];
        }
        
        [self updateAlbumsForURL:filePath];
        
        NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles;
        if (!shouldScanSubDirs) {
            options = options | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants;
        }
        
        //walk files in the background thread
        //Get all the subdirectories
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:filePath includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLLocalizedNameKey, NSURLEffectiveIconKey, NSURLIsDirectoryKey, NSURLTypeIdentifierKey, nil] options:options errorHandler:^(NSURL *url, NSError *error) {
            // Handle the error.
            DLog(@"error creating enumerator for directory %@ : %@", url.path, error);
            // Return YES if the enumeration should continue after the error.
            return YES;
        }];
        
        
        //self.albums = [NSMutableArray arrayWithCapacity:100];
        //int index = 0;
        for (NSURL *url in enumerator) {
            [self updateAlbumsForURL:url];
        }
        
        //[albums makeObjectsPerformSelector:@selector(updatePhotosFromFileSystem)];
        //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"photos != nil"];
        //[albums filterUsingPredicate:predicate];
        
        dispatch_async(dispatch_get_main_queue(),^(void){
            NSDictionary *aDict = [NSDictionary dictionaryWithObject:self.albums forKey:@"albums"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AlbumsUpdatedLoading" object:self userInfo:aDict];
        });
    });
    
    
    
    return;
}

-(void)fetchAllAlbums
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^(void){
        
        self.albums = [NSMutableArray arrayWithCapacity:100];
        
        //Check top level for any photos before checking subdirectories
        [self updateAlbumsForURL:self.rootFilePathURL];
        
        //walk files in the background thread
        //Get all the subdirectories
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:self.rootFilePathURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLLocalizedNameKey, NSURLEffectiveIconKey, NSURLIsDirectoryKey, NSURLTypeIdentifierKey, nil] options:NSDirectoryEnumerationSkipsHiddenFiles /*| NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants*/ errorHandler:^(NSURL *url, NSError *error) {
            // Handle the error.
            DLog(@"error creating enumerator for directory %@ : %@", url.path, error);
            // Return YES if the enumeration should continue after the error.
            return YES;
        }];
        
        
        
        //int index = 0;
        for (NSURL *url in enumerator) {
            NSError *error;
            NSNumber *isDirectory = nil;
            if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
                // handle error
                DLog(@"error on getResourceValue for file %@ : %@", url.path, error);
            }
            else if ([isDirectory boolValue]) {
                Album *anAlbum = [[Album alloc] initWithFilePath:url.path];
                [anAlbum updatePhotosFromFileSystem];
                if (anAlbum.photos.count!=0)
                {
                    [self.albumLookupTable setValue:anAlbum forKey:url.path];
                    [self.albums addObject:anAlbum];
                    dispatch_async(dispatch_get_main_queue(),^(void){
                        NSDictionary *aDict = [NSDictionary dictionaryWithObject:self.albums forKey:@"albums"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"AlbumsUpdatedLoading" object:self userInfo:aDict];
                    });
                }
                
            }
        }
        
        //[albums makeObjectsPerformSelector:@selector(updatePhotosFromFileSystem)];
        //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"photos != nil"];
        //[albums filterUsingPredicate:predicate];
        
        dispatch_async(dispatch_get_main_queue(),^(void){
            NSDictionary *aDict = [NSDictionary dictionaryWithObject:self.albums forKey:@"albums"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AlbumsFinishedLoading" object:self userInfo:aDict];
        });
    });
    

    
    return;
}



-(void)startObserving
{
    for (NSURL *aDir in [self observedDirectories])
    {
        [aDir addDirectoryObserver:self options:0 resumeToken:nil];
    }
    //[self.rootFilePathURL addDirectoryObserver:self options:0 resumeToken:nil];
}

-(void)stopObserving
{
    for (NSURL *aDir in [self observedDirectories])
    {
        [aDir removeDirectoryObserver:self];
    }
    //[self.rootFilePathURL removeDirectoryObserver:self];
}



-(void)checkForNewOrDeletedAlbumsInPath:(NSString *)aPath
{
    NSDictionary *albumLookupTmp = [self.albumLookupTable copy];
    NSEnumerator *enumerator = [albumLookupTmp keyEnumerator];
    NSString *aKey;
    NSMutableArray *removedAlbums = [NSMutableArray array];
    while(aKey = [enumerator nextObject])
    {
        if ([aKey hasPrefix:aPath])
        {
            Album *anAlbum = [albumLookupTmp valueForKey:aKey];
            if ([[NSFileManager defaultManager] fileExistsAtPath:aKey])
            {
                [anAlbum updatePhotosFromFileSystem];
            } else {
                [self.albums removeObject:anAlbum];
                [removedAlbums addObject:aKey];
                
            }
        }
    }
    if (removedAlbums.count || YES)
    {
        [self.albumLookupTable removeObjectsForKeys:removedAlbums];
        NSDictionary *userDict = [NSDictionary dictionaryWithObject:removedAlbums forKey:@"Albums"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AlbumsWereDeleted" object:self userInfo:userDict];
    }

}

// At least one file in the directory indicated by changedURL has changed.  You should examine the directory at changedURL to see which files changed.
// observedURL: the URL of the dorectory you're observing.
// changedURL: the URL of the actual directory that changed. This could be a subdirectory.
// historical: if YES, the event occured sometime before the observer was added.  If NO, it occurred just now.
// resumeToken: the resume token to save if you want to pick back up from this event.
- (void)observedDirectory:(NSURL*)observedURL childrenAtURLDidChange:(NSURL*)changedURL historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken {
    
    if (historical) {
        DLog(@"Files in %@ have changed, but the changes are historical - ignoring", changedURL.path);
        return;
    }
    
    NSLog(@"Files in %@ have changed!", changedURL.path);
    
    //return;
    
    Album *changedAlbum = [self.albumLookupTable valueForKey:changedURL.path];
    //NSAssert(changedAlbum!=nil, @"Received a notification for album that doesn't exist");
    
    DLog(@"Received notification for an album that doesn't exist - creating : %@", changedURL.path);
    if (changedAlbum==nil)
    {
        Album *anAlbum = [[Album alloc] initWithFilePath:changedURL.path];
        if ([anAlbum albumExistsWithPhotos]==YES)
        {
            [anAlbum updatePhotosFromFileSystem];
            if (anAlbum.photos.count!=0)
            {
                [self.albumLookupTable setValue:anAlbum forKey:changedURL.path];
                [self.albums addObject:anAlbum];
                
                NSDictionary *aDict = [NSDictionary dictionaryWithObject:self.albums forKey:@"albums"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AlbumsUpdatedLoading" object:self userInfo:aDict];
            }
        }
        

    } else {
        [changedAlbum updatePhotosFromFileSystem];
        
    }
    [self checkForNewOrDeletedAlbumsInPath:changedURL.path];
    [self updateAlbumsAtPath:changedURL scanSubdirs:NO];
}

// At least one file somewhere inside--but not necessarily directly descended from--changedURL has changed.  You should examine the directory at changedURL and all subdirectories to see which files changed.
// observedURL: the URL of the dorectory you're observing.
// changedURL: the URL of the actual directory that changed. This could be a subdirectory.
// reason: the reason the observation center can't pinpoint the changed directory.  You may want to ignore some reasons--for example, "ArchDirectoryObserverNoHistoryReason" simply means that you didn't pass a resume token when adding the observer, and so you should do an initial scan of the directory.
// historical: if YES, the event occured sometime before the observer was added.  If NO, it occurred just now.
// resumeToken: the resume token to save if you want to pick back up from this event.
- (void)observedDirectory:(NSURL*)observedURL descendantsAtURLDidChange:(NSURL*)changedURL reason:(ArchDirectoryObserverDescendantReason)reason historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken {
    NSLog(@"Descendents below %@ have changed! Reason : %d", changedURL.path, reason);
    
    //If this is the first notication, rebuild all albums from directory structure
    if (reason == ArchDirectoryObserverNoHistoryReason)
    {
        [self updateAlbumsAtPath:changedURL scanSubdirs:YES];
        /*if(![changedURL.path hasSuffix:@"Uploads"])
        {
            [self fetchAllAlbums];
        } else {
            [self updateAlbumsAtPath:changedURL scanSubdirs:YES];
        }*/
        //[self updateAlbumsAtPath:changedURL];
    }
}

// An ancestor of the observedURL has changed, so the entire directory tree you're observing may have vanished. You should ensure it still exists.
// observedURL: the URL of the dorectory you're observing.
// changedURL: the URL of the actual directory that changed. For this call, it will presumably be an ancestor directory.
// historical: if YES, the event occured sometime before the observer was added.  If NO, it occurred just now.
// resumeToken: the resume token to save if you want to pick back up from this event.
- (void)observedDirectory:(NSURL*)observedURL ancestorAtURLDidChange:(NSURL*)changedURL historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken {
    NSLog(@"%@, ancestor of your directory, has changed!", changedURL.path);
}

-(void)dealloc
{
    //[self stopObserving];
}

@end
