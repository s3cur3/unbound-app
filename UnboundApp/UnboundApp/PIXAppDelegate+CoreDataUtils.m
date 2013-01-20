//
//  PIXAppDelegate+CoreDataUtils.m
//  UnboundCoreDataUtility
//
//  Created by Bob on 1/4/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXAppDelegate+CoreDataUtils.h"
#import "PIXPhoto.h"
#import "PIXAlbum.h"
#import "PIXDefines.h"

extern NSString *kDirectoryPathKey;

extern NSString *kUB_ALBUMS_LOADED_FROM_FILESYSTEM;

@implementation PIXAppDelegate (CoreDataUtils)



-(IBAction)testFetchAllPhotos:(id)sender
{
    NSLog(@"testPhotosFetch");
    NSArray *fetchedObjects = [self fetchAllPhotos];
    NSLog(@"testPhotosFetch done : total count %ld", fetchedObjects.count);
}

-(NSArray *)fetchAllPhotos
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kPhotoEntityName];
    [fetchRequest setFetchBatchSize:500];
    NSError *error;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    return fetchedObjects;
}

-(void)setPhotos:(NSMutableArray *)newPhotos forAlbum:(PIXAlbum *)anAlbum
{
    NSOrderedSet *newPhotosSet = [[NSOrderedSet alloc] initWithArray:newPhotos];
    [anAlbum setPhotos:newPhotosSet updateCoverImage:YES];
    [newPhotos removeAllObjects];
}

-(void)photosFinishedLoading:(NSNotification *)note
{
    NSArray *photos = [note.userInfo valueForKey:@"items"];
    self.photoFiles = [photos sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES]]];
    
    self.fetchDate = [NSDate date];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
        //NSLog(@"TESTING");
        
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
        
        //-------------------------------------------------------
        //    Setting the undo manager to nil means that:
        //
        //    - You don’t waste effort recording undo actions for changes (such as insertions) that will not be undone;
        //    - The undo manager doesn’t maintain strong references to changed objects and so prevent them from being deallocated
        //-------------------------------------------------------
        [context setUndoManager:nil];
        
        
        //set it to the App Delegates persistant store coordinator
        PIXAppDelegate *appDelegate = (PIXAppDelegate *)[[NSApplication sharedApplication] delegate];
        [context setPersistentStoreCoordinator:[appDelegate persistentStoreCoordinator]];
        
        // overwrite the database with updates from this context
        [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        
        PIXAlbum *lastAlbum = nil;
        int i = 0;
        NSMutableArray *lastAlbumsPhotos = [NSMutableArray new];
        for (NSDictionary *aPhoto in self.photoFiles)
        {
            i++;
            NSString *aPath = [aPhoto valueForKey:@"dirPath"];
            if (!lastAlbum || ![aPath isEqualToString:lastAlbum.path])
            {
                if (lastAlbum) {
                    DLog(@"lastAlbum.photos.count = %ld", lastAlbum.photos.count);
                    [self setPhotos:lastAlbumsPhotos forAlbum:lastAlbum];
                    //lastAlbum.photos = [[NSOrderedSet alloc] initWithArray:lastAlbumsPhotos];
                    [lastAlbumsPhotos removeAllObjects];
                }
                lastAlbum = [self fetchAlbumWithPath:aPath inContext:context];
                if (lastAlbum==nil)
                {
                    lastAlbum = [NSEntityDescription insertNewObjectForEntityForName:@"PIXAlbum" inManagedObjectContext:context];
                    [lastAlbum setValue:aPath forKey:@"path"];
                }
                [lastAlbum setDateLastUpdated:self.fetchDate];
            }
            PIXPhoto *dbPhoto = [NSEntityDescription insertNewObjectForEntityForName:@"PIXPhoto" inManagedObjectContext:context];
            [dbPhoto setDateLastModified:[aPhoto valueForKey:@"modified"]];
            [dbPhoto setPath:[aPhoto valueForKey:@"path"]];
            [dbPhoto setDateLastUpdated:self.fetchDate];
            //[lastAlbum addPhotosObject:dbPhoto];
            //[dbPhoto setAlbum:lastAlbum];
            [lastAlbumsPhotos addObject:dbPhoto];
            //[lastAlbum addPhotosObject:dbPhoto];
            if (i%500==0) {
                [context save:nil];
            }
        }
        //lastAlbum.photos = [[NSOrderedSet alloc] initWithArray:lastAlbumsPhotos];
        //[lastAlbumsPhotos removeAllObjects];
        [self setPhotos:lastAlbumsPhotos forAlbum:lastAlbum];
        
        if (![self deleteObjectsForEntityName:@"PIXAlbum" withUpdateDateBefore:self.fetchDate inContext:context]) {
            DLog(@"There was a problem trying to delete old objects");
        }
        if (![self deleteObjectsForEntityName:@"PIXPhoto" withUpdateDateBefore:self.fetchDate inContext:context]) {
            DLog(@"There was a problem trying to delete old objects");
        }
        
        [context save:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            

            [self testFetchAllPhotos:nil];
            //[[NSNotificationCenter defaultCenter] postNotificationName:@"PhotoLoadingFinished" object:self userInfo:nil];

            [self testFetchAllAlbums:nil];
            //[[NSNotificationCenter defaultCenter] postNotificationName:@"AlbumLoadingFinished" object:self userInfo:nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
            
            [self finishedLoadingPrintTime];
        });
        
    });
    
    
}

//-(void)photosFinishedLoading:(NSNotification *)note
//{
//    NSArray *photos = [note.userInfo valueForKey:@"items"];
//    self.photoFiles = [photos sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES]]];
//    [self loadAlbums];
//}


//-(void)loadPhotos:(NSNotification *)note
-(void)loadPhotos;
{
    //NSArray *photos = [note.userInfo valueForKey:@"items"];
    //self.photoFiles = [photos sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES]]];
    [self loadPhotosForPage:1];
}

- (void)loadPhotosForPage:(NSUInteger)page
{
    DLog(@"fetchAllPhotosForPage: %ld", page);
    
    NSUInteger fileCount = self.photoFiles.count;
    NSUInteger recordsPerPage = 500;
    NSUInteger totalPages = (fileCount + recordsPerPage - 1) / recordsPerPage;
    
    
    NSUInteger index = (page-1) * recordsPerPage;
    
    NSUInteger rangeLength = recordsPerPage;
    
    if (index+recordsPerPage >= fileCount) {
        rangeLength = fileCount%500;
    }
    
    self.currentBatch = [self.photoFiles subarrayWithRange:NSMakeRange(index, rangeLength)];
    
    
    NSDictionary * params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                             self.currentBatch, @"items",
                             [NSString stringWithFormat:@"%ld", page], @"page",
                             @"500", @"perpage",
                             [NSString stringWithFormat:@"%ld", totalPages], @"pages",
                             kPhotoEntityName, @"entityName", nil];
    
    [self findOrCreateInDatabase:params];
    
    
}



- (void)findOrCreateInDatabase:(NSDictionary *)itemsDict
{
    [self findOrCreateInDatabase:itemsDict updateExisting:YES];
}


/** Given a list of managed objects, query the db and create if they don't exist, posibly update if they do.
 
 Based on the "Implementing Find-or-Create Efficiently" guidelines in this article
 https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/CoreData/Articles/cdImporting.html#//apple_ref/doc/uid/TP40003174-SW1
 
 @param itemsDict contains the items and some other useful values
 @param shouldUpdate should items already in the DB be updated
 @return void
 */
- (void)findOrCreateInDatabase:(NSDictionary *)itemsDict updateExisting:(BOOL)shouldUpdate
{
    
    //self.batchOfItems = nil;
    
    //used to signal short-circuit of the laoding if necessary
    loadingWasCanceled = NO;
    
    
    // loop through tags and set them up in a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
        // if the fetch was canceled after this background task was scheduled
        if(loadingWasCanceled == YES) {
            return;
        }
        
        NSArray *items = [itemsDict valueForKey:@"items"];
        int page = [[itemsDict valueForKey:@"page"] intValue];
        int totalPages = [[itemsDict valueForKey:@"pages"] intValue];
        //int perPage = [[itemsDict valueForKey:@"perpage"] intValue];
        
        NSString *entityName = [itemsDict valueForKey:@"entityName"];
        //int baseOrder = (page-1) * perPage;
        
        // create a new context in this thread
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
        
        //-------------------------------------------------------
        //    Setting the undo manager to nil means that:
        //
        //    - You don’t waste effort recording undo actions for changes (such as insertions) that will not be undone;
        //    - The undo manager doesn’t maintain strong references to changed objects and so prevent them from being deallocated
        //-------------------------------------------------------
        [context setUndoManager:nil];
        
        
        //set it to the App Delegates persistant store coordinator
        PIXAppDelegate *appDelegate = (PIXAppDelegate *)[[NSApplication sharedApplication] delegate];
        [context setPersistentStoreCoordinator:[appDelegate persistentStoreCoordinator]];
        
        // overwrite the database with updates from this context
        [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        
        
        NSArray *sortedItems = [items sortedArrayUsingDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES], nil]];
        
        NSArray *itemIDs = [sortedItems valueForKey:@"path"];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
        //[fetchRequest setEntity:[NSEntityDescription entityForName:kPhotoEntityName inManagedObjectContext:context]];
        [fetchRequest setPredicate: [NSPredicate predicateWithFormat: @"(path IN %@)", itemIDs]];
        
        
        // make sure the results are sorted by order. This will cause faster iteration through the loop when the order hasn't changed.
        [fetchRequest setSortDescriptors: [NSArray arrayWithObject:
                                           [[NSSortDescriptor alloc] initWithKey: @"path"
                                                                       ascending:YES]]];
        
        
        NSError * error;
        NSArray *itemsFound = [context executeFetchRequest:fetchRequest error:&error];
        
        if (page == 1) {
            self.fetchDate = [NSDate date];
        }
        
        //NSMutableSet *itemsToDelete = [NSMutableSet set];
        
        int startpoint = 0;
        for (NSDictionary *anItem in items)
        {
            NSString *anID = [anItem objectForKey:@"path"];
            id thisDBItem = nil;
            id dbItem = nil;
            
            //DLog(@"Serching for item %@", anID);
            
            // loop through all the albums in the db and check for this one
            for(int j = startpoint; j < [itemsFound count]; j++)
            {
                
                dbItem = [itemsFound objectAtIndex:j];
                if([[dbItem path] isEqualToString:anID])
                {
                    //DLog(@"Item '%@' found! Index is %d", dbItem.path, j);
                    if(j == startpoint)
                    {
                        startpoint++;
                    }
                    thisDBItem = dbItem;
                    break; // stop looping
                }
                //DLog(@"Checking core data album %@, Index is %d", dbItem.path, j);
            }
            
            if (thisDBItem==nil) // if we need to create a new item
            {
                //DLog(@"Item not found for album %@, creating one", anID);
                // Add albums to core data
                thisDBItem = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
                [thisDBItem setValue:anID forKey:@"path"];
                
            }
            if (shouldUpdate)
            {
                if ([entityName isEqualToString:kPhotoEntityName])
                {
                    [thisDBItem setDateLastModified:[anItem valueForKey:@"modified"]];
                }
                //TODO: update record with latest info
                //                int last_updated = [[photoset valueForKey:@"date_update"] intValue];
                //                int db_last_updated = -1;
                //                if ([thisDBAlbum dateSetup]!=nil) {
                //                    db_last_updated = [[thisDBAlbum dateSetup] timeIntervalSince1970];
                //                }
                //                if (last_updated > db_last_updated)
                //                {
                //                    [FlickrUtils setupAlbum:thisDBAlbum withInfoFrom:photoset ownerId:ownerId];
                //                }
                //
                //                thisDBAlbum.order = [NSNumber numberWithInt:baseOrder++];
                //                thisDBAlbum.dateFetchMatched = self.albumFetchDate;
            }
            [thisDBItem setDateLastUpdated:self.fetchDate];
            
        }
        
        // save the context and update the view between pages
        if (![context save:&error]) {
            // Handle the error...
            DLog(@"Unresolved error %@, %@", error, [error userInfo]);
            //abort();
        }
        
        if (page < totalPages)
        {
            //More entries to fetch
            DLog(@"Items fetched page %d out of total %d pages", page, totalPages);
            
            
            // if the fetch was canceled after this background task was scheduled
            if(loadingWasCanceled == YES) {
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([entityName isEqualToString:kPhotoEntityName])
                {
                    [self loadPhotosForPage:page+1];
                } else if ([entityName isEqualToString:kAlbumEntityName]) {
                    [self loadAlbumsForPage:page+1];
                }
                
                
            });
            return;
        } else {
            DLog(@"Finished fetching albums");
            //Delete old records
            if (![self deleteObjectsForEntityName:entityName withUpdateDateBefore:self.fetchDate inContext:context]) {
                DLog(@"There was a problem trying to delete old objects");
            }
            //
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([entityName isEqualToString:kPhotoEntityName])
                {
                    [self testFetchAllPhotos:nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"PhotoLoadingFinished" object:self userInfo:nil];
                } else if ([entityName isEqualToString:kAlbumEntityName]) {
                    [self testFetchAllAlbums:nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"AlbumLoadingFinished" object:self userInfo:nil];
                }
                
            });
            
        }
        
        
    });
    
    
}



-(BOOL)deleteObjectsForEntityName:(NSString *)entityName withUpdateDateBefore:(NSDate *)lastUpdated inContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dateLastUpdated == NULL || dateLastUpdated < %@", self.fetchDate, nil];
    
    
    NSFetchRequest *fetchRequestRemoval = [[NSFetchRequest alloc] initWithEntityName:entityName];
    // make sure the results are sorted as well
    [fetchRequestRemoval setPredicate:predicate];
    [fetchRequestRemoval setSortDescriptors: [NSArray arrayWithObject:
                                              [[NSSortDescriptor alloc] initWithKey: @"dateLastUpdated"
                                                                          ascending:YES] ]];
    NSError * anError;
    NSArray *itemsToDelete = [context executeFetchRequest:fetchRequestRemoval error:&anError];
    
    if (itemsToDelete==nil) {
        DLog(@"Unresolved error %@, %@", anError, [anError userInfo]);
#ifdef DEBUG
        [[NSApplication sharedApplication] presentError:anError];
#endif
        return NO;
    }
    
    
    if ([itemsToDelete count]>0) {
        DLog(@"Deleting %ld items that are no longer in the feed", [itemsToDelete count]);
        
        // delete any albums that are no longer in the feed
        for (id anItemToDelete in itemsToDelete)
        {
            DLog(@"Deleting item %@ with a dateLastUpdated of %@ which should be after %@", anItemToDelete, [anItemToDelete dateLastUpdated], self.fetchDate);
            [context deleteObject:anItemToDelete];
        }
        anError = nil;
        if (![context save:&anError]) {
            DLog(@"Unresolved error %@, %@", anError, [anError userInfo]);
            return NO;
        }
    }
    
    return YES;
}


-(IBAction)deleteAllPhotos:(id)sender
{
    NSLog(@"delete all records");
    NSArray *fetchedObjects = [self fetchAllPhotos];
    int counter = 0;
    NSError *error = nil;
    for (id aPhoto in fetchedObjects)
    {
        [self.managedObjectContext deleteObject:aPhoto];
        if (counter++%1000==0) {
            
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }
        
    }
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    NSLog(@"Deleted %d records", counter);
    
}



#pragma mark Album Methods

/*-(void)loadAlbums:(NSNotification *)note
 {
 NSArray *albums = [note.userInfo valueForKey:@"items"];
 self.albumFolders = [albums sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES]]];
 
 [self loadAlbumsForPage:1];
 }*/

-(void)loadAlbums
{
    NSArray *pathsArray = [self.photoFiles valueForKey:kDirectoryPathKey];
    NSSet *albumsSet = [NSSet setWithArray:pathsArray];
    NSArray *uniqueAlbums = [[albumsSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray *albumsDictArray = [NSMutableArray arrayWithCapacity:uniqueAlbums.count];
    for (NSString *aPath in uniqueAlbums)
    {
        [albumsDictArray addObject:@{@"path" : aPath, @"dirPath" : aPath}];
    }
    //[albumsSet sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:kDirectoryPathKey ascending:YES]]];
    //albumsDictArray = [albumsSet sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES]]];
    self.albumFolders = [NSArray arrayWithArray:albumsDictArray];
    
    [self loadAlbumsForPage:1];
}

- (void)loadAlbumsForPage:(NSUInteger)page
{
    DLog(@"fetchAllPhotosForPage: %ld", page);
    
    NSUInteger fileCount = self.albumFolders.count;
    NSUInteger recordsPerPage = 500;
    NSUInteger totalPages = (fileCount + recordsPerPage - 1) / recordsPerPage;
    
    
    NSUInteger index = (page-1) * recordsPerPage;
    
    NSUInteger rangeLength = recordsPerPage;
    
    if (index+recordsPerPage >= fileCount) {
        rangeLength = fileCount%500;
    }
    
    self.currentBatch = [self.albumFolders subarrayWithRange:NSMakeRange(index, rangeLength)];
    
    
    NSDictionary * params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                             self.currentBatch, @"items",
                             [NSString stringWithFormat:@"%ld", page], @"page",
                             @"500", @"perpage",
                             [NSString stringWithFormat:@"%ld", totalPages], @"pages",
                             kAlbumEntityName, @"entityName", nil];
    
    [self findOrCreateInDatabase:params];
    
    
}

-(void)updateAlbumsPhotos
{
    NSArray *albumsToUpdate = [self fetchAllAlbums];
    NSError *error = nil;
    NSString *predicateString = [NSString stringWithFormat:@"dirPath == $PATH"];
    NSPredicate *aPredicate = [NSPredicate predicateWithFormat:predicateString];
    for (PIXAlbum *anAlbum in albumsToUpdate)
    {
        NSString *albumPath = anAlbum.path;
        NSDictionary *variables = @{@"PATH" : albumPath};
        NSPredicate *localPredicate = [aPredicate predicateWithSubstitutionVariables:variables];
        
        NSArray *filteredPhotoFiles = [self.photoFiles filteredArrayUsingPredicate:localPredicate];
        NSArray *photoPaths = [filteredPhotoFiles valueForKey:@"path"];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kPhotoEntityName];
        
        [fetchRequest setPredicate: [NSPredicate predicateWithFormat: @"(path IN %@)", photoPaths]];
        
        
        // make sure the results are sorted by order. This will cause faster iteration through the loop when the order hasn't changed.
        [fetchRequest setSortDescriptors: [NSArray arrayWithObject:
                                           [[NSSortDescriptor alloc] initWithKey: @"dateLastModified"
                                                                       ascending:NO]]];
        
        
        NSArray *itemsFound = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (itemsFound == nil) {
            [PIXAppDelegate presentError:error];
            break;
        }
        NSOrderedSet *photoSet = [[NSOrderedSet alloc] initWithArray:itemsFound];
        [anAlbum setPhotos:photoSet];
        
        DLog(@"Updated photos for album '%@' : total photo count %ld",albumPath, anAlbum.photos.count);
        //[itemsFound makeObjectsPerformSelector:@selector(setAlbum:) withObject:self];
    }
    
    if (![self.managedObjectContext save:&error]) {
        [PIXAppDelegate presentError:error];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
    
    [self finishedLoadingPrintTime];
}

-(void)finishedLoadingPrintTime
{
    NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:[[PIXAppDelegate sharedAppDelegate] startDate]];
    NSLog(@"%g seconds elapsed\n", time);
}

-(IBAction)testFetchAllAlbums:(id)sender
{
    NSLog(@"testFetchAllAlbums");
    NSArray *fetchedObjects = [self fetchAllAlbums];
    NSLog(@"testFetchAllAlbums done : total count %ld", fetchedObjects.count);
}


-(NSArray *)fetchAllAlbums
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kAlbumEntityName];
    [fetchRequest setFetchBatchSize:500];
    NSError *error;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
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

-(IBAction)deleteAllAlbums:(id)sender
{
    NSLog(@"delete all records");
    NSArray *fetchedObjects = [self fetchAllAlbums];
    int counter = 0;
    NSError *error = nil;
    for (id anAlbum in fetchedObjects)
    {
        [self.managedObjectContext deleteObject:anAlbum];
        if (counter++%1000==0) {
            
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }
        
    }
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    NSLog(@"Deleted %d records", counter);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:self userInfo:nil];
    
}

#pragma mark -

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender {
    return [[self managedObjectContext] undoManager];
}

@end
