//
//  PIXFileParser.m
//  UnboundApp
//
//  Created by Scott Sykora on 2/20/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXFileParser.h"
#import "PIXFileManager.h"
#import "PIXAppDelegate.h"
#import "PIXDefines.h"
#import "PIXAlbum.h"
#import "PIXPhoto.h"

#import "ArchDirectoryObservationCenter.h"
#import "NSURL+DirectoryObserver.h"

#include <sys/types.h>
#include <pwd.h>
#include <unistd.h>

@interface PIXFileParser () <ArchDirectoryObserver>

@property (nonatomic,strong) NSDate *startDate;
@property (nonatomic, strong) NSMutableDictionary *loadingAlbumsDict;

@property BOOL scansCancelledFlag;

@property int isWorkingCounter;

@property float fullScannProgressCurrent;
@property float fullScannProgressTotal;

@property (strong, nonatomic) NSMutableDictionary * pendingFolderScanPaths;

@end

@implementation PIXFileParser

@synthesize sandboxScopeURLs = _sandboxScopeURLs;

-(void)incrementWorking
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isWorkingCounter++;
        
        if(self.isWorkingCounter > 0 && self.isWorking == NO)
        {
            self.isWorking = YES;
        }
    });
}

-(void)decrementWorking
{
    // deley this slightly so the spinner doens't flash constanly
    double delayInSeconds = 0.3;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.isWorkingCounter--;
        
        if(self.isWorkingCounter <= 0)
        {
            self.isWorkingCounter = 0;
            self.isWorking = NO;
        }
    });
}


- (dispatch_queue_t)sharedParsingQueue
{
    static dispatch_queue_t _sharedParsingQueue = 0;
    
    static dispatch_once_t onceTokenParsingQueue;
    dispatch_once(&onceTokenParsingQueue, ^{
        _sharedParsingQueue  = dispatch_queue_create("com.pixite.ub.parsingQueue", 0);
        
        // set this to a high priority queue so it doens't get blocked by the thumbs loading
        dispatch_set_target_queue(_sharedParsingQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        
        
    });
    
    return _sharedParsingQueue;
}

+ (PIXFileParser *)sharedFileParser
{
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}


#pragma mark - Directory Methods
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

NSString * aDefaultDropBoxDirectory()
{
    NSString *dropBoxHome =[UserHomeDirectory() stringByAppendingPathComponent:@"Dropbox/"];
    return dropBoxHome;
}

NSString * aDefaultDropBoxPhotosDirectory()
{
    NSString *dropBoxPhotosHome =[aDefaultDropBoxDirectory() stringByAppendingPathComponent:@"Photos/"];
    return dropBoxPhotosHome;
}


/*
 * dictionaryForURL will check if a file is an image or unbound file. If it is it will 
 * create the correct dictionary for that object for parsing later in the parseFiles 
 * method. This is written as a c function so it performs a little better in the 
 * tight loops where it's called
 */
 
NSDictionary * dictionaryForURL(NSURL * url)
{
    
    BOOL isImageFile = NO;
    NSString *utiValue;
    [url getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:nil];
    if (utiValue)
    {
        isImageFile = (UTTypeConformsTo((__bridge CFStringRef)utiValue, kUTTypeImage)) ||
                      (UTTypeConformsTo((__bridge CFStringRef)utiValue, kUTTypeMovie));
        
    }
    
    if(isImageFile)
    {
        NSDate *fileCreationDate;
        NSDate *fileModifiedDate;
        NSNumber *fileSize;
        
        [url getResourceValue:&fileCreationDate forKey:NSURLCreationDateKey error:nil];
        [url getResourceValue:&fileModifiedDate forKey:NSURLContentModificationDateKey error:nil];
        [url getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
        
        
        
        NSMutableDictionary *info = [@{kNameKey : [url lastPathComponent],
                               kPathKey : [url path],
                                     kDirectoryPathKey : [[url URLByDeletingLastPathComponent] path]} mutableCopy];
        
        if(fileCreationDate)
        {
            info[kCreatedKey] = fileCreationDate;
        }
        
        if(fileModifiedDate)
        {
            info[kModifiedKey] = fileModifiedDate;
        }
        
        if(fileSize)
        {
            info[kFileSizeKey] = fileSize;
        }

        
        return info;
        
    }
    
    else
    {
        NSNumber * isDirectoryValue;
        [url getResourceValue:&isDirectoryValue forKey:NSURLIsDirectoryKey error:nil];
        
        // we found a directory. Check if a .unbound file exists in this dir
        if([isDirectoryValue boolValue])
        {
            NSURL * unboundFileURL = [url URLByAppendingPathComponent:@".unbound"];
            
            NSDate *fileCreationDate = nil;
            [unboundFileURL getResourceValue:&fileCreationDate forKey:NSURLCreationDateKey error:nil];
            
            // if the .unbound file exits this won't be nil
            if(fileCreationDate)
            {
            
                NSDictionary *info = @{kIsUnboundFileKey : [NSNumber numberWithBool:YES],
                                       kNameKey : [unboundFileURL lastPathComponent],
                                       kPathKey : [unboundFileURL path],
                                       kDirectoryPathKey : [[unboundFileURL URLByDeletingLastPathComponent] path],
                                       kCreatedKey : fileCreationDate};
                
                return info;
            }
        }
    }
    
    return nil;
}

#pragma mark - File System Change Oberver Methods

-(BOOL)canAccessObservedDirectories
{
    BOOL canAccessAllDirectories = YES;
    
    DLog(@"** CHECKING FILE SYSTEM OBSERVATION AVAILABILITY **");
    
    for(NSURL * aScopeURL in self.sandboxScopeURLs)
    {
        [aScopeURL startAccessingSecurityScopedResource];
    }
    
    for (NSURL *aDir in [self observedDirectories])
    {
        
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:aDir.path isDirectory:&isDir]) {
            if (isDir!=YES) {
                canAccessAllDirectories = NO;
            }
        } else {
            canAccessAllDirectories = NO;
        }
        if (!isDir) {
            DLog(@"Unable to access file at path : '%@'\nisDirectory : %d", aDir.path, isDir);
        }
    }
    
    for(NSURL * aScopeURL in self.sandboxScopeURLs)
    {
        [aScopeURL stopAccessingSecurityScopedResource];
    }
    
    return canAccessAllDirectories;
}

-(void)startObserving
{
    // remove any observers, we only do this once
    [self stopObserving];
    
    for(NSURL * aScopeURL in self.sandboxScopeURLs)
    {
        [aScopeURL startAccessingSecurityScopedResource];
    }
    
    DLog(@"** STARTING FILE SYSTEM OBSERVATION **");
    for (NSURL *aDir in [self observedDirectories])
    {
        
        NSString *tokenKeyString = [NSString stringWithFormat:@"resumeToken-%@", aDir.path];
        NSData *token = [[NSUserDefaults standardUserDefaults] dataForKey:tokenKeyString];
        
        NSData * decodedToken = nil;
        
        if(token)
        {
            decodedToken = [NSKeyedUnarchiver unarchiveObjectWithData:token];
        }

        //[aDir addDirectoryObserver:self options:ArchDirectoryObserverResponsive | ArchDirectoryObserverObservesSelf resumeToken:decodedToken];
        
        
        [aDir addDirectoryObserver:self options:ArchDirectoryObserverResponsive resumeToken:decodedToken];
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
    // use the iVar here so we don't create a new list int he lazy getter (only stop if they're already loaded)
    for(NSURL * aScopeURL in _sandboxScopeURLs)
    {
        [aScopeURL stopAccessingSecurityScopedResource];
    }
    
    [NSURL removeObserverForAllDirectories:self];
    [self.loadingAlbumsDict removeAllObjects];
    _observedDirectories = nil;
    _sandboxScopeURLs = nil;
}


// At least one file in the directory indicated by changedURL has changed.  You should examine the directory at changedURL to see which files changed.
// observedURL: the URL of the dorectory you're observing.
// changedURL: the URL of the actual directory that changed. This could be a subdirectory.
// historical: if YES, the event occured sometime before the observer was added.  If NO, it occurred just now.
// resumeToken: the resume token to save if you want to pick back up from this event.
- (void)observedDirectory:(NSURL*)observedURL childrenAtURLDidChange:(NSURL*)changedURL historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken flags:(FSEventStreamEventFlags)flags
{    
    // update the resume token
    [self updateResumeToken:resumeToken forObservedDirectory:observedURL];
    
    if(![self isURLInObservedDirectories:changedURL]) return; // if this item isn't supposed to be observed do nothing
    
    // if the path is inside a package then don't traverse
    
    NSURL * subURL = changedURL;
    
    while ([self isURLInObservedDirectories:subURL]) {
        
        NSNumber * isPackage;
        NSNumber * isHidden;
        
        [subURL getResourceValue:&isPackage forKey:NSURLIsPackageKey error:nil];
        [subURL getResourceValue:&isHidden forKey:NSURLIsHiddenKey error:nil];
        
        subURL = [subURL URLByDeletingLastPathComponent];
        
        if([isPackage boolValue] || [isHidden boolValue])
        {
            if ([PIXFileManager fileIsMetadataFile:changedURL]) {
                if(self.pendingFolderScanPaths[subURL] == nil)
                {
                    // set a dummy object in this dictionary
                    self.pendingFolderScanPaths[subURL] = [NSNumber numberWithBool:YES];
                    
                    // delay for half a second so any other scans of the same folder don't get done
                    double delayInSeconds = 0.5;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        
                        [self.pendingFolderScanPaths removeObjectForKey:subURL];
                        
                        // start the scan of the url
                        [self scanURLForChanges:subURL withRecursion:PIXFileParserRecursionNone];
                        
                    });
                }
            }
            // do nothing, this is hidden or a package
            return;
        }
        
        
        
    }
    

    
    
    // if the item was renamed (both dir or file) then just scan the dir above it non-recursively    
    if(flags & kFSEventStreamEventFlagItemRenamed)
    {
        subURL = [changedURL URLByDeletingLastPathComponent];
        if([self isURLInObservedDirectories:subURL])
        {
            // we may be scanning a url a bunch of times so delay by a little in case there are more scans to do
            
            // if we're not already going to scan this path
            if(self.pendingFolderScanPaths[subURL] == nil) 
            {
                // set a dummy object in this dictionary
                self.pendingFolderScanPaths[subURL] = [NSNumber numberWithBool:YES];
                
                // delay for half a second so any other scans of the same folder don't get done
                double delayInSeconds = 0.5;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    
                    [self.pendingFolderScanPaths removeObjectForKey:subURL];
                    
                    // start the scan of the url
                    [self scanURLForChanges:subURL withRecursion:PIXFileParserRecursionNone];
                    
                });
            }
            
            
            
        }
        
        // if it's a dir we should also scan inside it
        if(flags & kFSEventStreamEventFlagItemIsDir)
        {
            [self scanURLForChanges:changedURL withRecursion:PIXFileParserRecursionFull];
        }
        
        return;
    }
    
    // if this is a file then handle deletions, creations and modifications
    
    if(flags & kFSEventStreamEventFlagItemIsFile)
    {
        if(flags & kFSEventStreamEventFlagItemRemoved)
        {
            [self deleteURL:changedURL];
        }
        
        else
        {
            [self scanFile:changedURL];
        }
    }
    
    
    
    // do a fully recursive scan of the directory (this is a notification the requires subdirs)
    if(flags & kFSEventStreamEventFlagMustScanSubDirs)
    {
        [self scanURLForChanges:changedURL withRecursion:PIXFileParserRecursionFull];
    }
    
    // do a non recursive scan of the directory (this isn't a notification the requires subdirs)
    else
    {
        [self scanURLForChanges:changedURL withRecursion:PIXFileParserRecursionNone];
    }
    
}



-(BOOL)isURLInObservedDirectories:(NSURL *)subURL
{
    for(NSURL * anObservedDirectory in self.observedDirectories)
    {
        if([[subURL path] hasPrefix:[anObservedDirectory path]])
        {
            return YES;
        }
    }
    
    return NO;
}

// At least one file somewhere inside--but not necessarily directly descended from--changedURL has changed.  You should examine the directory at changedURL and all subdirectories to see which files changed.
// observedURL: the URL of the dorectory you're observing.
// changedURL: the URL of the actual directory that changed. This could be a subdirectory.
// reason: the reason the observation center can't pinpoint the changed directory.  You may want to ignore some reasons--for example, "ArchDirectoryObserverNoHistoryReason" simply means that you didn't pass a resume token when adding the observer, and so you should do an initial scan of the directory.
// historical: if YES, the event occured sometime before the observer was added.  If NO, it occurred just now.
// resumeToken: the resume token to save if you want to pick back up from this event.
- (void)observedDirectory:(NSURL*)observedURL descendantsAtURLDidChange:(NSURL*)changedURL reason:(ArchDirectoryObserverDescendantReason)reason historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken
{
    // update the resume token
    [self updateResumeToken:resumeToken forObservedDirectory:observedURL];
}

// An ancestor of the observedURL has changed, so the entire directory tree you're observing may have vanished. You should ensure it still exists.
// observedURL: the URL of the dorectory you're observing.
// changedURL: the URL of the actual directory that changed. For this call, it will presumably be an ancestor directory.
// historical: if YES, the event occured sometime before the observer was added.  If NO, it occurred just now.
// resumeToken: the resume token to save if you want to pick back up from this event.
- (void)observedDirectory:(NSURL*)observedURL ancestorAtURLDidChange:(NSURL*)changedURL historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken
{
    // update the resume token
    [self updateResumeToken:resumeToken forObservedDirectory:observedURL];
    
    if(![self isURLInObservedDirectories:changedURL]) return; // if this item isn't supposed to be observed do nothing

}

#pragma mark - Methods for Scanning file system

- (void)cancelScans
{
    self.scansCancelledFlag = YES;
}

/**
 * This method will do a deep scan of the entire directory structure
 */

- (void)scanFullDirectory
{
    
    // force a new context to be used
    [self.parseContext rollback];
    
    // must do this at the begining of each new scan to reset context
    self.parseContext = nil;
    
    [self incrementWorking];
    
    self.fullScanProgress = 0.0;
    
    // use this flag so the deep scan will restart if the app crashes half way through
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDeepScanIncompleteKey];
    
    // set this to a high priority queue so it doens't get blocked by the thumbs loading
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        dispatch_group_t deletionWaitGroup = dispatch_group_create();
        
        if(self.scansCancelledFlag)
        {
            [self decrementWorking];
            self.fullScanProgress = 1.0;
            return;
        }
        
        self.fullScannProgressCurrent = 0;
        self.fullScannProgressTotal = 0;
        
        NSDate * startScanTime = [NSDate date];
        
        NSMutableArray *photoFiles = [NSMutableArray new];
        
        for(NSURL * aScopeURL in self.sandboxScopeURLs)
        {
            [aScopeURL startAccessingSecurityScopedResource];
        }
                
        // loop through each of the enumerators (there can be more than one)
        for(NSURL * aTopURL in self.observedDirectories)
        {
            
            
            NSDirectoryEnumerator *dirEnumerator = nil;
            //NSUInteger progressCounter = 0;
            
            BOOL isDir = NO;
            if([[NSFileManager defaultManager] fileExistsAtPath:aTopURL.path isDirectory:&isDir] && isDir)
            {
                NSFileManager *localFileManager=[[NSFileManager alloc] init];
                
                NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles |
                                                        NSDirectoryEnumerationSkipsPackageDescendants;
                
                dirEnumerator = [localFileManager enumeratorAtURL:aTopURL
                                       includingPropertiesForKeys:@[NSURLNameKey,
                                                                    NSURLIsDirectoryKey,
                                                                    NSURLTypeIdentifierKey,
                                                                    NSURLCreationDateKey,
                                                                    NSURLAttributeModificationDateKey,
                                                                    NSURLFileSizeKey]
                                                          options:options
                                                     errorHandler:^(NSURL *url, NSError *error) {
                                                         
                                                         for(NSURL * aScopeURL in _sandboxScopeURLs)
                                                         {
                                                             [aScopeURL stopAccessingSecurityScopedResource];
                                                         }
                                                         
                                                         return NO;
                                                     }];
                

            }
            
            
            // loop through each item in each enumerator
            
            
            NSURL *aURL = nil;
            while (aURL = [dirEnumerator nextObject]) {
                
                // if this is an parsable file add it to the photofiles array to be parsed
                NSDictionary * info = dictionaryForURL(aURL);
                
                if(info != nil)
                {
                    [photoFiles addObject:info];
                    
                    self.fullScannProgressTotal++;
                }
            }
            
            // add the unbound file of the main directory if it exists
            NSDictionary * info = dictionaryForURL(aTopURL);
            
            if(info != nil)
            {
                [photoFiles addObject:info];
            }
            
            // check the photoFiles count. When it goes above a threshhold
            // send it off to the parser to start parsing them at the same time
            if([photoFiles count] > 1500)
            {
                if(self.scansCancelledFlag)
                {
                    [self decrementWorking];
                    self.fullScanProgress = 1.0;
                    return;
                }
                
                // start parsing photos we've found (this will dispatch to another bg thread)
                // pass nil as the deletionblock because we're not ready to delete any files yet
                // use a dispatch group for this so the final delete can wait on these finishing
                [self parsePhotos:photoFiles withDeletionBlock:nil andGroup:deletionWaitGroup];
                
                // clear out the list since these have been parsed (don't removeAllObjects because this will mutate the array we sent to the parser)
                photoFiles = [NSMutableArray new];
            }
            
            
        }
        
        // when we're done do a final parse that also deletes any leftover files
        
        // start parsing photos we've found (this will dispatch to another bg thread)
        [self parsePhotos:photoFiles withDeletionBlock:^(NSManagedObjectContext *context) {
            
            // make sure all other parsePhotos dispatches are done running before executing the deletes
            dispatch_group_wait(deletionWaitGroup, DISPATCH_TIME_FOREVER);
            
            // go through and delete any photos/albums that weren't updated and should have been
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dateLastUpdated == NULL || dateLastUpdated < %@", startScanTime, nil];
            
            // be sure to delete albums first so there are less photos to iterate through in the second delete
            if (![self deleteObjectsForEntityName:@"PIXAlbum" inContext:context withPredicate:predicate]) {
                DLog(@"There was a problem trying to delete old objects");
            }
            if (![self deleteObjectsForEntityName:@"PIXPhoto" inContext:context withPredicate:predicate]) {
                DLog(@"There was a problem trying to delete old objects");
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[PIXAppDelegate sharedAppDelegate] saveDBToDisk:nil];
                
                // use this flag so the deep scan will restart if the app closes half way through
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDeepScanIncompleteKey];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
                
                for(NSURL * aScopeURL in _sandboxScopeURLs)
                {
                    [aScopeURL stopAccessingSecurityScopedResource];
                }
                
//                double delayInSeconds = 1.2;
//                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//                    
//                    [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
//                    
//                });
                
            });

            self.fullScanProgress = 1.0;
        } andGroup:NULL];
        
        [self decrementWorking];
        
        
    });
}

/**
 * This method will scan a specific album for changed files
 * this will not go any deeper than the current album
 */
- (void)scanAlbum:(PIXAlbum *)album withRecursion:(PIXFileParserRecursionOptions)recursionMode
{
    [self scanURLForChanges:[NSURL fileURLWithPath:album.path isDirectory:YES] withRecursion:recursionMode];
}

- (void)scanPath:(NSString *)path withRecursion:(PIXFileParserRecursionOptions)recursionMode
{
    if(path)
    {
        [self scanURLForChanges:[NSURL fileURLWithPath:path isDirectory:YES] withRecursion:recursionMode];
    }
}

/** 
 *  This method will scan a specific path in a shallow manner.
 *  It will recurse to subdirectories only if it find's subdirectories
 *  that arent already in the database structure. It will also track
 *  current scans so new ones arent started
 */
- (void)scanURLForChanges:(NSURL *)url withRecursion:(PIXFileParserRecursionOptions)recursionMode
{
    // must do this at the begining of each new scan to reset context
    self.parseContext = nil;
    
    self.scansCancelledFlag = NO;
    [self incrementWorking];
    
    // if this path isn't already being scanned:
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //
        
        if(self.scansCancelledFlag)
        {
            [self decrementWorking];
            return;
        }
        
        //DLog(@"Doing a shallow scan of: %@", url.path);
        
        NSDirectoryEnumerator *dirEnumerator = nil;

        if([[NSFileManager defaultManager] fileExistsAtPath:url.path])
        {
            NSFileManager *localFileManager=[[NSFileManager alloc] init];
            
            NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles |
                                                    NSDirectoryEnumerationSkipsPackageDescendants |
                                                    NSDirectoryEnumerationSkipsSubdirectoryDescendants;
            
            // don't skip subdirectories if mode is full
            if(recursionMode == PIXFileParserRecursionFull)
            {
                options =   NSDirectoryEnumerationSkipsHiddenFiles |
                            NSDirectoryEnumerationSkipsPackageDescendants;
            }
            
            
            dirEnumerator = [localFileManager enumeratorAtURL:url
                                   includingPropertiesForKeys:@[NSURLNameKey,
                                                                NSURLIsDirectoryKey,
                                                                NSURLTypeIdentifierKey,
                                                                NSURLCreationDateKey,
                                                                NSURLContentModificationDateKey,
                                                                NSURLFileSizeKey]
                                                      options:options
                                                 errorHandler:^(NSURL *url, NSError *error) {
                                                                            return NO;
                                                                        }];
        }

        NSMutableArray *photoFiles = [NSMutableArray new];
        NSMutableArray *directories = [NSMutableArray new];
        NSURL *aURL;
        while (aURL = [dirEnumerator nextObject]) {
            
            // if this is an parsable file add it to the photofiles array to be parsed
            NSDictionary * info = dictionaryForURL(aURL);
            
            if(info != nil)
            {
                [photoFiles addObject:info];
            }
            
            // if this is a directory then add it to the directories array to be checked for recursion
            else if(recursionMode == PIXFileParserRecursionSemi)
            {
                NSNumber * isDirectoryValue;
                [aURL getResourceValue:&isDirectoryValue forKey:NSURLIsDirectoryKey error:nil];
                
                NSNumber * isPackage;
                [aURL getResourceValue:&isPackage forKey:NSURLIsPackageKey error:nil];
                
                if([isDirectoryValue boolValue] && ![isPackage boolValue])
                {
                    // add the path string value to the mutable array
                    [directories addObject:[aURL path]];
                }
                
            }
        }
        
        // add the unbound file of the main directory if it exists
        NSDictionary * info = dictionaryForURL(url);
        
        if(info != nil)
        {
            [photoFiles addObject:info];
        }
        
        if(self.scansCancelledFlag)
        {
            
            [self decrementWorking];
            return;
        }
        
        NSDate * startParseDate = [NSDate date];
        
        NSString * path = url.path;
        
        // start parsing photos we've found (this will dispatch to another bg thread)
        [self parsePhotos:photoFiles withDeletionBlock:^(NSManagedObjectContext *context) {
            
            // go through and delete any photos/albums that weren't updated and should have been
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path == %@ && (dateLastUpdated == NULL || dateLastUpdated < %@)", path, startParseDate, nil];
            
            // if we're doing a full recursion then we need use a different predicate
            if(recursionMode == PIXFileParserRecursionFull)
            {
                predicate = [NSPredicate predicateWithFormat:@"path CONTAINS %@ && (dateLastUpdated == NULL || dateLastUpdated < %@)", path, startParseDate, nil];
            }
            
            // be sure to delete albums first so there are less photos to iterate through in the second delete
            if (![self deleteObjectsForEntityName:@"PIXAlbum" inContext:context withPredicate:predicate]) {
                DLog(@"There was a problem trying to delete old objects");
            }
            
            predicate = [NSPredicate predicateWithFormat:@"album.path == %@ && (dateLastUpdated == NULL || dateLastUpdated < %@)",path, startParseDate, nil];
            
            // if we're doing a full recursion then we need use a different predicate
            if(recursionMode == PIXFileParserRecursionFull)
            {
                predicate = [NSPredicate predicateWithFormat:@"album.path CONTAINS %@ && (dateLastUpdated == NULL || dateLastUpdated < %@)",path, startParseDate, nil];
            }
            
            if (![self deleteObjectsForEntityName:@"PIXPhoto" inContext:context withPredicate:predicate]) {
                DLog(@"There was a problem trying to delete old objects");
            }
            
            /// check that all subfolders exist (deletion just give a notification that the parent folder changed)
            if(recursionMode != PIXFileParserRecursionFull)
            {
                if (![self checkSubfoldersExistanceInContext:context withPath:path])
                {
                    DLog(@"There was a problem trying to delete subfolder");
                }
            }
            
        } andGroup:NULL];
        
        if(recursionMode == PIXFileParserRecursionSemi)
        {
            // go through the directories we found and see if any are not already in the db
            NSArray * existingAlbums = [self albumsWithPaths:directories];
            
            // for each directory we found, remove it from the list
            for(NSDictionary * anAlbumDict in existingAlbums)
            {
                NSString * thisAlbumPath = [anAlbumDict objectForKey:@"path"];
                
                NSUInteger index = [directories indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    return [thisAlbumPath isEqualToString:(NSString *)obj];
                }];
                
                if(index != NSNotFound)
                {
                    [directories removeObjectAtIndex:index];
                }
            }
            
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // now go through the directories left over and start recursive shallow scans on them
                for(NSString * path in directories)
                {
                    [self scanURLForChanges:[NSURL fileURLWithPath:path] withRecursion:recursionMode];
                }
                
                [self.loadingAlbumsDict removeObjectForKey:url.path];
                
                
            });
        }
        
        
        
        // always go back and decrement the loading
        [self decrementWorking];
        
        [[PIXAppDelegate sharedAppDelegate] saveDBToDiskWithRateLimit];
        
    });
}


// this is a convenience method to parse a single file
-(void)scanFile:(NSURL *)fileURL
{
    // must do this at the begining of each new scan to reset context
    self.parseContext = nil;
    
    // add the unbound file of the main directory if it exists
    NSDictionary * info = dictionaryForURL(fileURL);
    
    // if this is a photo then parse it
    if(info != nil)
    {
        // parse a single photo, no need for  a deletion block
        [self parsePhotos:@[info] withDeletionBlock:^(NSManagedObjectContext *context) { } andGroup:nil];
    }
}

// this will delete a photo or directory from the db if it exists
-(void)deleteURL:(NSURL *)fileURL
{
    
    NSNumber * isDirectoryValue;
    [fileURL getResourceValue:&isDirectoryValue forKey:NSURLIsDirectoryKey error:nil];
    
    if([isDirectoryValue boolValue])
    {
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"path CONTAINS %@", fileURL.path, nil];

        NSManagedObjectContext * context = [[PIXAppDelegate sharedAppDelegate] threadSafeSideSaveMOC];
        // be sure to delete albums first so there are less photos to iterate through in the second delete
        if (![self deleteObjectsForEntityName:@"PIXAlbum" inContext:context withPredicate:predicate]) {
            DLog(@"There was a problem trying to delete old objects");
        }
        
        [context save:nil];
    }
    
    else
    {
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"path == %@", fileURL.path, nil];
        
        NSManagedObjectContext * context = [[PIXAppDelegate sharedAppDelegate] threadSafeSideSaveMOC];
        // be sure to delete albums first so there are less photos to iterate through in the second delete
        if (![self deleteObjectsForEntityName:@"PIXPhoto" inContext:context withPredicate:predicate]) {
            DLog(@"There was a problem trying to delete old objects");
        }
        
        [context save:nil];
    }

}


// this will fetch albums matching the nstring paths in the paths array
-(NSArray *)albumsWithPaths:(NSArray *)paths
{
    
    // create a thread-safe context (may want to make this a child context down the road)
    NSManagedObjectContext *context = [[PIXAppDelegate sharedAppDelegate] threadSafeSideSaveMOC];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PIXAlbum" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setPropertiesToFetch:@[@"path"]];
    [fetchRequest setResultType:NSDictionaryResultType];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path in %@", paths];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    return fetchedObjects;
    
}


#pragma mark - Methods for Parsing into Core Data



-(void)parsePhotos:(NSArray *)photos withDeletionBlock:(void(^)(NSManagedObjectContext * context))deletionBlock andGroup:(dispatch_group_t)dispatchGroup
{
    if(self.scansCancelledFlag) return;

    self.fullScanProgress = (float)self.fullScannProgressCurrent / (float)self.fullScannProgressTotal;
    
    // recored an initial fetch date to use when deleting items that weren't found
    __block NSDate * fetchDate = [NSDate date];
    
    [self incrementWorking];
    
    void (^dispatchBlock)(void) = ^(void) {
        // if the parse context has changed then this is an old parse that we're no longer using
        if(self.parseContext == nil)
        {
            self.parseContext = [[PIXAppDelegate sharedAppDelegate] threadSafeSideSaveMOC];
        }
        
        NSManagedObjectContext *context = self.parseContext;
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
    //dispatch_async([self sharedParsingQueue], ^(void) {
        
        // create a thread-safe context (may want to make this a child context down the road)
        
        // lastalbum will be used to cache the album fetch when looping through photos
        PIXAlbum *lastAlbum = nil;
        
        // i will be used to track the loop count and fire a save every 500 loops
        int i = 0;
        
        // lastAlbumPhotos is an array of new photos we have found that belong to lastAlbum
        NSMutableArray *lastAlbumsPhotos = [NSMutableArray new];
        
        // lastAlbumsExistingPhotos is an array of the existing photos in lastAlbum.
        // They will be removed from this array as they're matched
        NSMutableArray *lastAlbumsExistingPhotos = [NSMutableArray new];
        
        // editedAlbumObjectIDs will store objectID's of albums we've edited so we can loop through and flush them on the main thread later
        NSMutableSet * editedAlbumObjectIDs = [NSMutableSet new];
        
        // loop through the array of photo filesystem dictionaries
        for (NSDictionary *aPhoto in photos)
        {
            i++;
            
            self.fullScannProgressCurrent++;
            
            // aPath is the path of this photos album
            NSString *aPath = [aPhoto valueForKey:@"dirPath"];
            
            // if lastAlbum isn't already this photos's album then we'll need to fetch or create it
            if (!lastAlbum || ![aPath isEqualToString:lastAlbum.path])
            {
                // we had a previous album we were adding photos to. Combine the photos and save them
                // (setting photos as a batch is faster than one at a time)
                if (lastAlbum) {
                    // combine the new photos we found with the albums previous existing photos
                    [lastAlbumsPhotos addObjectsFromArray:lastAlbumsExistingPhotos];
                    // set the photos at once - this method will update the stackPhotos relationship as well
                    [lastAlbum setPhotos:[NSSet setWithArray:lastAlbumsPhotos] updateCoverImage:YES];
                }
                
                // try to fetch an existing album with the new photos path
                lastAlbum = [self fetchAlbumWithPath:aPath inContext:context];
                
                // if we didn't find an existing album then we need to create it
                if (lastAlbum==nil)
                {
                    lastAlbum = [NSEntityDescription insertNewObjectForEntityForName:@"PIXAlbum" inManagedObjectContext:context];
                    [lastAlbum setValue:aPath forKey:@"path"];
                }
                
                else
                {
                    // store the objectID's of any albums we change so we can go through and update them on the main thread later
                    [editedAlbumObjectIDs addObject:[lastAlbum objectID]];
                }
                
                // we're starting a freshly found/created album so clear this array
                [lastAlbumsPhotos removeAllObjects];
                
                // set the date last Updated so this album is marked to not be deleted
                [lastAlbum setDateLastUpdated:fetchDate];
                
                // sethi the existing photos array to the current photos in the album
                lastAlbumsExistingPhotos = [[lastAlbum sortedPhotos] mutableCopy];
            }
            
            // if this is a .unbound file than no need to create a photo object
            if([aPhoto objectForKey:kIsUnboundFileKey] != nil)
            {
                //set the album date to to the creation date of the unbound file if needed
                if([lastAlbum albumDate] == nil)
                {
                    [lastAlbum setAlbumDate:[aPhoto objectForKey:kCreatedKey]];
                }
                
            }
            
            // this is a photo. Create the object in the db
            else
            {
                // now iterate throuhg the album's existing photos and see if this photo is already in core data
                __block PIXPhoto *dbPhoto = nil;
                NSUInteger index = [lastAlbumsExistingPhotos indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    if ([[obj valueForKey:@"path"] isEqualToString:[aPhoto valueForKey:@"path"]])
                    {
                        // we found the photo
                        dbPhoto = obj;
                        return YES;
                    }
                    return NO;
                }];
                
                if([dbPhoto isReallyDeleted])
                {
                    dbPhoto = nil;
                }
                
                // if we didn't find the photo we'll need to create a new entity
                if(dbPhoto==nil)
                {
                    dbPhoto = [NSEntityDescription insertNewObjectForEntityForName:@"PIXPhoto" inManagedObjectContext:context];
                }
                
                // if we found the photo, remove it from the album's existing photos
                if (index != NSNotFound) {
                    [lastAlbumsExistingPhotos removeObjectAtIndex:index];
                }
                
                [self setupPhoto:dbPhoto withFileInfo:aPhoto];
                
                
                // set this date so this photo won't be deleted
                [dbPhoto setDateLastUpdated:fetchDate];
                
                // add the photos to the array of found photos for this album
                [lastAlbumsPhotos addObject:dbPhoto];
                
                // update the progress bar every 100 items
                if(i%100==0)
                {
                    self.fullScanProgress = (float)self.fullScannProgressCurrent / (float)self.fullScannProgressTotal;
                }
                
                // save the context and send a UI update notification every 500 loops
                if (i%500==0) {
                    
                    [context save:nil];
                    
                    // update flush albums and the UI with a notification
                    // use performSelector instead of dispatch async because it's faster
                    [self performSelectorOnMainThread:@selector(flushAlbumsWithIDs:) withObject:[editedAlbumObjectIDs copy] waitUntilDone:NO];
                    
                    // we've flushed these already so clear them out
                    [editedAlbumObjectIDs removeAllObjects];
                    
                    // add the last one back in because we're still working with it
                    [editedAlbumObjectIDs addObject:[lastAlbum objectID]];
                }
            }
        }
        
        // we've finished the loop. add the photos objects to the last album we were working with
        [lastAlbumsPhotos addObjectsFromArray:lastAlbumsExistingPhotos];
        [lastAlbum setPhotos:[NSSet setWithArray:lastAlbumsPhotos] updateCoverImage:YES];

        //NSLog(@"scanned album %@ has %ld items", lastAlbum.title, lastAlbum.photos.count);
        
        if(deletionBlock)
        {
            deletionBlock(context);
        }
        
        // save the context
        [context save:nil];
        
        
        
        // update flush albums and the UI with a notification
        // use performSelector instead of dispatch async because it's faster
        [self performSelectorOnMainThread:@selector(flushAlbumsWithIDs:) withObject:[editedAlbumObjectIDs copy] waitUntilDone:NO];
        
        self.fullScanProgress = (float)self.fullScannProgressCurrent / (float)self.fullScannProgressTotal;
 
        [self decrementWorking];
    };
    
    
    if(dispatchGroup == NULL)
    {
        dispatch_async([self sharedParsingQueue], dispatchBlock);
    }
    
    else
    {
        dispatch_group_async(dispatchGroup, [self sharedParsingQueue], dispatchBlock);
    }
    
}

-(void)setupPhoto:(PIXPhoto *)photo withFileInfo:(NSDictionary *)fileInfo
{
    // set some basic attributes on the photo
    [photo setDateCreated:[fileInfo objectForKey:kCreatedKey]];
    [photo setPath:[fileInfo objectForKey:kPathKey]];
    [photo setName:[fileInfo objectForKey:kNameKey]];
    [photo setFileSize:[fileInfo objectForKey:kFileSizeKey]];
    
    NSDate * dateModified = [fileInfo objectForKey:kModifiedKey];
    
    
    // if this was modified since the last time we looked at it then we need to clear some data
    if([photo dateLastModified] != nil && [[photo dateLastModified] compare:dateModified] == NSOrderedAscending)
    {
        
        [photo clearFiles];
        [photo setExifData:nil];
        
        NSManagedObjectID * objectID = [photo objectID];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSManagedObjectContext * mainThreadContext = [[PIXAppDelegate sharedAppDelegate] managedObjectContext];
            PIXPhoto * mainThreadPhoto = (PIXPhoto *)[mainThreadContext objectWithID:objectID];
            
            if(mainThreadPhoto && ![mainThreadPhoto isReallyDeleted])
            {
            
                [mainThreadPhoto setThumbnailImage:nil];
                [mainThreadPhoto clearFiles];
                [mainThreadPhoto setExifData:nil];
                [mainThreadPhoto setFullsizeImage:nil];
                
                [mainThreadPhoto postPhotoUpdatedNote];
            }
            
        });
        

        
        
    }
        
    // set the date modified
    [photo setDateLastModified:dateModified];
    
}

-(NSArray *)fetchAlbumsWithPaths:(NSArray *)paths
{
    NSManagedObjectContext * context = [[PIXAppDelegate sharedAppDelegate] managedObjectContext];
    return [self fetchItemsWithPaths:paths inContext:context withEntityName:kAlbumEntityName];
}

-(NSArray *)fetchPhotosWithPaths:(NSArray *)paths
{
    NSManagedObjectContext * context = [[PIXAppDelegate sharedAppDelegate] managedObjectContext];
    return [self fetchItemsWithPaths:paths inContext:context withEntityName:kPhotoEntityName];
}

-(NSArray *)fetchItemsWithPaths:(NSArray *)paths inContext:(NSManagedObjectContext *)context withEntityName:(NSString *)entityName
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path IN %@", paths];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        //
    }
    
    return fetchedObjects;
}

-(PIXAlbum *)fetchAlbumWithPath:(NSString *)aPath inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PIXAlbum" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path == %@", aPath];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit:1];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        //
    }
    
    return [fetchedObjects lastObject];
}


// this should always be called on the main thread
-(void)flushAlbumsWithIDs:(NSSet *)albumIDS
{
    NSManagedObjectContext * context = [[PIXAppDelegate sharedAppDelegate] managedObjectContext];

    // fetch any the albums with these ids
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kAlbumEntityName];
    [fetchRequest setPredicate: [NSPredicate predicateWithFormat: @"(self IN %@)", albumIDS]];

    NSError * error;
    NSArray * editedAlbums = [context executeFetchRequest:fetchRequest error:&error];
    for(PIXAlbum * album in editedAlbums)
    {
        [album flush];
        //NSLog(@"flushed album %@ has %ld items", album.title, album.photos.count);
    }
   
    
   // NSNotification *albumNotification = [NSNotification notificationWithName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
    //[[NSNotificationQueue defaultQueue] enqueueNotification:albumNotification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil userInfo:nil];
    });
    
     
}

-(BOOL)deleteObjectsForEntityName:(NSString *)entityName inContext:(NSManagedObjectContext *)context withPredicate:(NSPredicate *)predicate
{
    BOOL isPhotoEntity = NO;
    if ([entityName isEqualToString:kPhotoEntityName])
    {
        isPhotoEntity = YES;
    }
    
    /*
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dateLastUpdated == NULL || dateLastUpdated < %@", lastUpdated, nil];
    if (path!=nil) {
        if (isPhotoEntity) {
            predicate = [NSPredicate predicateWithFormat:@"album.path == %@ && (dateLastUpdated == NULL || dateLastUpdated < %@)",path, lastUpdated, nil];
        } else {
            
            predicate = [NSPredicate predicateWithFormat:@"path == %@ && (dateLastUpdated == NULL || dateLastUpdated < %@)", path, lastUpdated, nil];
        }
    }*/
    
    
    NSFetchRequest *fetchRequestRemoval = [[NSFetchRequest alloc] initWithEntityName:entityName];
    // make sure the results are sorted as well
    [fetchRequestRemoval setPredicate:predicate];

    NSError * anError;
    NSArray *itemsToDelete = [context executeFetchRequest:fetchRequestRemoval error:&anError];
    //DLog(@"Deleting %ld items of entity type %@", itemsToDelete.count, entityName);
    
    if (itemsToDelete==nil) {
        //DLog(@"Unresolved error %@, %@", anError, [anError userInfo]);
#ifdef DEBUG
        [[NSApplication sharedApplication] presentError:anError];
#endif
        return NO;
    }
    
    
    if ([itemsToDelete count]>0) {
        //DLog(@"Deleting %ld items that are no longer in the feed", [itemsToDelete count]);
        NSMutableSet *albumsChanged = [NSMutableSet set];
        // delete any albums that are no longer in the feed
        for (id anItemToDelete in itemsToDelete)
        {
            //DLog(@"Deleting item %@ with a dateLastUpdated of %@ which should be after %@", anItemToDelete, [anItemToDelete dateLastUpdated], lastUpdated);
            if (isPhotoEntity) {
                PIXPhoto *aPhoto = (PIXPhoto *)anItemToDelete;
                if (aPhoto.album == nil) {
                    //NSAssert(aPhoto.album, @"Photo should not have album already");
                    DLog(@"Photo should have album");
                    continue;
                }
                [albumsChanged addObject:aPhoto.album];
                
                [context deleteObject:anItemToDelete];
            }
            
            // for albums, only delete them if they don't still exist in the file system
            else
            {
                NSFileManager * fm = [NSFileManager defaultManager];
                if (![fm fileExistsAtPath:[(PIXAlbum *)anItemToDelete path]])
                {
                    [context deleteObject:anItemToDelete];
                }
            }
            
        }
        if (isPhotoEntity) {
            for (PIXAlbum *anAlbum in albumsChanged)
            {
                //[anAlbum updateAlbumBecausePhotosDidChange];
                [[PIXFileParser sharedFileParser] scanPath:anAlbum.path withRecursion:PIXFileParserRecursionNone];
            }
        }
    }
    
    return YES;
}

-(BOOL)checkSubfoldersExistanceInContext:(NSManagedObjectContext *)context withPath:(NSString *)path
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path CONTAINS %@", path, nil];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kAlbumEntityName];
    // make sure the results are sorted as well
    [fetchRequest setPredicate:predicate];
    
    NSError * anError;
    NSArray *albumsToCheck = [context executeFetchRequest:fetchRequest error:&anError];
    
    
    for(PIXAlbum * anAlbum in albumsToCheck)
    {
        if([[NSFileManager defaultManager] fileExistsAtPath:anAlbum.path] == NO)
        {
            [context deleteObject:anAlbum];
        }
        
    }
    
    return YES;
}


#pragma mark - Lazy Loaders



-(NSArray<NSURL *> *) observedDirectories
{
    if (_observedDirectories==nil) {
        
        // pull the observed directories from the NSUserDefaults
        
        NSArray * bookmarkArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"PIX_ObservedDirectoriesKey"];
        
        
        // if we have not observed directories in the settings then we need the user to pick some...
        if([bookmarkArray count] == 0)
        {
            _observedDirectories = nil;
        }
        
        // otherwise loop through and create NSUrls from the strings
        else
        {
            NSMutableArray<NSURL *> * urlArray = [NSMutableArray new];
            
            for(NSData * bookmark in bookmarkArray)
            {
                if([bookmark isKindOfClass:[NSData class]])
                {
                    BOOL stale = NO;
                    NSError * error = nil;
                    NSURL * url = [NSURL URLByResolvingBookmarkData:bookmark
                                                            options:0 // these arent security scoped. thats what sandboxScopeURLs are for
                                                      relativeToURL:nil
                                                bookmarkDataIsStale:&stale
                                                              error:&error];
                    
                    if(stale)
                    {
                        NSLog(@"Error creating url from saved bookmark. Bookmark is stale.");
                    }
                    
                    if(url && !error && !stale)
                    {
                        [urlArray addObject:url];
                    }
                }
            }
            
            _observedDirectories = urlArray;
            return _observedDirectories;
        }
    }
    
    return _observedDirectories;
}

-(void)setObservedURLs:(NSArray *)direcoryURLs
{
    NSMutableArray * pathArray = [NSMutableArray new];
    
    for(NSURL * url in direcoryURLs)
    {
        
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:&isDir] && isDir) {
            
            NSError * error = nil;
            NSData * bookMarkData =  [url bookmarkDataWithOptions:0 // these arent security scoped. thats what sandboxScopeURLs are for
                                   includingResourceValuesForKeys:nil
                                                    relativeToURL:nil
                                                            error:&error];
            
            if(bookMarkData && error == nil)
            {
                [pathArray addObject:bookMarkData];
            }
            
            else
            {
                NSLog(@"Error creating security scoped bookmark: %@", error);
            }
        } else {
            DLog(@"Can't observe file URL, either it doesn't exist or is not a directory : %@", url);
        }
        
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:pathArray forKey:@"PIX_ObservedDirectoriesKey"];
    self.sandboxScopeURLs = nil;
}


// we need these to be seperate from observedURLS because if the user chooses the dropbox subfolders option the security scoped url doesn't pass through to subfolders
-(NSArray *) sandboxScopeURLs
{
    if (_sandboxScopeURLs == nil) {
        
        // pull the observed directories from the NSUserDefaults
        
        NSArray * bookmarkArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"PIX_SandboxBookmarksKey"];
        
        
        // if we have not observed directories in the settings then we need the user to pick some...
        if([bookmarkArray count] == 0)
        {
            _sandboxScopeURLs = nil;
        }
        
        // otherwise loop through and create NSUrls from the strings
        else
        {
            NSMutableArray * urlArray = [NSMutableArray new];
            
            BOOL bookMarksWereStale = NO;
            
            for(NSData * bookmark in bookmarkArray)
            {
                if([bookmark isKindOfClass:[NSData class]])
                {
                    BOOL stale = NO;
                    NSError * error = nil;
                    NSURL * url = [NSURL URLByResolvingBookmarkData:bookmark
                                                            options:NSURLBookmarkResolutionWithSecurityScope
                                                      relativeToURL:nil
                                                bookmarkDataIsStale:&stale
                                                              error:&error];
                    
                    if(stale)
                    {
                        NSLog(@"Error creating url from saved bookmark. Bookmark is stale.");
                        bookMarksWereStale = YES;
                    }
                    
                    if(url && !error)
                    {
                        [urlArray addObject:url];
                    }
                }
                
                // if any of the bookmarks were stale then update the saved bookmarks using the more recent urls
                if(bookMarksWereStale)
                {
                    [self setSandboxScopeURLs:urlArray];
                }
            }
            
            _sandboxScopeURLs = urlArray;
            return _sandboxScopeURLs;
        }
    }
    
    return _sandboxScopeURLs;
}

-(void)setSandboxScopeURLs:(NSArray *)sandboxScopeURLs
{
    NSMutableArray * bookmarkArray = [NSMutableArray new];
    
    for(NSURL * url in sandboxScopeURLs)
    {
        
        [url startAccessingSecurityScopedResource];
        
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:&isDir] && isDir) {
            
            NSError * error = nil;
            NSData * bookMarkData =  [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                   includingResourceValuesForKeys:nil
                                                    relativeToURL:nil
                                                            error:&error];
            
            if(bookMarkData && error == nil)
            {
                [bookmarkArray addObject:bookMarkData];
            }
            
            else
            {
                NSLog(@"Error creating security scoped bookmark: %@", error);
            }
            
        } else {
            DLog(@"Can't observe file URL, either it doesn't exist or is not a directory : %@", url);
        }
        
        [url stopAccessingSecurityScopedResource];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:bookmarkArray forKey:@"PIX_SandboxBookmarksKey"];
    self.observedDirectories = nil;
}

-(NSURL *) defaultDBFolder
{
    NSString *dropboxHomePath = aDefaultDropBoxDirectory();
    NSURL *rootFilePathURL = [NSURL fileURLWithPath: [NSString stringWithFormat:@"%@/Photos", dropboxHomePath]];
    
    return rootFilePathURL;
}

-(NSURL *) defaultDBCameraUploadsFolder
{
    NSString *dropboxHomePath = aDefaultDropBoxDirectory();
    NSURL *cameraUploadsLocation = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/Camera Uploads", dropboxHomePath]];
    
    return cameraUploadsLocation;
}

-(NSMutableDictionary *)pendingFolderScanPaths
{
    if(_pendingFolderScanPaths) return _pendingFolderScanPaths;
    
    
    _pendingFolderScanPaths = [NSMutableDictionary new];
    
    return _pendingFolderScanPaths;
}


#pragma mark - 
#pragma ui helpers for init and settings screens

//-(BOOL)checkReadWriteAccess:(NSURL *)filePathURL
//{
//    NSString *filePath = filePathURL.path;
//    if (!filePath.length ||
//        (access([filePath UTF8String], W_OK) != 0) ||
//        (access([filePath UTF8String], R_OK) != 0)) {
//            DLog(@"There's a problem with the file permissions on the new root folder : %@", filePathURL);
//            return NO;
//    }
//    return YES;
//        
//}

-(NSArray *) mountedVolumesInfo
{
    NSWorkspace   *ws = [NSWorkspace sharedWorkspace];
    NSArray     *vols = [ws mountedLocalVolumePaths];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSMutableArray *volumeInfos = [NSMutableArray arrayWithCapacity:[vols count]];
    
    for (NSString *path in vols)
    {
        NSDictionary* fsAttributes;
        NSString *description, *type, *name;
        BOOL removable, writable, unmountable, res;
        NSNumber *size;
        
        res = [ws getFileSystemInfoForPath:path
                               isRemovable:&removable
                                isWritable:&writable
                             isUnmountable:&unmountable
                               description:&description
                                      type:&type];
        if (!res) continue;
        NSError * error = nil;
        fsAttributes = [fm attributesOfFileSystemForPath:path error:&error];
        name         = [fm displayNameAtPath:path];
        size         = [fsAttributes objectForKey:NSFileSystemSize];
        
        DLog(@"path=%@\nname=%@\nremovable=%d\nwritable=%d\nunmountable=%d\n"
              "description=%@\ntype=%@, size=%@\n\n",
              path, name, removable, writable, unmountable, description, type, size);
        NSDictionary *aVolumeInfoDict = @{@"path" : path,
                                          @"name" : name,
                                          @"removable" : [NSNumber numberWithBool:removable],
                                          @"writable" : [NSNumber numberWithBool:writable],
                                          @"unmountable" : [NSNumber numberWithBool:unmountable],
                                          @"description" : description, @"type" : type, @"size" : size, @"fsAttributes" : fsAttributes};
        [volumeInfos addObject:aVolumeInfoDict];
    }
    return volumeInfos;
}

-(BOOL)checWriteAccess:(NSURL *)filePathURL
{
    NSString *filePath = filePathURL.path;
    if (access([filePath UTF8String], W_OK) != 0) {
        DLog(@"No write to file permissions on the new root folder : %@", filePathURL);
        return NO;
    }
    return YES;
    
}

-(BOOL)userChooseFolderDialog
{
    // Create the File Open Dialog class.
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    
    [openPanel setCanCreateDirectories:YES];
    //[openPanel setDirectoryURL:[NSURL fileURLWithPath:@"~/"]];
    
    NSInteger result = [openPanel runModal];
    
    if(result == NSFileHandlingPanelOKButton && [[openPanel URLs] count] == 1)
    {
        NSURL *selectedURL = [[openPanel URLs] lastObject];
        if (![self checWriteAccess:selectedURL]) {
#ifdef DEBUG
            [self mountedVolumesInfo];
#endif
            NSString *warningMessage = [NSString stringWithFormat:@"The root folder you selected is read-only which may prevent some app features from functioning properly. Continue with this folder anyway?"];
            if (NSRunAlertPanel(@"Read & Write Permissions Are Required", warningMessage, @"OK", @"Cancel", nil) == NSAlertDefaultReturn) {
                //User selected to continue with this folder - do nothing
            } else {
                //If user cancels go back to the preferenes view without making a change
                return NO;
            }
        }
        
        NSArray * urls = @[selectedURL];
        [selectedURL startAccessingSecurityScopedResource];
        
        // Check if the user chose a dropbox folder where we should only use the Photos and Camera Uploads subfolders
        if([[selectedURL lastPathComponent] isEqualToString:@"Dropbox"])
        {
            
            
            NSArray * dropboxURLS = @[[selectedURL URLByAppendingPathComponent:@"Photos"],
                                      [selectedURL URLByAppendingPathComponent:@"Camera Uploads"]];
            
            BOOL urlsExist = YES;
            
            for(NSURL * aURL in dropboxURLS)
            {
                BOOL isDir = NO;
                if (![[NSFileManager defaultManager] fileExistsAtPath:aURL.path isDirectory:&isDir] || !isDir)
                {
                    urlsExist = NO;
                }
            }
            
            
            
            // if all the urls are good, ask the user if we should use the subfolders
            if(urlsExist)
            {
                NSString *message = [NSString stringWithFormat:@"You've selected your Dropbox folder for your photos. Would you like Unbound to scan just the Photos and Camera Uploads subfolders? This matches the default configuration of Unbound for iPhone and iPad."];
                if (NSRunAlertPanel(@"Use Photos and Camera Uploads Folder?", message, @"Use Subfolders", @"Use entire Dropbox folder", nil) == NSAlertDefaultReturn) {
                    urls = dropboxURLS;
                }
            }
        }
        
        
        [[PIXAppDelegate sharedAppDelegate] showMainWindow:nil];
        
        // use this flag so the deep scan will restart if the app crashes half way through
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDeepScanIncompleteKey];
        
        [self stopObserving];
        
        [self setObservedURLs:urls];
        [self setSandboxScopeURLs:@[selectedURL]]; // s
        
        [selectedURL stopAccessingSecurityScopedResource];
        
        [[PIXAppDelegate sharedAppDelegate] clearDatabase];
        
        [self scanFullDirectory];
        
        for(NSURL * pathURL in self.observedDirectories)
        {
            NSString *tokenKeyString = [NSString stringWithFormat:@"resumeToken-%@", pathURL.path];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:tokenKeyString];
        }
        
        [self startObserving];
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kAppFirstRun];
        
        return YES;
    }
    
    return NO;
}

-(void)rescanFiles
{
    // use this flag so the deep scan will restart if the app crashes half way through
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDeepScanIncompleteKey];
    
    //[[PIXAppDelegate sharedAppDelegate] clearDatabase];
    [[PIXFileParser sharedFileParser] scanFullDirectory];
    
    [[PIXFileParser sharedFileParser] stopObserving];
    
    for(NSURL * pathURL in self.observedDirectories)
    {
        NSString *tokenKeyString = [NSString stringWithFormat:@"resumeToken-%@", pathURL.path];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:tokenKeyString];
    }
    
    [[PIXFileParser sharedFileParser] startObserving];
}

@end
