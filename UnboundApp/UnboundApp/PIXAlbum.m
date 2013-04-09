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
#import "PIXThumbnail.h"
#import "PIXDefines.h"
#import "PIXAppDelegate.h"

static NSString *const kItemsKey = @"photos";

@implementation PIXAlbum

@dynamic albumDate;
@dynamic startDate;
@dynamic dateLastUpdated;
@dynamic dateReadUnboundFile;
@dynamic path;
@dynamic subtitle;
@dynamic thumbnail;
@dynamic title;
@dynamic account;
@dynamic datePhoto;
@dynamic photos;
@dynamic stackPhotos;

+(NSArray *)sortedAlbums
{
    
    NSManagedObjectContext * context = [[PIXAppDelegate sharedAppDelegate] managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kAlbumEntityName];
    [fetchRequest setFetchBatchSize:100];
    
    // prefetch stack photos. These are used in the album-level views
    [fetchRequest setRelationshipKeyPathsForPrefetching:@[@"stackPhotos"]];
    
    PIXAlbumSort currentSort = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"PIXAlbumSort"];
    
    NSSortDescriptor * sort1 = nil;
    NSSortDescriptor * sort2 = nil;
    
    switch (currentSort) {
        case PIXAlbumSortNewToOld:
            
            sort1 = [[NSSortDescriptor alloc] initWithKey:@"albumDate" ascending:NO];
            sort2 = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO selector:@selector(localizedStandardCompare:)];
            [fetchRequest setSortDescriptors:@[sort1, sort2]];
            
            break;
            
        case PIXAlbumSortOldToNew:
            
            sort1 = [[NSSortDescriptor alloc] initWithKey:@"albumDate" ascending:YES];
            sort2 = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)];
            [fetchRequest setSortDescriptors:@[sort1, sort2]];
            
            break;
            
        case PIXAlbumSortAtoZ:
            
            sort1 = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)];
            sort2 = [[NSSortDescriptor alloc] initWithKey:@"albumDate" ascending:YES];
            
            [fetchRequest setSortDescriptors:@[sort1, sort2]];
            
            break;
            
        case PIXAlbumSortZtoA:
            
            sort1 = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO selector:@selector(localizedStandardCompare:)];
            sort2 = [[NSSortDescriptor alloc] initWithKey:@"albumDate" ascending:NO];
            
            [fetchRequest setSortDescriptors:@[sort1, sort2]];
            
            break;
            
        default:
            
            sort1 = [[NSSortDescriptor alloc] initWithKey:@"albumDate" ascending:NO];
            sort2 = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO];
            [fetchRequest setSortDescriptors:@[sort1, sort2]];
            
            break;
    }
    
    
    
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects == nil) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    
    return fetchedObjects;
}

- (NSURL *)filePathURL
{
    return [NSURL fileURLWithPath:self.path isDirectory:YES];
}

-(NSImage *)thumbnailImage
{
    return nil; // this is just here for the protocol
}

-(void)cancelThumbnailLoading;
{
    for(PIXPhoto * stackPhoto in self.stackPhotos)
    {
        stackPhoto.cancelThumbnailLoadOperation = YES;
    }
}



- (NSString *) imageSubtitle;
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


-(void)setPhotos:(NSSet *)photos updateCoverImage:(BOOL)shouldUpdateCoverPhoto;
{
    /*
    NSMutableOrderedSet *newPhotosSet = [photos mutableCopy];
    
    [newPhotosSet sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        PIXPhoto * photo1 = obj1;
        PIXPhoto * photo2 = obj2;
        
        NSDate * photo1Date = [photo1 dateTaken];
        NSDate * photo2Date = [photo2 dateTaken];
        
        
        if(photo1Date == nil) photo1Date = [photo1 dateCreated];
        if(photo2Date == nil) photo2Date = [photo2 dateCreated];
         
        
//        if(photo2Date == nil || photo1Date == nil)
//        {
//            photo1Date = [photo1 dateCreated];
//            photo2Date = [photo2 dateCreated];
//        }
    
        return [photo1Date compare:photo2Date];
        
    }];
    */
    
    
    self.photos = photos;
    
    NSUInteger photoCount = self.photos.count;
    if (shouldUpdateCoverPhoto==YES && photoCount != 0)
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
        NSUInteger stackRange = photoCount>=3 ? 3 : photoCount;
        NSRange indexRange = NSMakeRange(0, stackRange);
        NSIndexSet *stackSet = [NSIndexSet indexSetWithIndexesInRange:indexRange];
        NSArray *stackArray = [self.sortedPhotos objectsAtIndexes:stackSet];
        self.stackPhotos = [NSOrderedSet orderedSetWithArray:stackArray];
        
        
        // set the subtitle
        NSDate *aDate = self.albumDate;
        
        NSString *formattedDateString = [[PIXAlbum sharedSubtitleDateFormatter] stringFromDate:aDate];
        self.subtitle = [NSString stringWithFormat:@"%ld items from %@", photoCount, formattedDateString];
        
    }
    
    else
    {
        self.subtitle = @"No Items";
    }
    
    
}

-(NSArray *)sortedPhotos
{
    return [(NSSet *)self.photos sortedArrayUsingDescriptors:[self photoSortDescriptors]];
}

-(NSArray *)photoSortDescriptors
{
    PIXPhotoSort currentSort = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"PIXPhotoSort"];
    
    NSSortDescriptor * sort1 = nil;
    NSSortDescriptor * sort2 = nil;
    NSArray * sortDescriptors;
    
    switch (currentSort) {
        case PIXPhotoSortNewToOld:
            
            sort1 = [[NSSortDescriptor alloc] initWithKey:@"sortDate" ascending:NO];
            sort2 = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO selector:@selector(localizedStandardCompare:)];
            sortDescriptors = @[sort1, sort2];
            
            break;
            
        case PIXPhotoSortOldToNew:
            
            sort1 = [[NSSortDescriptor alloc] initWithKey:@"sortDate" ascending:YES];
            sort2 = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)];
            sortDescriptors = @[sort1, sort2];
            
            break;
            
        case PIXPhotoSortAtoZ:
            
            sort1 = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)];
            sort2 = [[NSSortDescriptor alloc] initWithKey:@"sortDate" ascending:YES];
            
            sortDescriptors = @[sort1, sort2];
            
            break;
            
        case PIXPhotoSortZtoA:
            
            sort1 = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO selector:@selector(localizedStandardCompare:)];
            sort2 = [[NSSortDescriptor alloc] initWithKey:@"sortDate" ascending:NO];
            
            sortDescriptors = @[sort1, sort2];
            
            break;
            
        default:
            
            sort1 = [[NSSortDescriptor alloc] initWithKey:@"sortDate" ascending:NO];
            sort2 = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO];
            sortDescriptors = @[sort1, sort2];
            
            break;
    }
    
    return sortDescriptors;

}


-(void) checkDates
{    
    // create a dispatch queue so dispatches will happen in order
    dispatch_queue_t myQueue = dispatch_queue_create("com.pixite.albumDates", DISPATCH_QUEUE_SERIAL);
    // loop through all this album's photos
    for(PIXPhoto * aPhoto in self.photos)
    {
        // only try to get exif data if it's needed
        if(aPhoto.exifData == nil)
        {
            // this will dispatch async to pull the data from the file and then set the data on the main thread
            // this method will only do anything if exif is nil
            [aPhoto findExifDataUsingDispatchQueue:myQueue];
        }
    }
    
    // add this to the same queue so it will execute after all exif fetches are complete
    dispatch_async(myQueue, ^{
        
        // dispatch async again to keep the execution after the main thread settings of the exif data
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self setPhotos:self.photos updateCoverImage:YES];
            [self flush];
 
        });
        
    });
    
}

-(void)flush
{
    if(self.managedObjectContext != nil && ![self isDeleted])
    {
        //self.subtitle = nil;
        
        // not sure if we need to send this. the all albums refresh is always sent after this
        //[[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self];
        
        [self updateUnboundFileinBackground];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self];
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
        NSData *data = [NSData dataWithContentsOfFile:unboundFilePath];
        NSError *error = nil;
        unboundMetaDictionary = [[NSJSONSerialization JSONObjectWithData:data
                                                                 options:kNilOptions
                                                                   error:&error] mutableCopy];
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
    
    // write the JSON back to the file
    NSOutputStream *os = [[NSOutputStream alloc] initToFileAtPath:unboundFilePath append:NO];
    NSError *error;
    [os open];
    if (![NSJSONSerialization writeJSONObject:unboundJSON toStream:os options:NSJSONWritingPrettyPrinted error:&error]) {
        [PIXAppDelegate presentError:error];
    }
    [os close];
    
    [self setDateReadUnboundFile:[NSDate date]];
    
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
        NSManagedObjectContext * context = [[PIXAppDelegate sharedAppDelegate] threadSafeManagedObjectContext];
        PIXAlbum * threadAlbum = (PIXAlbum *)[context existingObjectWithID:thisID error:nil];
        
        if(threadAlbum == nil) return;
        
        [threadAlbum updateUnboundFile];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self];
        
    });
}

-(void)updateUnboundFile
{    
    if(![self unboundFileIsChanged]) return;
    
    
     NSMutableDictionary * unboundMetaDictionary = [self readUnboundFile];
        
    [unboundMetaDictionary setObject:@"1.0" forKey:@"unboundFileVersion"];
    
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
                            
                            PIXPhoto * mainThreadPhoto = (PIXPhoto *)[mainContext existingObjectWithID:photoID error:nil];
                            
                            if(mainThreadPhoto)
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
    
    [self.managedObjectContext save:nil];
    
    
}

-(void) setUnboundFileCaptionForPhoto:(PIXPhoto *)photo
{
    if(photo == nil) return;
    
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
