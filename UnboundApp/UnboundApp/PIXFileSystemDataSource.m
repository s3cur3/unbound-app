//
//  PIXFileSystemDataSource.m
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#include <sys/types.h>
#include <pwd.h>

#import "PIXFileSystemDataSource.h"
#import "Album.h"
#import "PIXDefines.h"

#define ONLY_LOAD_ALBUMS_WITH_IMAGES 1

extern NSString *kUB_ALBUMS_LOADED_FROM_FILESYSTEM;

/*
 * Used to get the home directory of the user, UNIX/C based workaround for sandbox issues
 */
NSString * UserHomeDirectory()
{
    const struct passwd * passwd = getpwnam([NSUserName() UTF8String]);
    if(!passwd)
        return nil; // bail out cowardly
    const char *homeDir_c = getpwnam([NSUserName() UTF8String])->pw_dir;
    NSString *homeDir = [[NSFileManager defaultManager]
                         stringWithFileSystemRepresentation:homeDir_c
                         length:strlen(homeDir_c)];
    return homeDir;
}

NSString * DefaultDropBoxDirectory()
{
    NSString *dropBoxHome =[UserHomeDirectory() stringByAppendingPathComponent:@"Dropbox/"];
    return dropBoxHome;
}

NSString * DefaultDropBoxPhotosDirectory()
{
    NSString *dropBoxPhotosHome =[DefaultDropBoxDirectory() stringByAppendingPathComponent:@"Photos/"];
    return dropBoxPhotosHome;
}

@implementation PIXFileSystemDataSource

@synthesize albumLookupTable = _albumLookupTable;

+ (PIXFileSystemDataSource *)sharedInstance
{
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

-(id)init
{
    self=[super init];
    if (self)
    {
        if (self.rootFilePath == nil) {
            self.rootFilePath = DefaultDropBoxPhotosDirectory();
            [self loadAllAlbums];
        }
    }
    return self;
}

-(NSArray *)executeFetchRequest:(NSFetchRequest *)fetchRequest
{
    return nil;
}

-(NSDictionary *)albumLookupTable
{
    if (_albumLookupTable==nil) {
        return [NSDictionary dictionary];
    }
    return _albumLookupTable;
}

-(void)setAlbumLookupTable:(NSDictionary *)albumLookupTable
{
    _albumLookupTable = albumLookupTable;
    [self.albums removeAllObjects];
    [self.albums addObjectsFromArray:[albumLookupTable allValues]];
    [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];

}

//TODO: deleteEntity

//TODO: manage .unbound files



-(NSMutableArray *)albums
{
    if (_albums == nil)
    {
        _albums = [[self.albumLookupTable allValues] mutableCopy];
    }
    return _albums;
}

-(void)loadAllAlbums
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^(void){
        
        //NSDictionary *albumsDict = [self albumsDictForURL:[self rootFilePathURL]];
        NSMutableDictionary *tmpAlbumLookupTable = [NSMutableDictionary dictionary];
        for (NSURL *aURL in [self observedDirectories])
        {
            NSDictionary *observedDirectoryDict = [self albumsDictForURL:aURL];
            [tmpAlbumLookupTable addEntriesFromDictionary:observedDirectoryDict];
        }
        
        dispatch_async(dispatch_get_main_queue(),^(void){
            
            self.albumLookupTable = tmpAlbumLookupTable;
            [self startObserving];
        });
    });
}

// -------------------------------------------------------------------------------
//  isImageFile:filePath
//
//  Uses LaunchServices and UTIs to detect if a given file path is an image file.
// -------------------------------------------------------------------------------
- (BOOL)fileIsImageFile:(NSURL *)url
{
    BOOL isImageFile = NO;
    
    NSString *utiValue;
    [url getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:nil];
    if (utiValue)
    {
        isImageFile = UTTypeConformsTo((__bridge CFStringRef)utiValue, kUTTypeImage);
    }
    return isImageFile;
}

- (BOOL)fileIsUnboundMetadataFile:(NSURL *)url
{
#if ONLY_LOAD_ALBUMS_WITH_IMAGES
    return NO;
#endif
    
    BOOL isUnboundMetadataFile = NO;
    if ([url.path.lastPathComponent isEqualToString:kUnboundAlbumMetadataFileName])
    {
        isUnboundMetadataFile = YES;
    }
    return isUnboundMetadataFile;
    
    //Not using getResourceValue as it can be synchronous
    /*NSString *utiValue;
    [url getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:nil];
    if (utiValue)
    {
        isUnboundMetadataFile = [utiValue isEqualToString:kUnboundAlbumMetadataFileName];
    }*/
    
}

//-------------------------------------------------------
// Check if the directory has image files
// or an existing .unbound file
//-------------------------------------------------------
-(BOOL)directoryIsPhotoAlbum:(NSURL *)aDirectoryURL
{
    
    NSArray *propKeys = [NSArray arrayWithObjects:NSURLLocalizedNameKey, NSURLTypeIdentifierKey, NSURLIsDirectoryKey, nil];
    NSError *error = nil;
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:aDirectoryURL
                                                               includingPropertiesForKeys:propKeys
                                                                                  options:NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                                    error:&error];
    
    if(directoryContents == nil) {
        [[NSApplication sharedApplication] presentError:error];
        return NO;
    }
    
    __block BOOL isDirectoryPhotoAlbum = NO;
    [directoryContents enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

        if ([self fileIsUnboundMetadataFile:(NSURL *)obj] || [self fileIsImageFile:(NSURL *)obj]==YES)
        {
            isDirectoryPhotoAlbum = YES;
            *stop = YES;
        }
    }];
    
    return isDirectoryPhotoAlbum;
}

-(NSDictionary *)albumsDictForURL:(NSURL *)aURL
{
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:aURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLLocalizedNameKey, NSURLEffectiveIconKey, NSURLIsDirectoryKey, NSURLTypeIdentifierKey, nil] options:NSDirectoryEnumerationSkipsHiddenFiles /*| NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants*/ errorHandler:^(NSURL *url, NSError *error) {
        // Handle the error.
        DLog(@"error creating enumerator for directory %@ : %@", url.path, error);
        [[NSApplication sharedApplication] presentError:error];
        // Return YES if the enumeration should continue after the error.
        return YES;
    }];
    
    NSMutableDictionary *newAlbumsDict = [NSMutableDictionary dictionary];
    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            DLog(@"error on getResourceValue for file %@ : %@", url.path, error);
            [[NSApplication sharedApplication] presentError:error];
        }
        else if ([isDirectory boolValue]) {
            if ([newAlbumsDict valueForKey:url.path]==nil && [self directoryIsPhotoAlbum:url]==YES)
            {
                Album *anAlbum = [[Album alloc] initWithFilePath:url.path];
                [anAlbum updatePhotosFromFileSystem];
                [newAlbumsDict setValue:anAlbum forKey:url.path];
            }
        }
    }
    
    
    return newAlbumsDict;
}


-(NSURL *)rootFilePathURL
{
    NSAssert(self.rootFilePath!=nil, @"No root file path set in FileSystemDataSource");
    return [NSURL fileURLWithPath:self.rootFilePath];
}

-(NSArray *) observedDirectories;
{
    NSURL *rootFilePathURL = [self rootFilePathURL];
    NSString *dropboxHomePath = DefaultDropBoxDirectory();
    NSString *aPath = [NSString stringWithFormat:@"%@/Camera Uploads", dropboxHomePath];
    NSURL *cameraUploadsLocation = [NSURL fileURLWithPath:aPath];
    return [NSArray arrayWithObjects:rootFilePathURL, cameraUploadsLocation, nil];
}

//possible options are ArchDirectoryObserverResponsive and ArchDirectoryObserverObservesSelf
-(void)startObserving
{
    for (NSURL *aDir in [self observedDirectories])
    {
        [aDir addDirectoryObserver:self options:0 resumeToken:nil];
    }
}

-(void)stopObserving
{
    for (NSURL *aDir in [self observedDirectories])
    {
        [aDir removeDirectoryObserver:self];
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
    Album *changedAlbum = [self.albumLookupTable valueForKey:changedURL.path];
    
    if (changedAlbum==nil)
    {
        DLog(@"Received notification for an album that doesn't exist - creating : %@", changedURL.path);
        Album *anAlbum = [[Album alloc] initWithFilePath:changedURL.path];
        if ([anAlbum albumExistsWithPhotos]==YES)
        {
            [anAlbum updatePhotosFromFileSystem];
            if (anAlbum.photos.count!=0)
            {
                [self.albumLookupTable setValue:anAlbum forKey:changedURL.path];
            }
        }
        
        
    } else {
        [changedAlbum updatePhotosFromFileSystem];
        
    }
}

// At least one file somewhere inside--but not necessarily directly descended from--changedURL has changed.  You should examine the directory at changedURL and all subdirectories to see which files changed.
// observedURL: the URL of the dorectory you're observing.
// changedURL: the URL of the actual directory that changed. This could be a subdirectory.
// reason: the reason the observation center can't pinpoint the changed directory.  You may want to ignore some reasons--for example, "ArchDirectoryObserverNoHistoryReason" simply means that you didn't pass a resume token when adding the observer, and so you should do an initial scan of the directory.
// historical: if YES, the event occured sometime before the observer was added.  If NO, it occurred just now.
// resumeToken: the resume token to save if you want to pick back up from this event.
- (void)observedDirectory:(NSURL*)observedURL descendantsAtURLDidChange:(NSURL*)changedURL reason:(ArchDirectoryObserverDescendantReason)reason historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken {
    NSLog(@"Descendents below %@ have changed! Reason : %d", changedURL.path, reason);
}

// An ancestor of the observedURL has changed, so the entire directory tree you're observing may have vanished. You should ensure it still exists.
// observedURL: the URL of the dorectory you're observing.
// changedURL: the URL of the actual directory that changed. For this call, it will presumably be an ancestor directory.
// historical: if YES, the event occured sometime before the observer was added.  If NO, it occurred just now.
// resumeToken: the resume token to save if you want to pick back up from this event.
- (void)observedDirectory:(NSURL*)observedURL ancestorAtURLDidChange:(NSURL*)changedURL historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken {
    NSLog(@"%@, ancestor of your directory, has changed!", changedURL.path);
}

//-------------------------------------------------------
//  This'll cause a very specific crash if my shared instance is ever deallocated due to a bug.
//  (Yes, hex 0x42 is not 42, but it leaves a nice 0x000000042 in a register in the crash log,
//   making it immediately identifiable what happened.)
//   via -> http://goo.gl/C7jho
//-------------------------------------------------------
- (void)dealloc
{
    *(char*)0x42 = 'b';
    // no super, ARC all the way
}

@end
