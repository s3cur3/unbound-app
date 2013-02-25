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
            
            self.albumDate = [self.datePhoto findDateTaken];
            
            self.subtitle = nil;
            
        }
    }
}

-(void)setPhotos:(NSOrderedSet *)photos updateCoverImage:(BOOL)shouldUpdateCoverPhoto;
{
    if (photos.count != self.photos.count)
    {
        self.subtitle = nil;
    }
    
    self.photos = photos;
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

-(void)flush
{
    if(self.managedObjectContext != nil && ![self isDeleted])
    {
        self.subtitle = nil;
        
        // not sure if we need to send this. the all albums refresh is always sent after this
        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self];
    }
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
