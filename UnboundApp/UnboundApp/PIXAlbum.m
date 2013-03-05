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
@dynamic dateLastUpdated;
@dynamic path;
@dynamic subtitle;
@dynamic thumbnail;
@dynamic title;
@dynamic account;
@dynamic datePhoto;
@dynamic photos;
@dynamic stackPhotos;

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
        
    }
    return self.subtitle;
}

- (NSString *)path
{
    [self willAccessValueForKey:@"path"];
    NSString *tmpValue = [self primitiveValueForKey:@"path"];
    [self didAccessValueForKey:@"path"];
    return tmpValue;
}

- (void)setPath:(NSString *)value
{
    [self willChangeValueForKey:@"path"];
    [self setPrimitiveValue:value forKey:@"path"];
    [self setTitle:[value lastPathComponent]];
    [self didChangeValueForKey:@"path"];
}

-(void)updateAlbumBecausePhotosDidChange
{
    self.subtitle = nil;
    [self updateDatePhoto];
    [self updateStackPhotos];
}

-(void)updateDatePhoto
{
    if (self.photos.count)
    {
        PIXPhoto *newDatePhoto = [self.photos lastObject];
        if (newDatePhoto != self.datePhoto) {
            self.datePhoto = newDatePhoto;
            
            self.albumDate = [self.datePhoto findDisplayDate];
            
            self.subtitle = nil;
            
        }
    }
}

-(void)setPhotos:(NSOrderedSet *)photos updateCoverImage:(BOOL)shouldUpdateCoverPhoto;
{
    NSMutableOrderedSet *newPhotosSet = [photos mutableCopy];
    
    [newPhotosSet sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        PIXPhoto * photo1 = obj1;
        PIXPhoto * photo2 = obj2;
        
        NSDate * photo1Date = [photo1 dateTaken];
        NSDate * photo2Date = [photo2 dateTaken];
        
        /*
         if(photo1Date == nil) photo1Date = [photo1 dateCreated];
         
         
         if(photo2Date == nil) photo2Date = [photo2 dateCreated];
         */
        
        if(photo2Date == nil || photo1Date == nil)
        {
            photo1Date = [photo1 dateCreated];
            photo2Date = [photo2 dateCreated];
        }
        
        return [photo1Date compare:photo2Date];
        
    }];
    
    self.subtitle = nil;
    
    self.photos = newPhotosSet;
    
    if (shouldUpdateCoverPhoto==YES && photos.count != 0) {
        [self updateAlbumBecausePhotosDidChange];
    }
}

-(void)updateStackPhotos
{
    NSUInteger photoCount = self.photos.count;
    if (photoCount > 0) {
        NSUInteger stackRange = photoCount>=3 ? 3 : photoCount;
        NSRange indexRange = NSMakeRange(0, stackRange);
        NSIndexSet *stackSet = [NSIndexSet indexSetWithIndexesInRange:indexRange];
        NSArray *stackArray = [self.photos objectsAtIndexes:stackSet];
        self.stackPhotos = [NSOrderedSet orderedSetWithArray:stackArray];
    }
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
        self.subtitle = nil;
        
        // not sure if we need to send this. the all albums refresh is always sent after this
        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self];
    }
    
    [self updateUnboundFile];
}

-(void)updateUnboundFile
{

    NSString *unboundFilePath = [NSString stringWithFormat:@"%@/.unbound", self.path];
    
    NSMutableDictionary * unboundMetaDictionary = nil;
    
    // if we already have a .unboubnd file load that
    if ([[NSFileManager defaultManager] fileExistsAtPath:unboundFilePath])
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

    //DLog(@"before: %@", unboundMetaDictionary);
    
    [unboundMetaDictionary setObject:@"1.0" forKey:@"unboundFileVersion"];
    
    // loop through the photos and populate the captions
    NSDictionary * photosDictionary = [unboundMetaDictionary objectForKey:@"photos"];
    NSEnumerator *enumerator = [photosDictionary keyEnumerator];
    id aKey = nil;
    while ( (aKey = [enumerator nextObject]) != nil) {
        NSString * photoName = (NSString *)aKey;
        NSDictionary * photoDict = [photosDictionary objectForKey:aKey];
        
        // check that these are the right class types
        if([photoName isKindOfClass:[NSString class]] && [photoDict isKindOfClass:[NSDictionary class]])
        {
            //DLog(@"Found Photo Caption");
        }
        
    }
    
    NSDateFormatter *datFormatter = [[NSDateFormatter alloc] init];
    [datFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    
    if(self.albumDate != nil)
    {
        [unboundMetaDictionary setObject:[datFormatter stringFromDate:[self albumDate]] forKey:@"albumDate"];
    }
    
    //DLog(@"after: %@", unboundMetaDictionary);
    
    // write the JSON back to the file
    NSOutputStream *os = [[NSOutputStream alloc] initToFileAtPath:unboundFilePath append:NO];
    NSError *error;
    [os open];
    if (![NSJSONSerialization writeJSONObject:unboundMetaDictionary toStream:os options:NSJSONWritingPrettyPrinted error:&error]) {
        [PIXAppDelegate presentError:error];
    }
    [os close];

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
