//
//  PIXAlbum.m
//  UnboundApp
//
//  Created by Scott Sykora on 2/7/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXAlbum.h"
#import "PIXAccount.h"
#import "PIXPhoto.h"
#import "PIXDefines.h"
#import "PIXAppDelegate.h"
#import "PIXApplicationExtensions.h"
//#include <unistd.h>

static NSString *const kItemsKey = @"photos";

@implementation PIXAlbum

@dynamic albumDate;
@dynamic startDate;
@dynamic dateLastUpdated;
@dynamic dateReadUnboundFile;
@dynamic path;
@dynamic subtitle;
@dynamic title;
@dynamic account;
@dynamic datePhoto;
@dynamic photos;
@dynamic stackPhotos;
@dynamic needsDateScan;

PIXAlbumSort albumSortPref(void);
NSArray * albumSortDescriptors(PIXAlbumSort currentSort);

+(NSArray *)sortedAlbums
{
    return [self sortedAlbums:nil];
}

+(NSArray *)sortedAlbums:(NSString *)filterString
{
    NSManagedObjectContext * context = [[PIXAppDelegate sharedAppDelegate] managedObjectContext];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kAlbumEntityName];
    [fetchRequest setFetchBatchSize:100];
#if TRIAL
    [fetchRequest setFetchLimit:TRIAL_MAX_ALBUMS];
#endif

    // prefetch stack photos. These are used in the album-level views
    [fetchRequest setRelationshipKeyPathsForPrefetching:@[@"stackPhotos"]];

    NSPredicate * nonNullPath = [NSPredicate predicateWithFormat:@"path != NULL"];
    if(filterString && filterString.length > 0) {
        NSMutableArray<NSPredicate *> *predicates = [NSMutableArray array];
        [predicates addObject:nonNullPath];
        [predicates addObject:[NSCompoundPredicate orPredicateWithSubpredicates:@[
                [NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", filterString],
                [NSPredicate predicateWithFormat:@"subtitle CONTAINS[cd] %@", filterString]
        ]]];
        fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    } else {
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"path != NULL"]];
    }

	[fetchRequest setSortDescriptors:albumSortDescriptors(albumSortPref())];

    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }

    return fetchedObjects;
}

PIXAlbumSort albumSortPref(void)
{
    return (PIXAlbumSort)[[NSUserDefaults standardUserDefaults] integerForKey:@"PIXAlbumSort"];
}

NSArray * albumSortDescriptors(PIXAlbumSort currentSort)
{
    switch (currentSort) {
        case PIXAlbumSortNewToOld:
            return @[
                    [[NSSortDescriptor alloc] initWithKey:@"albumDate" ascending:NO],
                    [[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO selector:@selector(localizedStandardCompare:)]
            ];

        case PIXAlbumSortOldToNew:
            return @[
                    [[NSSortDescriptor alloc] initWithKey:@"albumDate" ascending:YES],
                    [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)]
            ];

        case PIXAlbumSortZtoA:
            return @[
                    [[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO selector:@selector(localizedStandardCompare:)],
                    [[NSSortDescriptor alloc] initWithKey:@"albumDate" ascending:NO]
            ];

        case PIXAlbumSortAtoZ:
        default:
            return @[
                    [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)],
                    [[NSSortDescriptor alloc] initWithKey:@"albumDate" ascending:YES]
            ];
    }
}

- (NSURL *)filePathURL
{
    return [NSURL fileURLWithPath:self.path isDirectory:YES];
}

-(NSImage *)thumbnailImage
{
    return nil; // this is just here for the protocol
}

-(void)prepareForDeletion
{
    
}





- (NSString *) imageSubtitle
{
    /*
    if (self.subtitle == nil)
    {
        if (self.dateLastUpdated && self.albumDate)
        {
            NSDate *aDate = self.albumDate;
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterShortStyle];
            [dateFormatter setTimeStyle:NSDateFormatterNoStyle]; // no time on albums
            NSString *formattedDateString = [dateFormatter stringFromDate:aDate];
            self.subtitle = [NSString stringWithFormat:@"%ld items from %@", self.photos.count, formattedDateString];
        } else if (self.dateLastUpdated && self.photos.count==0) {
            return @"No items";
        } else {
            return @"Loading...";
        }
        
    }*/
    return self.subtitle;
}

/*
- (NSString *)path
{
    [self willAccessValueForKey:@"path"];
    NSString *tmpValue = [self primitiveValueForKey:@"path"];
    [self didAccessValueForKey:@"path"];
    return tmpValue;
}*/

- (void)setPath:(NSString *)value
{
    [self willChangeValueForKey:@"path"];
    [self setPrimitiveValue:value forKey:@"path"];
    [self setTitle:[value lastPathComponent]];
    [self didChangeValueForKey:@"path"];
}


+(NSDateFormatter *)sharedSubtitleDateFormatter
{
    
    __strong static NSDateFormatter *_sharedSubtitleDateFormatter = nil;
    
    if(_sharedSubtitleDateFormatter == nil)
    {    
        _sharedSubtitleDateFormatter = [[NSDateFormatter alloc] init];
        [_sharedSubtitleDateFormatter setDateStyle:NSDateFormatterShortStyle];
        [_sharedSubtitleDateFormatter setTimeStyle:NSDateFormatterNoStyle]; // no time on albums
    }
    
    return _sharedSubtitleDateFormatter;

}


-(void)setPhotos:(NSSet *)photos updateCoverImage:(BOOL)shouldUpdateCoverPhoto
{
    if([self isReallyDeleted]) return;
    
    self.photos = photos;
    
    if(shouldUpdateCoverPhoto)
    {
        [self fixCoverAndSubtitle];
    }
    
    
}

-(void)fixCoverAndSubtitle
{
    if([self isReallyDeleted]) return;
    
    NSUInteger photoCount = self.photos.count;
    if (photoCount > 0)
    {
        // sort the photos for setting up the dates and stacks
        NSSortDescriptor * sort1 = [[NSSortDescriptor alloc] initWithKey:@"sortDate" ascending:YES];
        
        NSArray * datePhotos = [self.photos sortedArrayUsingDescriptors:@[sort1]];
        
        // set the startDate of the album (used at the top of the thumb grid)
        PIXPhoto * firstPhoto = [datePhotos objectAtIndex:0];
        self.startDate = [firstPhoto findDisplayDate];
        
        // set the datephoto and albumdate (maybe we don't need to store the datephoto relationship?)
        PIXPhoto *newDatePhoto = [datePhotos lastObject];
        
        if (newDatePhoto != self.datePhoto) {
            self.datePhoto = newDatePhoto;
            
            self.albumDate = [self.datePhoto findDisplayDate];
            
        }
        
        // set the stackphotos
        //NSUInteger stackRange = photoCount>=1 ? 1 : photoCount;
        NSUInteger stackRange = photoCount>=3 ? 3 : photoCount;
        NSRange indexRange = NSMakeRange(0, stackRange);
        NSIndexSet *stackSet = [NSIndexSet indexSetWithIndexesInRange:indexRange];
        NSArray *stackArray = [self.sortedPhotos objectsAtIndexes:stackSet];
        
        
        self.stackPhotos = [NSOrderedSet orderedSetWithArray:stackArray];
        
        
        // set the subtitle
        NSDate *aDate = self.albumDate;
        
        NSString *formattedDateString = [[PIXAlbum sharedSubtitleDateFormatter] stringFromDate:aDate];
        #warning TODO: Support 1 item
        self.subtitle = [NSString stringWithFormat:@"%ld items from %@", photoCount, formattedDateString];
        
    }
    
    else
    {
        self.subtitle = @"No Items";
    }
}

-(NSArray<PIXPhoto *> *)sortedPhotos
{
    return [self.photos sortedArrayUsingDescriptors:[self photoSortDescriptors]];
}

-(NSArray *)photoSortDescriptors
{
    PIXPhotoSort currentSort = (PIXPhotoSort) [[NSUserDefaults standardUserDefaults] integerForKey:@"PIXPhotoSort"];
    switch (currentSort) {
        case PIXPhotoSortOldToNew:
            return @[
                    [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:YES],
                    [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)]
            ];

        case PIXPhotoSortAtoZ:
            return @[
                    [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)],
                    [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:YES]
            ];

        case PIXPhotoSortZtoA:
            return @[
                    [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:NO selector:@selector(localizedStandardCompare:)],
                    [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:NO]
            ];

        case PIXPhotoSortNewToOld:
        default:
            return @[
                    [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:NO],
                    [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:NO selector:@selector(localizedStandardCompare:)]
            ];
    }
}
/*
- (NSOrderedSet *)stackPhotos
{
    [self willAccessValueForKey:@"stackPhotos"];
    NSOrderedSet *stackPhotos = [self primitiveValueForKey:@"stackPhotos"];
    [self didAccessValueForKey:@"stackPhotos"];
    
 
//    // if for some reason the stack photos got broken, fix them
//    if(stackPhotos.count == 0 && self.photos.count > 0)
//    {
//        // dispatch this so we don't get an infinite loop
//        dispatch_async(dispatch_get_current_queue(), ^{
//            [self setPhotos:self.photos updateCoverImage:YES];
//            
//            [[NSNotificationCenter defaultCenter] postNotificationName:AlbumStackDidChangeNotification object:self];
//        });
//    }

    
    return stackPhotos;
}*/



-(void) checkDates
{
    if([self isReallyDeleted]) return;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSManagedObjectContext * threadSafeContext = [[PIXAppDelegate sharedAppDelegate] threadSafePassThroughMOC];
        
        PIXAlbum * threadAlbum = (PIXAlbum *)[threadSafeContext objectWithID:[self objectID]];
        
        if([threadAlbum isReallyDeleted])
        {
            threadAlbum = nil;
        }
        
        // loop through all this album's photos
        for(PIXPhoto * aPhoto in threadAlbum.photos)
        {
            if(![aPhoto isReallyDeleted])
            {
                break;
            }
            
            // only try to get exif data if it's needed
            if(aPhoto.exifData == nil)
            {
                // this will dispatch async to pull the data from the file and then set the data on the main thread
                // this method will only do anything if exif is nil
                [aPhoto findExifData];
            }
        }
        
        // save the context back to the main thread
        [threadSafeContext save:nil];
        
        // dispatch async again to keep the execution after the main thread settings of the exif data
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setPhotos:self.photos updateCoverImage:YES];
            [self flush];
            [[PIXAppDelegate sharedAppDelegate] saveDBToDiskWithRateLimit];
        });
    });
    
}

-(void)flush
{
    if(![self isReallyDeleted])
    {
        [self.managedObjectContext refreshObject:self mergeChanges:NO];
        
        // I don't think we need to write unbound files unless we're saving captions now (only used on dropbox anyway)
        // I've commented this out to see if it's faster on initial scan
        //[self updateUnboundFileinBackground];
        
        [self fixCoverAndSubtitle];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumStackDidChangeNotification object:self];
        
        NSNotification * note = [NSNotification notificationWithName:AlbumDidChangeNotification object:self];
        
        // enqueue these notes on the sender so if a few album stack images load right after each other it doesn't have to redraw multiple times
        [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnSender forModes:nil];
        
        [self readAndImportUnboundFile];
            
        
        [[PIXAppDelegate sharedAppDelegate] saveDBToDiskWithRateLimit];
    }
}

-(BOOL)unboundFileIsChanged
{
    NSString *unboundFilePath = [NSString stringWithFormat:@"%@/.unbound", self.path];
        
    // if we already have a .unboubnd file load that
    if ([[NSFileManager defaultManager] fileExistsAtPath:unboundFilePath])
    {
        // if we've already loaded the .unbound file since it's been modified no need to do anything here
        NSURL * unboundFileURL = [NSURL fileURLWithPath:unboundFilePath];
        
        NSDate * dateModified = nil;
        [unboundFileURL getResourceValue:&dateModified forKey:NSURLContentModificationDateKey error:nil];
        
        if([self dateReadUnboundFile] && [[self dateReadUnboundFile] compare:dateModified] != NSOrderedAscending)
        {
            return NO; // no need to do anything here, the db is already up to date
        }
    }
    
    return YES;
}

-(NSMutableDictionary *)readUnboundFile
{
    if([self isReallyDeleted]) return nil;
    
    NSString *unboundFilePath = [NSString stringWithFormat:@"%@/.unbound", self.path];
    
    NSMutableDictionary * unboundMetaDictionary = nil;
    
    // if we already have a .unboubnd file load that
    NSFileManager * fm = [[NSFileManager alloc] init];
    
    if ([fm fileExistsAtPath:unboundFilePath])
    {
        NSError *anError = nil;
        //NSData *data = [NSData dataWithContentsOfFile:unboundFilePath];
        NSData *data = [NSData dataWithContentsOfFile:unboundFilePath options:(NSDataReadingUncached) error:&anError];
        if (data == nil) {
            DLog(@"No data returned when attempting to read '%@', error: %@", unboundFilePath, anError);
        } else {
            NSError *error = nil;
            unboundMetaDictionary = [[NSJSONSerialization JSONObjectWithData:data
                                                                     options:kNilOptions
                                                                       error:&error] mutableCopy];
            if (error != nil) {
                DLog(@"%@", error);
            }
        }
    }
    
    // if this isn't a dictionary then it's not valid
    if(![unboundMetaDictionary isKindOfClass:[NSMutableDictionary class]])
    {
        unboundMetaDictionary = [NSMutableDictionary new];
    }
    
    return unboundMetaDictionary;
}

-(void)writeUnboundFile:(NSDictionary *)unboundJSON
{
    NSString *unboundFilePath = [NSString stringWithFormat:@"%@/.unbound", self.path];
//    //NSURL *ubFileURL = [NSURL URLWithString:self.path];
//    if ((access([unboundFilePath UTF8String], W_OK) == 0) ||
//        (access([self.path UTF8String], W_OK) == 0))
//    {
//        // have access rights to read
    
    
    // if(![self shouldHaveUnboundFile]) return;
    
    // write the JSON back to the file
    NSOutputStream *os = [[NSOutputStream alloc] initToFileAtPath:unboundFilePath append:NO];
    NSError *error;
    [os open];

    // no error if this is unwritable (captions arent saved when disk is unwritabe but they're still stored in the db)
    if([os hasSpaceAvailable])
    {
        if (![NSJSONSerialization writeJSONObject:unboundJSON toStream:os options:NSJSONWritingPrettyPrinted error:&error]) {
            [PIXAppDelegate presentError:error];
        }
    }
    [os close];
    
    [self setDateReadUnboundFile:[NSDate date]];
    
//    } else {
//        NSAlert *alert = [[NSAlert alloc] init];
//        [alert setMessageText:@"Unable to save changes to album at path '%@'.\nWrite permissions are disabled."];
//        [alert addButtonWithTitle:@"OK"];
//        [alert runModal];
//    }
    

    
}

- (dispatch_queue_t)sharedUnboundQueue
{
    static dispatch_queue_t _sharedUnboundQueue = 0;
    
    static dispatch_once_t oncesharedUnboundQueue;
    dispatch_once(&oncesharedUnboundQueue, ^{
        _sharedUnboundQueue  = dispatch_queue_create("com.pixite.ub.unboundFileParsingQueue", 0);
        
        // set this to a high priority queue so it doens't get blocked by the thumbs loading
        dispatch_set_target_queue(_sharedUnboundQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));        
        
    });
    
    return _sharedUnboundQueue;
}


-(void)updateUnboundFileinBackground
{
    if(![self unboundFileIsChanged]) return;
    
    NSManagedObjectID * thisID = [self objectID];
    
    dispatch_async([self sharedUnboundQueue], ^{
        
        // get a bg thread context and find the album object
        NSManagedObjectContext * context = [[PIXAppDelegate sharedAppDelegate] threadSafePassThroughMOC];
        PIXAlbum * threadAlbum = (PIXAlbum *)[context objectWithID:thisID];
        
        
        if(threadAlbum == nil || [threadAlbum isReallyDeleted]) return;
        
        [threadAlbum updateUnboundFile];
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:AlbumStackDidChangeNotification object:self];
            
            NSNotification * note = [NSNotification notificationWithName:AlbumDidChangeNotification object:self];
            
            // enqueue these notes on the sender so if a few album stack images load right after each other it doesn't have to redraw multiple times
            [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnSender forModes:nil];
            
            [[PIXAppDelegate sharedAppDelegate] saveDBToDiskWithRateLimit];
        });
        
        
    });
}

-(BOOL)shouldHaveUnboundFile
{
    NSString * lowercasePath = [self.path lowercaseString];
    return ([lowercasePath rangeOfString:@"/dropbox/"].length > 0);
}

-(NSMutableDictionary *)readAndImportUnboundFile
{
    NSMutableDictionary * unboundMetaDictionary = [self readUnboundFile];
    
    // loop through the photos and populate the captions
    NSDictionary * photosDictionary = [unboundMetaDictionary objectForKey:@"photos"];
    
    if(photosDictionary)
    {
        for(PIXPhoto * aPhoto in self.photos)
        {
            NSDictionary * photoInfoDict = [photosDictionary objectForKey:[aPhoto name]];
            
            if(photoInfoDict)
            {
                NSString * caption = [photoInfoDict objectForKey:@"caption"];
                if([caption isKindOfClass:[NSString class]])
                {
                    // if we're changing the caption
                    if(![aPhoto.caption isEqualToString:[photoInfoDict objectForKey:@"caption"]])
                    {
                        NSManagedObjectID * photoID = [aPhoto objectID];
                        
                        // update the photo on the main thread
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            // get the mainthread context and find the photo
                            NSManagedObjectContext * mainContext = [[PIXAppDelegate sharedAppDelegate] managedObjectContext];
                            NSString * newCaption = [photoInfoDict objectForKey:@"caption"];
                            
                            PIXPhoto * mainThreadPhoto = (PIXPhoto *)[mainContext objectWithID:photoID];
                            
                            if(mainThreadPhoto && ![mainThreadPhoto isReallyDeleted])
                            {
                                // update the photo's caption
                                [mainThreadPhoto setCaption:newCaption];
                                
                                // also update the views
                                [mainThreadPhoto postPhotoUpdatedNote];
                            }
                            
                        });
                    }
                }
            }
        }
    }
    
    return unboundMetaDictionary;

}

-(void)updateUnboundFile
{    
    if(![self unboundFileIsChanged] || ![self shouldHaveUnboundFile]) return;
    
    
    NSMutableDictionary * unboundMetaDictionary = [self readAndImportUnboundFile];
        
    [unboundMetaDictionary setObject:@"1.0" forKey:@"unboundFileVersion"];
    
    
    NSDateFormatter *datFormatter = [[NSDateFormatter alloc] init];
    [datFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    
    BOOL wasChanged = NO;
    
    if(self.albumDate != nil)
    {
        NSString * newDateString = [datFormatter stringFromDate:[self albumDate]];
        NSString * oldDateString = [unboundMetaDictionary objectForKey:@"albumDate"];
        
        if(![oldDateString isEqualToString:newDateString])
        {
            [unboundMetaDictionary setObject:newDateString forKey:@"albumDate"];
            wasChanged = YES;
        }
    }
    
    //DLog(@"after: %@", unboundMetaDictionary);
    
    if(wasChanged)
    {
        [self writeUnboundFile:unboundMetaDictionary];
    }
}

-(void) setUnboundFileCaptionForPhoto:(PIXPhoto *)photo
{
    if(photo == nil) return;
    
    //if(![self shouldHaveUnboundFile]) return;
    
    NSMutableDictionary * unboundMetaDictionary = [self readUnboundFile];

    NSMutableDictionary * photos = [[unboundMetaDictionary objectForKey:@"photos"] mutableCopy];
    
    if(photos == nil)
    {
        photos= [NSMutableDictionary new];
    }
    
    NSMutableDictionary * photoDict = [[photos objectForKey:photo.name] mutableCopy];
    
    if(photoDict == nil)
    {
        photoDict = [NSMutableDictionary new];
    }
    
    // if we have a caption set it
    if(photo.caption != nil)
    {
        [photoDict setObject:photo.caption forKey:@"caption"];
    }
    
    // otherwise remove it
    else
    {
        [photoDict removeObjectForKey:@"caption"];
    }
    
    // if we have any photo info set it
    if([photoDict count])
    {
        [photos setObject:photoDict forKey:photo.name];
    }
    
    // if it's empty remove the key
    else
    {
        [photos removeObjectForKey:photo.name];
    }
    
    [unboundMetaDictionary setObject:photos forKey:@"photos"];
    
    [self writeUnboundFile:unboundMetaDictionary];
}

-(BOOL) isReallyDeleted
{
    return (self.isDeleted || self.managedObjectContext == nil);
}

//
//- (PIXPhoto *)coverPhoto
//{
//    [self willAccessValueForKey:@"coverPhoto"];
//    PIXPhoto *tmpValue = [self primitiveValueForKey:@"coverPhoto"];
//    [self didAccessValueForKey:@"coverPhoto"];
//    return tmpValue;
//}
//
//- (void)setCoverPhoto:(PIXPhoto *)value
//{
//    [self willChangeValueForKey:@"coverPhoto"];
//    [self setPrimitiveValue:value forKey:@"coverPhoto"];
//    self.albumDate = value.dateLastModified;
//    self.thumbnail = value.thumbnail.imageData;
//    _thumbnailImage = nil;
//    self.subtitle = nil;    
//    [self didChangeValueForKey:@"coverPhoto"];
//}



/*

- (void)insertObject:(PIXPhoto *)value inPhotosAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kItemsKey];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
    [tmpOrderedSet insertObject:value atIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kItemsKey];
}

- (void)removeObjectFromPhotosAtIndex:(NSUInteger)idx {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kItemsKey];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
    [tmpOrderedSet removeObjectAtIndex:idx];
    [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kItemsKey];
}

- (void)insertPhotos:(NSArray *)values atIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kItemsKey];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
    [tmpOrderedSet insertObjects:values atIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kItemsKey];
}

- (void)removePhotosAtIndexes:(NSIndexSet *)indexes {
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kItemsKey];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
    [tmpOrderedSet removeObjectsAtIndexes:indexes];
    [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kItemsKey];
}

- (void)replaceObjectInPhotosAtIndex:(NSUInteger)idx withObject:(PIXPhoto *)value {
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:kItemsKey];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
    [tmpOrderedSet replaceObjectAtIndex:idx withObject:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:kItemsKey];
}

- (void)replacePhotosAtIndexes:(NSIndexSet *)indexes withSubitems:(NSArray *)values {
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:kItemsKey];
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
    [tmpOrderedSet replaceObjectsAtIndexes:indexes withObjects:values];
    [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:kItemsKey];
}

- (void)addPhotosObject:(PIXPhoto *)value
{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
    NSUInteger idx = [tmpOrderedSet count];
    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kItemsKey];
    [tmpOrderedSet addObject:value];
    [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kItemsKey];
}

- (void)removePhotosObject:(PIXPhoto *)value
{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
    NSUInteger idx = [tmpOrderedSet indexOfObject:value];
    if (idx != NSNotFound) {
        NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kItemsKey];
        [tmpOrderedSet removeObject:value];
        [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kItemsKey];
    }
}

- (void)addPhotos:(NSOrderedSet *)values
{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSUInteger valuesCount = [values count];
    NSUInteger objectsCount = [tmpOrderedSet count];
    for (NSUInteger i = 0; i < valuesCount; ++i) {
        [indexes addIndex:(objectsCount + i)];
    }
    if (valuesCount > 0) {
        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kItemsKey];
        [tmpOrderedSet addObjectsFromArray:[values array]];
        [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
        [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kItemsKey];
    }
}

- (void)removePhotos:(NSOrderedSet *)values
{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (id value in values) {
        NSUInteger idx = [tmpOrderedSet indexOfObject:value];
        if (idx != NSNotFound) {
            [indexes addIndex:idx];
        }
    }
    if ([indexes count] > 0) {
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kItemsKey];
        [tmpOrderedSet removeObjectsAtIndexes:indexes];
        [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kItemsKey];
    }
}
*/

#pragma mark - Pastboard Dragging Methods


@end
