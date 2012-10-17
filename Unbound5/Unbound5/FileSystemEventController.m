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
    NSAssert(changedAlbum!=nil, @"Received a notification for album that doesn't exist");
    [changedAlbum updatePhotosFromFileSystem];
}

- (void)observedDirectory:(NSURL*)observedURL descendantsAtURLDidChange:(NSURL*)changedURL reason:(ArchDirectoryObserverDescendantReason)reason historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken {
    NSLog(@"Descendents below %@ have changed!", changedURL.path);
}

- (void)observedDirectory:(NSURL*)observedURL ancestorAtURLDidChange:(NSURL*)changedURL historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken {
    NSLog(@"%@, ancestor of your directory, has changed!", changedURL.path);
}

-(void)dealloc
{
    [self stopObserving];
}

@end
