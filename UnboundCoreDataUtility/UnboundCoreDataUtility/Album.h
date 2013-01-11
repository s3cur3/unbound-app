//
//  Album.h
//  UnboundCoreDataUtility
//
//  Created by Bob on 1/7/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo;

@interface Album : NSManagedObject
{
    NSImage *_thumbnailImage;
}

@property (nonatomic, retain) NSDate * dateLastModified;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSData * thumbnail;
@property (nonatomic, retain) NSDate * dateLastUpdated;
@property (nonatomic, retain) NSOrderedSet *photos;

-(NSImage *)thumbnailImage;

@end

@interface Album (CoreDataGeneratedAccessors)

- (void)insertObject:(Photo *)value inPhotosAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPhotosAtIndex:(NSUInteger)idx;
- (void)insertPhotos:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePhotosAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPhotosAtIndex:(NSUInteger)idx withObject:(Photo *)value;
- (void)replacePhotosAtIndexes:(NSIndexSet *)indexes withPhotos:(NSArray *)values;
- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSOrderedSet *)values;
- (void)removePhotos:(NSOrderedSet *)values;
@end
