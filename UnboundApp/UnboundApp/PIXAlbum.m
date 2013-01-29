//
//  PIXAlbum.m
//  UnboundApp
//
//  Created by Bob on 1/8/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXAlbum.h"
#import "PIXAccount.h"
#import "PIXPhoto.h"
#import "PIXThumbnail.h"
#import "PIXDefines.h"

static NSString *const kItemsKey = @"photos";

@implementation PIXAlbum

@dynamic dateLastUpdated;
@dynamic path;
@dynamic photos;
@dynamic account;
@dynamic title;
@dynamic subtitle;
@dynamic thumbnail;
@dynamic coverPhoto;
@dynamic albumDate;

//@dynamic dateMostRecentPhoto;

// invoked after a fetch or after unfaulting (commonly used for computing derived values from the persisted properties)
-(void)awakeFromFetch
{
    [super awakeFromFetch];
//    if (self.photos != nil && self.coverPhoto==nil) {
//        self.coverPhoto = [self.photos lastObject];
//        //DLog(@"%@", aDate);
//    }
    //[[NSNotificationCenter defaultCenter] addObser]
    //[self addObserver:self forKeyPath:@"photos.count" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"photos" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"coverImage" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"photos"]) {
        _thumbnailImage = nil;
        self.thumbnail = nil;
        DLog(@"photos changed for album : %@", self.title);
        self.subtitle = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

/* Callback before delete propagation while the object is still alive.  Useful to perform custom propagation before the relationships are torn down or reconfigure KVO observers. */
- (void)prepareForDeletion
{
    [self removeObserver:self forKeyPath:@"photos"];
    [self removeObserver:self forKeyPath:@"coverImage"];
    [super prepareForDeletion];
}

-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"photos"];
    [self removeObserver:self forKeyPath:@"coverImage"];
}

- (NSURL *)filePathURL
{
    return [NSURL fileURLWithPath:self.path isDirectory:YES];
}

- (NSImage *)thumbnailImage
{
    if (_thumbnailImage == nil)
    {
        NSData *thumbData = self.thumbnail;
        if (thumbData != nil) {
            _thumbnailImage = [[NSImage alloc] initWithData:self.thumbnail];
        } else if (self.coverPhoto.thumbnail.imageData == nil) {
            [self.coverPhoto thumbnailImage];
            return nil;
            /*NSURL *aPath = self.coverPhoto.filePath;
            self.thumbnail = [[NSData alloc] initWithContentsOfMappedFile:aPath.path];
            _thumbnailImage = [[NSImage alloc] initWithData:self.thumbnail];*/
        } else if (self.coverPhoto.thumbnail.imageData != nil) {
            self.thumbnail = self.coverPhoto.thumbnail.imageData;
            _thumbnailImage = [[NSImage alloc] initWithData:self.thumbnail];
            /*NSURL *aPath = self.coverPhoto.filePath;
             self.thumbnail = [[NSData alloc] initWithContentsOfMappedFile:aPath.path];
             _thumbnailImage = [[NSImage alloc] initWithData:self.thumbnail];*/
        } else {
            return nil;
        }
    }
    return _thumbnailImage;
}

-(void)cancelThumbnailLoading;
{
    self.coverPhoto.cancelThumbnailLoadOperation = YES;
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
            [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
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

-(void)setPhotos:(NSOrderedSet *)photos updateCoverImage:(BOOL)shouldUpdateCoverPhoto;
{
    self.photos = photos;
    if (shouldUpdateCoverPhoto==YES && photos.count != 0) {
        self.coverPhoto = [photos objectAtIndex:0];
        self.albumDate = self.coverPhoto.dateLastModified;
        NSData *coverImageThumbData = self.coverPhoto.thumbnail.imageData;
        if (coverImageThumbData != nil) {
            self.thumbnail = coverImageThumbData;
        }
    }
}


//-(PIXPhoto *)mostRecentPhoto
//{
//    if (_mostRecentPhoto == nil && self.photos != nil)
//    {
//        _mostRecentPhoto = [self fetchMostRecentPhoto];
//    }
//    return _mostRecentPhoto;
//}
//
//-(NSDate *)dateMostRecentPhoto
//{
//    if (_dateMostRecentPhoto == nil && self.photos != nil)
//    {
//        PIXPhoto *aPhoto = [self mostRecentPhoto];
//        if (aPhoto!=nil) {
//            _dateMostRecentPhoto = aPhoto.dateLastModified;
//        }
//    }
//    return _dateMostRecentPhoto;
//}
//
//-(PIXPhoto *)fetchMostRecentPhoto
//{
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PIXPhoto"];
//    
//    fetchRequest.fetchLimit = 1;
//    fetchRequest.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"dateLastModified" ascending:NO]];
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"album == %@", self];
//    [fetchRequest setPredicate:predicate];
//    NSError *error = nil;
//    
//    id photo = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error].lastObject;
//    return (PIXPhoto *)photo;
//}
//
//-(PIXPhoto *)fetchMostRecentPhotoOld
//{
//    NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:@"dateLastModified"];
//    NSExpression *maxDateExpression = [NSExpression expressionForFunction:@"max:"
//                                                                arguments:[NSArray arrayWithObject:keyPathExpression]];
//    
//    NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
//    [expressionDescription setName:@"mostRecent"];
//    [expressionDescription setExpression:maxDateExpression];
//    [expressionDescription setExpressionResultType:NSDateAttributeType];
//    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:kPhotoEntityName];
//    [request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
//    NSError *error;
//    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
//    id aResult = [results lastObject];
//    if (aResult==nil) {
//        DLog(@"%@", error);
//        return nil;
//    }
//    return (PIXPhoto *)aResult;
//}

//TODO: look into NSFetchedPropertyDescription
//-(NSDate *)fetchDateMostRecentPhoto
//{
//    NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:@"dateLastModified"];
//    NSExpression *maxDateExpression = [NSExpression expressionForFunction:@"max:"
//                                                                  arguments:[NSArray arrayWithObject:keyPathExpression]];
//    
//    NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
//    [expressionDescription setName:@"mostRecent"];
//    [expressionDescription setExpression:maxDateExpression];
//    [expressionDescription setExpressionResultType:NSDateAttributeType];
//    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:kPhotoEntityName];
//    [request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
//    NSError *error;
//    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
//    id aResult = [results lastObject];
//    if (aResult==nil) {
//        DLog(@"%@", error);
//        return nil;
//    }
//    //DLog(@"result : %@", aResult);
//    return (NSDate *)[aResult valueForKey:@"dateLastModified"];
//}


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

//NSKeyValueSetSetMutation
/*-(void)setPhotos:(NSOrderedSet *)values
{
    [self willChangeValueForKey:@"photos" withSetMutation:NSKeyValueSetSetMutation usingObjects:values];
    [[self primitiveValueForKey:@"photos"] unionSet:values];
    [self didChangeValueForKey:@"photos" withSetMutation:NSKeyValueSetSetMutation usingObjects:values];
}

-(NSOrderedSet *)photos
{
    [self willAccessValueForKey:@"photos"];
    NSOrderedSet *tmpValue = [self primitiveValueForKey:@"photos"];
    [self didAccessValueForKey:@"photos"];
    return tmpValue;
}*/

@end
