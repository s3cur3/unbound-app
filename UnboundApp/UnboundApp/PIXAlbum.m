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
#import "PIXDefines.h"


@implementation PIXAlbum

@dynamic dateLastUpdated;
@dynamic path;
@dynamic photos;
@dynamic account;
@dynamic title;
@dynamic subtitle;
@dynamic thumbnail;

@dynamic dateMostRecentPhoto;

// invoked after a fetch or after unfaulting (commonly used for computing derived values from the persisted properties)
-(void)awakeFromFetch
{
    [super awakeFromFetch];
//    if (self.photos != nil) {
//        NSDate *aDate = [self dateMostRecentPhoto];
//        DLog(@"%@", aDate);
//    }
}

/* Callback before delete propagation while the object is still alive.  Useful to perform custom propagation before the relationships are torn down or reconfigure KVO observers. */
- (void)prepareForDeletion
{
    [super prepareForDeletion];
}

- (NSURL *)filePathURL
{
    return [NSURL fileURLWithPath:self.path isDirectory:YES];
}

- (NSImage *)thumbnailImage
{
    if (_thumbnailImage == nil && self.photos != nil)
    {
        PIXPhoto *aPhoto = [self mostRecentPhoto];
        if (aPhoto!=nil) {
            if (aPhoto.thumbnailImage)
            _thumbnailImage = aPhoto.thumbnailImage;
        }
    } else if (self.photos==nil || self.photos.count==0) {
        return [NSImage imageNamed:@"nophoto"];
    }
    return _thumbnailImage;
    
}

- (NSString *) imageSubtitle;
{
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

-(PIXPhoto *)mostRecentPhoto
{
    if (_mostRecentPhoto == nil && self.photos != nil)
    {
        _mostRecentPhoto = [self fetchMostRecentPhoto];
    }
    return _mostRecentPhoto;
}

-(NSDate *)dateMostRecentPhoto
{
    if (_dateMostRecentPhoto == nil && self.photos != nil)
    {
        PIXPhoto *aPhoto = [self mostRecentPhoto];
        if (aPhoto!=nil) {
            _dateMostRecentPhoto = aPhoto.dateLastModified;
        }
    }
    return _dateMostRecentPhoto;
}

-(PIXPhoto *)fetchMostRecentPhoto
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PIXPhoto"];
    
    fetchRequest.fetchLimit = 1;
    fetchRequest.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"dateLastModified" ascending:NO]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"album == %@", self];
    [fetchRequest setPredicate:predicate];
    NSError *error = nil;
    
    id photo = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error].lastObject;
    return (PIXPhoto *)photo;
}

-(PIXPhoto *)fetchMostRecentPhotoOld
{
    NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:@"dateLastModified"];
    NSExpression *maxDateExpression = [NSExpression expressionForFunction:@"max:"
                                                                arguments:[NSArray arrayWithObject:keyPathExpression]];
    
    NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
    [expressionDescription setName:@"mostRecent"];
    [expressionDescription setExpression:maxDateExpression];
    [expressionDescription setExpressionResultType:NSDateAttributeType];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:kPhotoEntityName];
    [request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    id aResult = [results lastObject];
    if (aResult==nil) {
        DLog(@"%@", error);
        return nil;
    }
    return (PIXPhoto *)aResult;
}

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

//- (void)addPhotoObject:(PIXPhoto *)value
//{    
//    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
//    [self willChangeValueForKey:@"photos" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
//    [[self primitiveValueForKey:@"photos"] addObject:value];
//    [self didChangeValueForKey:@"photos" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
//}
//
//- (void)removePhotoObject:(PIXPhoto *)value
//{
//    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
//    [self willChangeValueForKey:@"photos" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
//    [[self primitiveValueForKey:@"photos"] removeObject:value];
//    [self didChangeValueForKey:@"photos" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
//}
//
//- (void)addPhotos:(NSSet *)values
//{
//    [self willChangeValueForKey:@"photos" withSetMutation:NSKeyValueUnionSetMutation usingObjects:values];
//    [[self primitiveValueForKey:@"photos"] unionSet:values];
//    [self didChangeValueForKey:@"photos" withSetMutation:NSKeyValueUnionSetMutation usingObjects:values];
//}
//
//- (void)removePhotos:(NSSet *)values
//{
//    [self willChangeValueForKey:@"photos" withSetMutation:NSKeyValueMinusSetMutation usingObjects:values];
//    [[self primitiveValueForKey:@"photos"] minusSet:values];
//    [self didChangeValueForKey:@"photos" withSetMutation:NSKeyValueMinusSetMutation usingObjects:values];
//}

//NSKeyValueSetSetMutation
/*-(void)setPhotos:(NSSet *)values
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
