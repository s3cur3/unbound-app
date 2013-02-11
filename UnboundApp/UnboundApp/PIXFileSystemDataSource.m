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
#import "PIXDefines.h"
#import "PIXGetAlbumPathsOperation.h"
#import "PIXLoadAlbumOperation.h"

#define ONLY_LOAD_ALBUMS_WITH_IMAGES 1

//extern NSString *kUB_ALBUMS_LOADED_FROM_FILESYSTEM;
//extern NSString *kLoadImageDidFinish;
extern NSString *kLoadAlbumDidFinish;
extern NSString *kGetPathsOperationDidFinish;
//extern NSString *kScanCountKey;

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
@property (nonatomic, strong) NSOperationQueue *loadingQueue;

@property (nonatomic, strong) NSMutableDictionary *loadingAlbumsDict;


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
        tableRecords = [[NSMutableArray alloc] init];
        scanCount = 0;
        self.finishedLoading = YES;
        self.loadingAlbumsDict = [[NSMutableDictionary alloc] init];
        /*if (self.rootFilePath == nil) {
            self.rootFilePath = DefaultDropBoxPhotosDirectory();
            [self loadAllAlbums];
        }*/
    }
    return self;
}

-(NSOperationQueue *)loadingQueue;
{
    if (_loadingQueue == NULL)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _loadingQueue = [[NSOperationQueue alloc] init];
            [_loadingQueue setName:@"com.pixite.thumbnail.generator"];
            [_loadingQueue setMaxConcurrentOperationCount:1];
        });
        
    }
    return _loadingQueue;
}

-(void)checkIfFinishedLoading
{
    //NSAssert(!self.finishedLoading, @"checkIfFinishedLoading called too many times");
    if (self.finishedLoading == YES) {
        DLog(@"Should not happen");
        return;
    }
    if (self.loadingQueue.operationCount == 0) {
        // Do something here when your queue has completed
        NSLog(@"queue has completed");
        if ([[self.loadingQueue operations] count] == 0)
        {
            self.finishedLoading = YES;
            [self.loadingQueue removeObserver:self forKeyPath:@"operationCount"];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kLoadImageDidFinish object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kLoadAlbumDidFinish object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kGetPathsOperationDidFinish object:nil];
            //NSAssert([[NSThread currentThread] isMainThread], @"Not on main thread!");
            [self performSelectorOnMainThread:@selector(finishAndSaveRecords) withObject:nil waitUntilDone:NO];
        } else {
            DLog(@"\r\n[[self.loadingQueue operations] count] : %ld", [[self.loadingQueue operations] count]);
        }
    } else {
        DLog(@"checkIfFinishedLoading - operation count : %ld", self.loadingQueue.operationCount);
    }
}

- (void)mainThread_handleLoadedImages:(NSNotification *)note
{
    // Pending NSNotifications can possibly back up while waiting to be executed,
	// and if the user stops the queue, we may have left-over pending
	// notifications to process.
	//
	// So make sure we have "active" running NSOperations in the queue
	// if we are to continuously add found image files to the table view.
	// Otherwise, we let any remaining notifications drain out.
	//
	NSDictionary *notifData = [note userInfo];
    
    NSNumber *loadScanCountNum = [notifData valueForKey:kScanCountKey];
    NSInteger loadScanCount = [loadScanCountNum integerValue];
    
    if (YES)//[myStopButton isEnabled])
    {
        // make sure the current scan matches the scan of our loaded image
        if (scanCount == loadScanCount)
        {
            [tableRecords addObject:notifData];
        } else {
            DLog(@"here is the problem, scanCount: %ld, loadScanCount = %ld ", scanCount, loadScanCount);
        }
    }
    if (self.finishedLoading == NO) {
        [self performSelector:@selector(checkIfFinishedLoading) withObject:nil afterDelay:0.0f];
    }
}

-(void)anyThread_handleLoadedImages:(NSNotification *)note
{
    [self performSelectorOnMainThread:@selector(mainThread_handleLoadedImages:) withObject:note waitUntilDone:NO];
    NSLog(@"\r\n\t\timage loaded : %@", [note.userInfo valueForKey:@"path"]);
}

-(void)anyThread_handleLoadedAlbums:(NSNotification *)note
{
    //[self performSelectorOnMainThread:@selector(mainThread_handleLoadedImages:) withObject:note waitUntilDone:NO];
    NSLog(@"\r\n\talbum loaded : %@", [note.userInfo valueForKey:@"path"]);
    [self performSelectorOnMainThread:@selector(checkIfFinishedLoading) withObject:nil waitUntilDone:NO];
}


-(void)anyThread_handleLoadedPaths:(NSNotification *)note
{
    //[self performSelectorOnMainThread:@selector(mainThread_handleLoadedImages:) withObject:note waitUntilDone:NO];
    NSLog(@"\r\npath loaded : %@", [note.userInfo valueForKey:@"path"]);
    [self performSelectorOnMainThread:@selector(checkIfFinishedLoading) withObject:nil waitUntilDone:NO];
}

-(void)startLoadingAllAlbumsAndPhotosInObservedDirectories
{
    self.finishedLoading = NO;
    scanCount++;
    // register for the notification when an image file has been loaded by the NSOperation: "LoadOperation"
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(anyThread_handleLoadedImages:)
                                                 name:kLoadImageDidFinish
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(anyThread_handleLoadedAlbums:)
                                                 name:kLoadAlbumDidFinish
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(anyThread_handleLoadedPaths:)
                                                 name:kGetPathsOperationDidFinish
                                               object:nil];
    

    [tableRecords removeAllObjects];
    NSArray *photoDirs = [self observedDirectories];
    for (NSURL *aURL in photoDirs)
    {
        PIXLoadAlbumOperation *loadTopLevelOperation = [[PIXLoadAlbumOperation alloc] initWithRootURL:aURL queue:self.loadingQueue scanCount:scanCount];
        [loadTopLevelOperation setQueuePriority:NSOperationQueuePriorityVeryLow];
        [self.loadingQueue addOperation:loadTopLevelOperation];	// this will start the "GetPathsOperation"
    }
    

    for (NSURL *aURL in photoDirs)
    {
        PIXGetAlbumPathsOperation *getPathsOp = [[PIXGetAlbumPathsOperation alloc] initWithRootURL:aURL queue:self.loadingQueue scanCount:scanCount];
        [getPathsOp setQueuePriority:NSOperationQueuePriorityLow];
        [self.loadingQueue addOperation:getPathsOp];	// this will start the "GetPathsOperation"
    }
    
    [self.loadingQueue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == self.loadingQueue && [keyPath isEqualToString:@"operationCount"]) {
        if (self.loadingQueue.operationCount == 0) {
            // Do something here when your queue has completed
            NSLog(@"queue has completed");
            if ([[self.loadingQueue operations] count] == 0)
            {
                //NSAssert([[NSThread currentThread] isMainThread], @"Not on main thread!");
                [self performSelectorOnMainThread:@selector(checkIfFinishedLoading) withObject:nil waitUntilDone:NO];
            } else {
                DLog(@"\r\n[[self.loadingQueue operations] count] : %ld", [[self.loadingQueue operations] count]);
            }
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object
                               change:change context:context];
    }
}

-(void)finishAndSaveRecords
{
    /*PhotoLoadOperation *op = [[PhotoLoadOperation alloc] initWithData:tableRecords];
     NSOperationQueue *saveQueue = [[NSOperationQueue alloc] init];
     [saveQueue addOperation:op];*/
    //PIXAppDelegate *appDelegate = (PIXAppDelegate *)[[NSApplication sharedApplication] delegate];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSearchDidFinishNotification object:self userInfo:@{@"items" : [tableRecords copy]}];
    //[appDelegate addItemToList:[tableRecords copy]];
    //[self fetchRecords];
    //[saveQueue waitUntilAllOperationsAreFinished];
    //NSLog(@"DONE SAVING DATA");
    //[queue setSuspended:NO];
    //NSString *resultStr = [NSString stringWithFormat:@"DONE LOADING!\nImages found: %ld", [tableRecords count]];
    //[self setResultsString: resultStr];
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
    DLog(@"** STARTING FILE SYSTEM OBSERVATION **");
    for (NSURL *aDir in [self observedDirectories])
    {
        NSString *tokenKeyString = [NSString stringWithFormat:@"resumeToken-%@", aDir.path];
        NSData *token = [[NSUserDefaults standardUserDefaults] dataForKey:tokenKeyString];
        NSData *decodedToken = [NSKeyedUnarchiver unarchiveObjectWithData:token];
        [aDir addDirectoryObserver:self options:ArchDirectoryObserverResponsive resumeToken:decodedToken];
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
    
    //[tableRecords removeAllObjects];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(anyThread_handleLoadedImages:)
//                                                 name:kLoadAlbumDidFinish
//                                               object:nil];
    
    
    if ([self.loadingAlbumsDict objectForKey:changedURL.path]==nil) {
        [self.loadingAlbumsDict setObject:changedURL forKey:changedURL.path];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //
            NSArray *photoFiles = [self getFilesAtURL:changedURL];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[PIXAppDelegate sharedAppDelegate] parsePhotos:photoFiles withPath:changedURL.path];
                [self.loadingAlbumsDict removeObjectForKey:changedURL.path];
            });

        });
        
    }
    
    //TODO: check for deleted albums
    
    
//    scanCount++;
//    
//    PIXLoadAlbumOperation *op = [[PIXLoadAlbumOperation alloc] initWithRootURL:changedURL queue:self.loadingQueue scanCount:0];
//    
//    [op setQueuePriority:NSOperationQueuePriorityVeryLow];
//    [self.loadingQueue addOperation:op];
//    
//    [self.loadingQueue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
    

//    if (self.finishedLoading) {
//        [self startLoadingAllAlbumsAndPhotosInObservedDirectories];
//    }
    
    
    // this will start the "GetPathsOperation"
    /*PIXAppDelegate *appDelegate = [PIXAppDelegate sharedAppDelegate];
     PIXAlbum *dbAlbum = [appDelegate fetchAlbumWithPath:changedURL.path inContext:appDelegate.managedObjectContext];
     if (dbAlbum!=nil) {
     NSNotification *albumChangedNotification = [NSNotification notificationWithName:AlbumDidChangeNotification
     object:dbAlbum
     userInfo:@{@"changedURL" : changedURL, @"observedURL" : observedURL}];
     
     [[NSNotificationQueue defaultQueue] enqueueNotification:albumChangedNotification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnSender forModes:nil];
     } else {
     DLog(@"No album at path %@", changedURL.path);
     }*/
    
    
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


-(NSArray *)getFilesAtURL:(NSURL *)url
{
    NSMutableArray *photoFiles = [NSMutableArray new];
    NSFileManager *localFileManager=[[NSFileManager alloc] init];
    NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants;
    NSDirectoryEnumerator *dirEnumerator = [localFileManager enumeratorAtURL:url
                                                  includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey,
                                                                              NSURLIsDirectoryKey,NSURLTypeIdentifierKey,NSURLCreationDateKey,nil]
                                                                     options:options
                                                                errorHandler:^(NSURL *url, NSError *error) {
                                                                    // Handle the error.
                                                                    [PIXAppDelegate presentError:error];
                                                                    // Return YES if the enumeration should continue after the error.
                                                                    return YES;
                                                                }];
    id obj;
    while (obj = [dirEnumerator nextObject]) {
        if ([self fileIsImageFile:(NSURL *)obj]==YES)
        {
            NSDate *fileCreationDate;
            NSURL *aURL = (NSURL *)obj;
            [aURL getResourceValue:&fileCreationDate forKey:NSURLCreationDateKey error:nil];
            
            /*NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
             [formatter setTimeStyle:NSDateFormatterNoStyle];
             [formatter setDateStyle:NSDateFormatterShortStyle];
             NSString *modDateStr = [formatter stringFromDate:fileCreationDate];*/
            
            NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [aURL lastPathComponent], kNameKey,
                                  //[self.loadURL absoluteString], kPathKey,
                                  [aURL path], kPathKey,
                                  [[aURL URLByDeletingLastPathComponent] path] , kDirectoryPathKey,
                                  //modDateStr, kModifiedKey,
                                  fileCreationDate, kCreatedKey,
                                  //[NSString stringWithFormat:@"%ld", [fileSize integerValue]], kSizeKey,
                                  //[NSNumber numberWithInteger:ourScanCount], kScanCountKey,  // pass back to check if user cancelled/started a new scan
                                  nil];
            [photoFiles addObject:info];
            
        }
    }
    
    return photoFiles;

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
