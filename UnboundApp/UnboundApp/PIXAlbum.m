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


@implementation PIXAlbum

@dynamic dateLastUpdated;
@dynamic path;
@dynamic photos;
@dynamic account;
@dynamic title;
@dynamic subtitle;

- (NSURL *)filePathURL
{
    return [NSURL fileURLWithPath:self.path isDirectory:YES];
}

- (NSImage *)thumbnailImage
{
    return [NSImage imageNamed:@"nophoto"];
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

@end
