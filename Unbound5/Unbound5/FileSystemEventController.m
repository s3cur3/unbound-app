//
//  FileSystemEventController.m
//  Unbound5
//
//  Created by Bob on 10/17/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "FileSystemEventController.h" 
#import "Album.h"

@implementation FileSystemEventController

-(id)initWithPath:(NSURL *)aFilePathURL
{
    self = [super init];
    if (self)
    {
        self.rootFilePathURL = aFilePathURL;
        self.albumLookupTable = [NSMutableDictionary dictionaryWithCapacity:100];
    }
    return self;
}

-(id)initWithPath:(NSURL *)aFilePathURL
      albumsTable:(NSDictionary *)anAlbumsDict;
{
    self = [super init];
    if (self)
    {
        self.rootFilePathURL = aFilePathURL;
        self.albumLookupTable = anAlbumsDict;
    }
    return self;
}

-(void)fetchAllAlbums
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^(void){
        //walk files in the background thread
        //Get all the subdirectories
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:self.rootFilePathURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLLocalizedNameKey, NSURLEffectiveIconKey, NSURLIsDirectoryKey, NSURLTypeIdentifierKey, nil] options:NSDirectoryEnumerationSkipsHiddenFiles /*| NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants*/ errorHandler:^(NSURL *url, NSError *error) {
            // Handle the error.
            DLog(@"error creating enumerator for directory %@ : %@", url.path, error);
            // Return YES if the enumeration should continue after the error.
            return YES;
        }];
        
        
        self.albums = [NSMutableArray arrayWithCapacity:100];
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
    [self.rootFilePathURL addDirectoryObserver:self options:0 resumeToken:nil];
}

-(void)stopObserving
{
    [self.rootFilePathURL removeDirectoryObserver:self];
}

- (void)observedDirectory:(NSURL*)observedURL childrenAtURLDidChange:(NSURL*)changedURL historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken {
    NSLog(@"Files in %@ have changed!", changedURL.path);
    Album *changedAlbum = [self.albumLookupTable valueForKey:changedURL.path];
    //NSAssert(changedAlbum!=nil, @"Received a notification for album that doesn't exist");
    if (changedAlbum==nil)
    {
        Album *anAlbum = [[Album alloc] initWithFilePath:changedURL.path];
        [anAlbum updatePhotosFromFileSystem];
        if (anAlbum.photos.count!=0)
        {
            [self.albumLookupTable setValue:anAlbum forKey:changedURL.path];
            [self.albums addObject:anAlbum];
            
            NSDictionary *aDict = [NSDictionary dictionaryWithObject:self.albums forKey:@"albums"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AlbumsUpdatedLoading" object:self userInfo:aDict];

        }
    } else {
        [changedAlbum updatePhotosFromFileSystem];
    }
}

- (void)observedDirectory:(NSURL*)observedURL descendantsAtURLDidChange:(NSURL*)changedURL reason:(ArchDirectoryObserverDescendantReason)reason historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken {
    NSLog(@"Descendents below %@ have changed! Reason : %d", changedURL.path, reason);
}

- (void)observedDirectory:(NSURL*)observedURL ancestorAtURLDidChange:(NSURL*)changedURL historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken {
    NSLog(@"%@, ancestor of your directory, has changed!", changedURL.path);
}

-(void)dealloc
{
    //[self stopObserving];
}

@end
