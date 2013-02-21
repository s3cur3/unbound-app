//
//  PIXFileParser.m
//  UnboundApp
//
//  Created by Scott Sykora on 2/20/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXFileParser.h"
#import "PIXAppDelegate.h"
#import "PIXDefines.h"
#import "PIXAlbum.h"
#import "PIXPhoto.h"

#import "ArchDirectoryObservationCenter.h"
#import "NSURL+DirectoryObserver.h"

#include <sys/types.h>
#include <pwd.h>

@interface PIXFileParser () <ArchDirectoryObserver>

@property (nonatomic,strong) NSDate *startDate;
@property (nonatomic, strong) NSMutableDictionary *loadingAlbumsDict;

@property BOOL scansCancelledFlag;

@end

@implementation PIXFileParser



- (dispatch_queue_t)sharedParsingQueue
{
    static dispatch_queue_t _sharedParsingQueue = 0;
    
    static dispatch_once_t onceTokenParsingQueue;
    dispatch_once(&onceTokenParsingQueue, ^{
        _sharedParsingQueue  = dispatch_queue_create("com.pixite.ub.parsingQueue", 0);
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
NSString * aUserHomeDirectory()
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
    NSString *dropBoxHome =[aUserHomeDirectory() stringByAppendingPathComponent:@"Dropbox/"];
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
        isImageFile = UTTypeConformsTo((__bridge CFStringRef)utiValue, kUTTypeImage);
    }
    
    if(isImageFile)
    {
        NSDate *fileCreationDate;
        [url getResourceValue:&fileCreationDate forKey:NSURLCreationDateKey error:nil];
        
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                              [url lastPathComponent], kNameKey,
                              [url path], kPathKey,
                              [[url URLByDeletingLastPathComponent] path] , kDirectoryPathKey,
                              fileCreationDate, kCreatedKey,
                              nil];
        
        return info;
        
    }
    
    return nil;
}

#pragma mark - File System Change Oberver Methods

-(void)startObserving
{
    // remove any observers, we only do this one
    [NSURL removeObserverForAllDirectories:self];
    
    DLog(@"** STARTING FILE SYSTEM OBSERVATION **");
    for (NSURL *aDir in [self observedDirectories])
    {
        NSString *tokenKeyString = [NSString stringWithFormat:@"resumeToken-%@", aDir.path];
        NSData *token = [[NSUserDefaults standardUserDefaults] dataForKey:tokenKeyString];
        NSData *decodedToken = [NSKeyedUnarchiver unarchiveObjectWithData:token];
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
    [NSURL removeObserverForAllDirectories:self];
}


// At least one file in the directory indicated by changedURL has changed.  You should examine the directory at changedURL to see which files changed.
// observedURL: the URL of the dorectory you're observing.
// changedURL: the URL of the actual directory that changed. This could be a subdirectory.
// historical: if YES, the event occured sometime before the observer was added.  If NO, it occurred just now.
// resumeToken: the resume token to save if you want to pick back up from this event.
- (void)observedDirectory:(NSURL*)observedURL childrenAtURLDidChange:(NSURL*)changedURL historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken
{
    // update the resume token
    [self updateResumeToken:resumeToken forObservedDirectory:observedURL];
    
    // do a shallow, semi-recursive scan of the directory
    [self scanURLForChanges:changedURL];
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if(self.scansCancelledFlag) return;
        
        NSDate * startScanTime = [NSDate date];
        
        NSMutableArray *photoFiles = [NSMutableArray new];
        NSArray * enumerators = [self recursiveEnumeratorsForRootDirectories];
        
        
        // loop through each of the enumerators (there can be more than one)
        for(NSDirectoryEnumerator * dirEnumerator in enumerators)
        {
            // loop through each item in each enumerator
            NSURL *aURL = nil;
            while (aURL = [dirEnumerator nextObject]) {
                
                // if this is an parsable file add it to the photofiles array to be parsed
                NSDictionary * info = dictionaryForURL(aURL);
                
                if(info != nil)
                {
                    [photoFiles addObject:info];
                }
            }
            
            // check the photoFiles count. When it goes above a threshhold
            // send it off to the parser to start parsing them at the same time
            if([photoFiles count] > 1500)
            {
                if(self.scansCancelledFlag) return;
                
                // start parsing photos we've found (this will dispatch to another bg thread)
                // pass nil as the deletionblock because we're not ready to delete any files yet
                [self parsePhotos:photoFiles withDeletionBlock:nil];
                
                // clear out the list since these have been parsed (don't removeAllObjects because this will mutate the array we sent to the parser)
                photoFiles = [NSMutableArray new];
            }
            
            
        }
        
        // when we're done do a final parse that also deletes any leftover files
        
        // start parsing photos we've found (this will dispatch to another bg thread)
        [self parsePhotos:photoFiles withDeletionBlock:^(NSManagedObjectContext *context) {
            
            // go through and delete any photos/albums that weren't updated and should have been
            
            // be sure to delete albums first so there are less photos to iterate through in the second delete
            if (![self deleteObjectsForEntityName:@"PIXAlbum" withUpdateDateBefore:startScanTime inContext:context withPath:nil]) {
                DLog(@"There was a problem trying to delete old objects");
            }
            if (![self deleteObjectsForEntityName:@"PIXPhoto" withUpdateDateBefore:startScanTime inContext:context withPath:nil]) {
                DLog(@"There was a problem trying to delete old objects");
            }
            
            
        }];
        
        
    });
}

/**
 * This method will scan a specific album for changed files
 * this will not go any deeper than the current album
 */
- (void)shallowScanAlbum:(PIXAlbum *)url
{
    self.scansCancelledFlag = NO;
    
    // TODO: Implement this
}

/** 
 *  This method will scan a specific path in a shallow manner.
 *  It will recurse to subdirectories only if it find's subdirectories
 *  that arent already in the database structure. It will also track
 *  current scans so new ones arent started
 */
- (void)scanURLForChanges:(NSURL *)url
{
    self.scansCancelledFlag = NO;
    
    // if this path isn't already being scanned:
    if (url.path != nil && [self.loadingAlbumsDict objectForKey:url.path]==nil) {
        [self.loadingAlbumsDict setObject:url forKey:url.path];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //
            
            //DLog(@"Doing a shallow scan of: %@", url.path);
            
            NSDirectoryEnumerator *dirEnumerator = [self nonRecursiveEnumeratorForURL:url];
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
                else
                {
                    NSNumber * isDirectoryValue;
                    [aURL getResourceValue:&isDirectoryValue forKey:NSURLIsDirectoryKey error:nil];
                    
                    if([isDirectoryValue boolValue])
                    {
                        // add the path string value to the mutable array
                        [directories addObject:[aURL path]];
                    }
                    
                }
            }
            
            if(self.scansCancelledFlag)
            {
                return;
            }
            
            NSDate * startParseDate = [NSDate date];
            
            NSString * path = url.path;
            
            // start parsing photos we've found (this will dispatch to another bg thread)
            [self parsePhotos:photoFiles withDeletionBlock:^(NSManagedObjectContext *context) {
                
                // go through and delete any photos/albums that weren't updated and should have been
                
                // be sure to delete albums first so there are less photos to iterate through in the second delete
                if (![self deleteObjectsForEntityName:@"PIXAlbum" withUpdateDateBefore:startParseDate inContext:context withPath:path]) {
                    DLog(@"There was a problem trying to delete old objects");
                }
                if (![self deleteObjectsForEntityName:@"PIXPhoto" withUpdateDateBefore:startParseDate inContext:context withPath:path]) {
                    DLog(@"There was a problem trying to delete old objects");
                }
                
                /// check that all subfolders exist (deletion just give a notification that the parent folder changed)
                
                if (![self checkSubfoldersExistanceInContext:context withPath:path])
                {
                    DLog(@"There was a problem trying to delete subfolder");
                }
                
            }];
            
            
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
                    [self scanURLForChanges:[NSURL fileURLWithPath:path]];
                }
                
                [self.loadingAlbumsDict removeObjectForKey:url.path];
            });
        });
        
    }
    
}

-(NSArray *)recursiveEnumeratorsForRootDirectories
{
    NSMutableArray * enumerators = [NSMutableArray new];
    
    
    for(NSURL * aURL in self.observedDirectories)
    {
    
        if([[NSFileManager defaultManager] fileExistsAtPath:aURL.path])
        {
        
            NSFileManager *localFileManager=[[NSFileManager alloc] init];
            NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants;
            NSDirectoryEnumerator *dirEnumerator = [localFileManager enumeratorAtURL:aURL
                                                          includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey,
                                                                                      NSURLIsDirectoryKey,NSURLTypeIdentifierKey,NSURLCreationDateKey, NSURLAttributeModificationDateKey,nil]
                                                                             options:options
                                                                        errorHandler:^(NSURL *url, NSError *error) {
                                                                            // Handle the error.
                                                                            [PIXAppDelegate presentError:error];
                                                                            // Return YES if the enumeration should continue after the error.
                                                                            return NO;
                                                                        }];
            
            [enumerators addObject:dirEnumerator];
        }
    }
    
    return enumerators;
}

-(NSDirectoryEnumerator *)nonRecursiveEnumeratorForURL:(NSURL *)url
{
    if(![[NSFileManager defaultManager] fileExistsAtPath:url.path]) return nil;
    
    NSFileManager *localFileManager=[[NSFileManager alloc] init];
    NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants;
    NSDirectoryEnumerator *dirEnumerator = [localFileManager enumeratorAtURL:url
                                                  includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey,
                                                                              NSURLIsDirectoryKey,NSURLTypeIdentifierKey,NSURLCreationDateKey, NSURLAttributeModificationDateKey,nil]
                                                                     options:options
                                                                errorHandler:^(NSURL *url, NSError *error) {
                                                                    // Handle the error.
                                                                    //[PIXAppDelegate presentError:error];
                                                                    // Return YES if the enumeration should continue after the error.
                                                                    return NO;
                                                                }];
    
    return dirEnumerator;
}

// this will fetch albums matching the nstring paths in the paths array
-(NSArray *)albumsWithPaths:(NSArray *)paths
{
    
    // create a thread-safe context (may want to make this a child context down the road)
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
    [context setUndoManager:nil];
    
    //set it to the App Delegates persistant store coordinator
    [context setPersistentStoreCoordinator:[[PIXAppDelegate sharedAppDelegate] persistentStoreCoordinator]];
    
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


-(void)parsePhotos:(NSArray *)photos withDeletionBlock:(void(^)(NSManagedObjectContext * context))deletionBlock
{
    // i'm going to disable this sort for now. I think the enumerators give us photos in a reasonable order and the method is robust enough to handle out-of-order arrays. --scott
    //self.photoFiles = [photos sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES]]];
    
    // recored an initial fetch date to use when deleting items that weren't found
    __block NSDate * fetchDate = [NSDate date];
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
    dispatch_async([self sharedParsingQueue], ^(void) {
        PIXAppDelegate *appDelegate = (PIXAppDelegate *)[[NSApplication sharedApplication] delegate];
        
        // create a thread-safe context (may want to make this a child context down the road)
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
        
        // try the parent child relationship
        /*NSManagedObjectContext *context = [[NSManagedObjectContext alloc]
                                           initWithConcurrencyType:NSConfinementConcurrencyType];
        
        
        [context setParentContext:[appDelegate managedObjectContext]];*/
        
        //-------------------------------------------------------
        //    Setting the undo manager to nil means that:
        //
        //    - You don’t waste effort recording undo actions for changes (such as insertions) that will not be undone;
        //    - The undo manager doesn’t maintain strong references to changed objects and so prevent them from being deallocated
        //-------------------------------------------------------
        [context setUndoManager:nil];
        
        
        //set it to the App Delegates persistant store coordinator
        [context setPersistentStoreCoordinator:[appDelegate persistentStoreCoordinator]];
        
        // overwrite the database with updates from this context
        [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        
        
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
                    [self setPhotos:lastAlbumsPhotos forAlbum:lastAlbum];
                }
                
                // try to fetch an existing album with the new photos path
                lastAlbum = [self fetchAlbumWithPath:aPath inContext:context];
                
                // if we didn't find an existing album then we need to create it
                if (lastAlbum==nil)
                {
                    lastAlbum = [NSEntityDescription insertNewObjectForEntityForName:@"PIXAlbum" inManagedObjectContext:context];
                    [lastAlbum setValue:aPath forKey:@"path"];
                }
                
                // store the objectID's of any albums we touch so we can go through and update them on the main thread later
                [editedAlbumObjectIDs addObject:[lastAlbum objectID]];
                
                // we're starting a freshly found/created album so clear this array
                [lastAlbumsPhotos removeAllObjects];
                
                // set the date last Updated so this album is marked to not be deleted
                [lastAlbum setDateLastUpdated:fetchDate];
                
                // sethi the existing photos array to the current photos in the album
                lastAlbumsExistingPhotos = [[lastAlbum.photos array] mutableCopy];
            }
            
            // now iterate throuhg the album's existing photos and see if this phot is already in core data
            __block PIXPhoto *dbPhoto = nil;
            NSUInteger index = [lastAlbumsExistingPhotos indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                //
                if ([[obj valueForKey:@"path"] isEqualToString:[aPhoto valueForKey:@"path"]])
                {
                    // we found the photo
                    dbPhoto = obj;
                    return YES;
                }
                return NO;
            }];
            
            // if we didn't find the photo we'll need to create a new entity
            if(dbPhoto==nil)
            {
                dbPhoto = [NSEntityDescription insertNewObjectForEntityForName:@"PIXPhoto" inManagedObjectContext:context];
            }
            
            // if we found the photo, remove it from the album's existing photos
            if (index != NSNotFound) {
                [lastAlbumsExistingPhotos removeObjectAtIndex:index];
            }
            
            // set some basic attributes on the photo
            [dbPhoto setDateLastModified:[aPhoto valueForKey:@"modified"]];
            [dbPhoto setPath:[aPhoto valueForKey:@"path"]];
            
            // set this date so this photo won't be deleted
            [dbPhoto setDateLastUpdated:fetchDate];
            
            // add the photos to the array of found photos for this album
            [lastAlbumsPhotos addObject:dbPhoto];
            
            // save the context and send a UI update notification every 500 loops
            if (i%500==0) {
                [context save:nil];
                
                // update flush albums and the UI with a notification
                // use performSelector instead of dispatch async because it's faster
                [self performSelectorOnMainThread:@selector(flushAlbumsWithIDS:) withObject:[editedAlbumObjectIDs copy] waitUntilDone:NO];
                
                // we've flushed these already so clear them out
                [editedAlbumObjectIDs removeAllObjects];
                
                // add the last one back in because we're still working with it
                [editedAlbumObjectIDs addObject:[lastAlbum objectID]];
            }
        }
        
        // we've finished the loop. add the photos objects to the last album we were working with
        [lastAlbumsPhotos addObjectsFromArray:lastAlbumsExistingPhotos];
        [self setPhotos:lastAlbumsPhotos  forAlbum:lastAlbum];
        
        if(deletionBlock)
        {
            deletionBlock(context);
        }
        
        
        
        // save the context
        [context save:nil];
        
        // update flush albums and the UI with a notification
        // use performSelector instead of dispatch async because it's faster
        [self performSelectorOnMainThread:@selector(flushAlbumsWithIDS:) withObject:[editedAlbumObjectIDs copy] waitUntilDone:NO];
        
        
        
        
    });
    
    
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

-(void)setPhotos:(NSMutableArray *)newPhotos forAlbum:(PIXAlbum *)anAlbum
{
    NSSortDescriptor *sortByDate = [[NSSortDescriptor alloc] initWithKey:@"dateLastModified" ascending:YES];
    [newPhotos sortUsingDescriptors:@[sortByDate] ];
    NSOrderedSet *newPhotosSet = [[NSOrderedSet alloc] initWithArray:newPhotos];
    [anAlbum setPhotos:newPhotosSet updateCoverImage:YES];
    [newPhotos removeAllObjects];
}

// this should always be called on the main thread
-(void)flushAlbumsWithIDS:(NSSet *)albumIDs
{
    // fetch any the albums with these ids
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kAlbumEntityName];
    [fetchRequest setPredicate: [NSPredicate predicateWithFormat: @"(self IN %@)", albumIDs]];
    
    NSError * error;
    NSArray * editedAlbums = [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    for(PIXAlbum * album in editedAlbums)
    {
        [album flush];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
}

-(BOOL)deleteObjectsForEntityName:(NSString *)entityName withUpdateDateBefore:(NSDate *)lastUpdated inContext:(NSManagedObjectContext *)context withPath:(NSString *)path
{
    BOOL isPhotoEntity = NO;
    if ([entityName isEqualToString:kPhotoEntityName])
    {
        isPhotoEntity = YES;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dateLastUpdated == NULL || dateLastUpdated < %@", lastUpdated, nil];
    if (path!=nil) {
        if (isPhotoEntity) {
            predicate = [NSPredicate predicateWithFormat:@"album.path == %@ && (dateLastUpdated == NULL || dateLastUpdated < %@)",path, lastUpdated, nil];
        } else {
            
            predicate = [NSPredicate predicateWithFormat:@"path == %@ && (dateLastUpdated == NULL || dateLastUpdated < %@)", path, lastUpdated, nil];
        }
    }
    
    
    NSFetchRequest *fetchRequestRemoval = [[NSFetchRequest alloc] initWithEntityName:entityName];
    // make sure the results are sorted as well
    [fetchRequestRemoval setPredicate:predicate];
    [fetchRequestRemoval setSortDescriptors: [NSArray arrayWithObject:
                                              [[NSSortDescriptor alloc] initWithKey: @"dateLastUpdated"
                                                                          ascending:YES] ]];
    NSError * anError;
    NSArray *itemsToDelete = [context executeFetchRequest:fetchRequestRemoval error:&anError];
    DLog(@"Deleting %ld items of entity type %@", itemsToDelete.count, entityName);
    
    if (itemsToDelete==nil) {
        DLog(@"Unresolved error %@, %@", anError, [anError userInfo]);
#ifdef DEBUG
        [[NSApplication sharedApplication] presentError:anError];
#endif
        return NO;
    }
    
    
    if ([itemsToDelete count]>0) {
        DLog(@"Deleting %ld items that are no longer in the feed", [itemsToDelete count]);
        NSMutableSet *albumsChanged = [NSMutableSet set];
        // delete any albums that are no longer in the feed
        for (id anItemToDelete in itemsToDelete)
        {
            DLog(@"Deleting item %@ with a dateLastUpdated of %@ which should be after %@", anItemToDelete, [anItemToDelete dateLastUpdated], lastUpdated);
            if (isPhotoEntity) {
                PIXPhoto *aPhoto = (PIXPhoto *)anItemToDelete;
                if (aPhoto.album == nil) {
                    //NSAssert(aPhoto.album, @"Photo should not have album already");
                    DLog(@"Photo should have album");
                    continue;
                }
                [albumsChanged addObject:aPhoto.album];
            }
            [context deleteObject:anItemToDelete];
        }
        if (isPhotoEntity) {
            for (PIXAlbum *anAlbum in albumsChanged)
            {
                [anAlbum updateAlbumBecausePhotosDidChange];
            }
        }
        anError = nil;
        if (![context save:&anError]) {
            DLog(@"Unresolved error %@, %@", anError, [anError userInfo]);
            return NO;
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
    
    anError = nil;
    if (![context save:&anError]) {
        DLog(@"Unresolved error %@, %@", anError, [anError userInfo]);
        return NO;
    }
    
    return YES;
}


#pragma mark - Lazy Loaders


-(NSArray *) observedDirectories
{
    if (_observedDirectories==nil) {
        
        // pull the observed directories from the NSUserDefaults
        
        NSArray * pathArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"PIX_ObservedDirectoriesKey"];
        
        
        // if we have not observed directories in the settings then default to the dropbox /Photos and /Camera Uploads folders
        if([pathArray count] == 0)
        {
            NSString *dropboxHomePath = aDefaultDropBoxDirectory();
            NSURL *rootFilePathURL = [NSURL fileURLWithPath: [NSString stringWithFormat:@"%@/Photos", dropboxHomePath]];
            NSURL *cameraUploadsLocation = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/Camera Uploads", dropboxHomePath]];
            _observedDirectories = [NSArray arrayWithObjects:rootFilePathURL, cameraUploadsLocation, nil];
        }
        
        // otherwise loop through and create NSUrls from the strings
        else
        {
            NSMutableArray * urlArray = [NSMutableArray new];
            
            for(NSString * path in pathArray)
            {
                if([path isKindOfClass:[NSString class]])
                {
                    NSURL * url = [NSURL fileURLWithPath:path];
                    [urlArray addObject:url];
                }
            }
            
            _observedDirectories = urlArray;
            return _observedDirectories;
        }
    }
    
    return _observedDirectories;
}

@end
