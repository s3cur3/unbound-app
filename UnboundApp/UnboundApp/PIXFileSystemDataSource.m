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
#import "PIXAlbum.h"
#import "PIXDefines.h"
#import "PIXAppDelegate.h"
#import "PIXAppDelegate+CoreDataUtils.h"

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

@interface PIXFileSystemDataSource()

@property (nonatomic,strong) NSDate *startDate;
@property (nonatomic,strong) NSDate *endDate;
@property (nonatomic,strong) NSDateFormatter *dateFormatter;

//@property(strong) ArchDirectoryObservationResumeToken resumeToken;

-(void)finishedLoadingAlbums;

-(void)startLoadingPhotos;
-(void)finishedLoadingPhotos;

@end

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
        /*if (self.rootFilePath == nil) {
            self.rootFilePath = DefaultDropBoxPhotosDirectory();
            [self loadAllAlbums];
        }*/
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
    NSMutableArray *tmp = [[albumLookupTable allValues] mutableCopy];
    [tmp sortUsingDescriptors:self.sortDescriptors];
    [self.albums removeAllObjects];
    [self.albums addObjectsFromArray:tmp];
    
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

-(NSMutableArray *)sortedAlbums
{
    if (_sortedAlbums==nil)
    {
        _sortedAlbums = [[self.albums sortedArrayUsingDescriptors:self.sortDescriptors] mutableCopy];
    }
    return _sortedAlbums;
}

-(NSArray *)sortDescriptors {
    if (_sortDescriptors==nil) {
        _sortDescriptors = [NSArray arrayWithObject:self.dateMostRecentPhotoDescriptor];
    }
    return _sortDescriptors;
}

-(NSSortDescriptor *)dateMostRecentPhotoDescriptor
{
    if (_dateMostRecentPhotoDescriptor==nil) {
        _dateMostRecentPhotoDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateMostRecentPhoto" ascending:NO];
    }
    return _dateMostRecentPhotoDescriptor;
}

-(void)loadAllAlbums
{
    self.finishedLoading = NO;
    self.startDate = [NSDate date];
    NSLog(@"Started Loading : %@", [self.dateFormatter stringFromDate:self.startDate]);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^(void){
        
        //NSDictionary *albumsDict = [self albumsDictForURL:[self rootFilePathURL]];
        NSMutableDictionary *tmpAlbumLookupTable = [NSMutableDictionary dictionary];
        for (NSURL *aURL in [self observedDirectories])
        {
            //Make sure to add the observed directories themselves if they have photos
            if ([self directoryIsPhotoAlbum:aURL]==YES) {
                Album *anAlbum = [[Album alloc] initWithFilePathURL:aURL];
                [tmpAlbumLookupTable setValue:anAlbum forKey:aURL.path];
            }
            //As well as all of their subdirectories
            NSDictionary *observedDirectoryDict = [self albumsDictForURL:aURL];
            [tmpAlbumLookupTable addEntriesFromDictionary:observedDirectoryDict];
        }
        
        dispatch_async(dispatch_get_main_queue(),^(void){
            _albumLookupTable = tmpAlbumLookupTable;
            [self finishedLoadingAlbums];
            [self setAlbumLookupTable:tmpAlbumLookupTable];
            [self performSelector:@selector(startLoadingPhotos) withObject:nil afterDelay:0.1];
        });
    });
}

-(void)finishedLoadingAlbums
{
    self.endDate = [NSDate date];
    NSLog(@"Finished loading : %@", [self.dateFormatter stringFromDate:self.endDate]);
    NSArray *albums = [self.albumLookupTable allKeys];
    NSLog(@"%ld albums found", [albums count]);
    NSTimeInterval time = [self.endDate timeIntervalSinceDate:self.startDate];
    NSLog(@"%g seconds elapsed", time);
    self.startDate = nil;
    self.endDate = nil;
}

-(void)startLoadingPhotos
{
    dispatch_queue_t myQueue = dispatch_queue_create("com.pixite.ub.photos", 0);
    dispatch_group_t group = dispatch_group_create();
    
    self.startDate = [NSDate date];
    NSEnumerator *albumEnumerator = [self.albumLookupTable objectEnumerator];
    
    
    
    dispatch_group_async(group,myQueue,^(void){
        //NSEnumerator *content = albumEnumerator;
        //NSMutableArray *somePhotos = [NSMutableArray array];
        //NSDate *aDateMostRecentPhoto = nil;
        //NSError *error;
        id anAlbum = nil;
        while (anAlbum = [albumEnumerator nextObject])
        {
            [(Album *)anAlbum updatePhotosFromFileSystem];
        }
        
    });
    
    
    dispatch_group_notify(group, myQueue, ^{
        
        dispatch_async(dispatch_get_main_queue(),^(void){
            [self finishedLoadingPhotos];
            
            //Hack to get albums to reorder on new mostRecentPhotoDate
            [self setAlbumLookupTable:self.albumLookupTable];
            
            //Tell the app delegate we're done and it's time to start observing file system changes
            [[NSNotificationCenter defaultCenter] postNotificationName:kUB_PHOTOS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
        });
    });
    
}

-(void)loadPhotosForAlbum:(Album *)anAlbum
{
    dispatch_queue_t myQueue = dispatch_queue_create("com.pixite.ub.album.photos.update", 0);
    
    dispatch_async(myQueue,^(void){
        [(Album *)anAlbum updatePhotosFromFileSystem];
    });
    
    
}

-(void)finishedLoadingPhotos
{
    self.endDate = [NSDate date];
    NSLog(@"Finished loading photos : %@", [self.dateFormatter stringFromDate:self.endDate]);
    //NSArray *albums = [self.albumLookupTable allKeys];
    //NSLog(@"%ld albums found", [albums count]);
    NSTimeInterval time = [self.endDate timeIntervalSinceDate:self.startDate];
    NSLog(@"%g seconds elapsed", time);
    self.startDate = nil;
    self.endDate = nil;
    
    self.finishedLoading = YES;
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
    //NSURLNameKey, NSURLEffectiveIconKey, NSURLIsDirectoryKey, 
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:aDirectoryURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLTypeIdentifierKey, nil] options:NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:^(NSURL *url, NSError *error) {
     // Handle the error.
     DLog(@"error creating enumerator for directory %@ : %@", url.path, error);
     [[NSApplication sharedApplication] presentError:error];
     // Return YES if the enumeration should continue after the error.
     return YES;
     }];
    
    id obj;
    while (obj = [enumerator nextObject]) {
        if ([self fileIsUnboundMetadataFile:(NSURL *)obj] || [self fileIsImageFile:(NSURL *)obj]==YES)
        {
            return YES;
        }
    }
    return NO;

}
/*-(BOOL)directoryIsPhotoAlbum_old:(NSURL *)aDirectoryURL
{
    
    NSArray *propKeys = [NSArray arrayWithObjects:NSURLNameKey, NSURLTypeIdentifierKey, NSURLIsDirectoryKey, NSURLEffectiveIconKey, nil];
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
}*/

-(NSDictionary *)albumsDictForURL:(NSURL *)aURL
{
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:aURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsDirectoryKey, nil] options:NSDirectoryEnumerationSkipsHiddenFiles /*| NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants*/ errorHandler:^(NSURL *url, NSError *error) {
        // Handle the error.
        DLog(@"error enumerating directory %@ : %@", url.path, error);
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
                Album *anAlbum = [[Album alloc] initWithFilePathURL:url];
                //[anAlbum updatePhotosFromFileSystem];
                [newAlbumsDict setValue:anAlbum forKey:url.path];
            }
        }
    }
    
    
    return newAlbumsDict;
}

-(NSDateFormatter *)dateFormatter
{
    if (_dateFormatter==nil) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [self.dateFormatter setTimeStyle:NSDateFormatterLongStyle];
    }
    return _dateFormatter;
}

-(NSString *)rootFilePath
{
    if (_rootFilePath == nil) {
        _rootFilePath = DefaultDropBoxPhotosDirectory();
    }
    return _rootFilePath;
}

-(NSURL *)rootFilePathURL
{
    NSAssert(self.rootFilePath!=nil, @"No root file path set in FileSystemDataSource");
    return [NSURL fileURLWithPath:self.rootFilePath];
}

-(NSArray *) observedDirectories;
{
    if (_observedDirectories==nil) {
        NSURL *rootFilePathURL = [self rootFilePathURL];
        NSString *dropboxHomePath = DefaultDropBoxDirectory();
        NSString *aPath = [NSString stringWithFormat:@"%@/Camera Uploads", dropboxHomePath];
        NSURL *cameraUploadsLocation = [NSURL fileURLWithPath:aPath];
        _observedDirectories = [NSArray arrayWithObjects:rootFilePathURL, cameraUploadsLocation, nil];
    }
    return _observedDirectories;
}

//possible options are ArchDirectoryObserverResponsive and ArchDirectoryObserverObservesSelf
-(void)startObserving
{
    for (NSURL *aDir in [self observedDirectories])
    {
        NSString *tokenKeyString = [NSString stringWithFormat:@"resumeToken-%@", aDir.path];
        NSData *token = [[NSUserDefaults standardUserDefaults] dataForKey:tokenKeyString];
        NSData *decodedToken = [NSKeyedUnarchiver unarchiveObjectWithData:token];
        [aDir addDirectoryObserver:self options:0 resumeToken:decodedToken];
        //[aDir addDirectoryObserver:self options:0 resumeToken:nil];
    }
}

-(void)updateResumeToken:(ArchDirectoryObservationResumeToken)resumeToken forObservedDirectory:(NSURL *)observedURL
{
    if (resumeToken!=nil) {
        NSString *tokenKeyString = [NSString stringWithFormat:@"resumeToken-%@", observedURL.path];
        NSData *dataObject = [NSKeyedArchiver archivedDataWithRootObject:resumeToken];
        [[NSUserDefaults standardUserDefaults] setObject:dataObject forKey:tokenKeyString];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

-(void)stopObserving
{
    [NSURL removeObserverForAllDirectories:self];
//    for (NSURL *aDir in [self observedDirectories])
//    {
//        [aDir removeDirectoryObserver:self];
//    }
}

// At least one file in the directory indicated by changedURL has changed.  You should examine the directory at changedURL to see which files changed.
// observedURL: the URL of the dorectory you're observing.
// changedURL: the URL of the actual directory that changed. This could be a subdirectory.
// historical: if YES, the event occured sometime before the observer was added.  If NO, it occurred just now.
// resumeToken: the resume token to save if you want to pick back up from this event.
- (void)observedDirectory:(NSURL*)observedURL childrenAtURLDidChange:(NSURL*)changedURL historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken {
    
    
    DLog(@"\r\n*******\nobservedDirectory:'%@'\nchildrenAtURLDidChange: %@\nhistorical: %@\r\n*******", observedURL.path, changedURL.path, historical ? @"YES" : @"NO");
    [self updateResumeToken:resumeToken forObservedDirectory:observedURL];
    
    if (historical) {
        DLog(@"Files in album '%@' have changed while the app was not active", changedURL.path);
        //NSAssert(NO, @"Not expecting historical changes in childrenAtURLDidChange");
    }
    PIXAppDelegate *appDelegate = [PIXAppDelegate sharedAppDelegate];
    PIXAlbum *dbAlbum = [appDelegate fetchAlbumWithPath:changedURL.path inContext:appDelegate.managedObjectContext];
    if (dbAlbum!=nil) {
        NSNotification *albumChangedNotification = [NSNotification notificationWithName:AlbumDidChangeNotification
                                                                                 object:dbAlbum
                                                                               userInfo:@{@"changedURL" : changedURL, @"observedURL" : observedURL}];
        
        [[NSNotificationQueue defaultQueue] enqueueNotification:albumChangedNotification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnSender forModes:nil];
    } else {
        DLog(@"No album at path %@", changedURL.path);
    }
    
//
//    NSLog(@"Files in %@ have changed!", changedURL.path);
//    Album *changedAlbum = [self.albumLookupTable valueForKey:changedURL.path];
//    
//    if (changedAlbum==nil)
//    {
//        DLog(@"Received notification for an album that doesn't exist - creating : %@", changedURL.path);
//        Album *anAlbum = [[Album alloc] initWithFilePath:changedURL.path];
//        if ([anAlbum albumExistsWithPhotos]==YES)
//        {
//            [anAlbum updatePhotosFromFileSystem];
//            if (anAlbum.photos.count!=0)
//            {
//                [self.albumLookupTable setValue:anAlbum forKey:changedURL.path];
//            }
//        }
//        
//        
//    } else {
//        [self loadPhotosForAlbum:changedAlbum];
//    }
}

//typedef enum {
//    // You added an observer with a nil resume token, so the directory's history is unknown.
//    ArchDirectoryObserverNoHistoryReason = 0,
//    // The observation center coalesced events that occurred only a couple seconds apart.
//    ArchDirectoryObserverCoalescedReason,
//    // Events came too fast and some were dropped.
//    ArchDirectoryObserverEventDroppedReason,
//    // Event ID numbers have wrapped and so the history is not reliable.
//    ArchDirectoryObserverEventIDsWrappedReason,
//    // A volume was mounted in a subdirectory.
//    ArchDirectoryObserverVolumeMountedReason,
//    // A volume was unmounted in a subdirectory.
//    ArchDirectoryObserverVolumeUnmountedReason
//} ArchDirectoryObserverDescendantReason;

// At least one file somewhere inside--but not necessarily directly descended from--changedURL has changed.  You should examine the directory at changedURL and all subdirectories to see which files changed.
// observedURL: the URL of the dorectory you're observing.
// changedURL: the URL of the actual directory that changed. This could be a subdirectory.
// reason: the reason the observation center can't pinpoint the changed directory.  You may want to ignore some reasons--for example, "ArchDirectoryObserverNoHistoryReason" simply means that you didn't pass a resume token when adding the observer, and so you should do an initial scan of the directory.
// historical: if YES, the event occured sometime before the observer was added.  If NO, it occurred just now.
// resumeToken: the resume token to save if you want to pick back up from this event.
- (void)observedDirectory:(NSURL*)observedURL descendantsAtURLDidChange:(NSURL*)changedURL reason:(ArchDirectoryObserverDescendantReason)reason historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken {

    DLog(@"\r\n*******\r\nobservedDirectory:'%@'\r\ndescendantsAtURLDidChange: '%@'\r\nreason: %d\r\nhistorical: %@\r\n*******", observedURL.path, changedURL.path, reason, historical ? @"YES" : @"NO");
    [self updateResumeToken:resumeToken forObservedDirectory:observedURL];
    
    //This seems to be an initial notification that can be safely ignored
    if (reason == ArchDirectoryObserverNoHistoryReason)
    {
        DLog(@"Skipping FSEvent with reason: ArchDirectoryObserverNoHistoryReason");
        return;
    } else if (reason == ArchDirectoryObserverCoalescedReason) {
        DLog(@"FSEvent with reason: ArchDirectoryObserverCoalescedReason");
    } else {
        DLog(@"FSEvent with reason: %d", reason);
    }
}

// An ancestor of the observedURL has changed, so the entire directory tree you're observing may have vanished. You should ensure it still exists.
// observedURL: the URL of the dorectory you're observing.
// changedURL: the URL of the actual directory that changed. For this call, it will presumably be an ancestor directory.
// historical: if YES, the event occured sometime before the observer was added.  If NO, it occurred just now.
// resumeToken: the resume token to save if you want to pick back up from this event.
- (void)observedDirectory:(NSURL*)observedURL ancestorAtURLDidChange:(NSURL*)changedURL historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken {
    
    DLog(@"\r\n*******\r\nobservedDirectory:'%@'\r\nancestorAtURLDidChange: '%@'\r\nhistorical: %@\r\n*******", observedURL.path, changedURL.path, historical ? @"YES" : @"NO");
    [self updateResumeToken:resumeToken forObservedDirectory:observedURL];
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
