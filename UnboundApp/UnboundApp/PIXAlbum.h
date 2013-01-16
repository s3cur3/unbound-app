//
//  PIXAlbum.h
//  UnboundApp
//
//  Created by Bob on 1/8/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PIXAccount, PIXPhoto;

@interface PIXAlbum : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) NSDate * dateLastUpdated;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSOrderedSet *photos;
@property (nonatomic, retain) PIXAccount *account;

//non-core data

- (NSURL *)filePathURL;
- (NSImage *)thumbnailImage;
- (NSString *) imageSubtitle;

//@property (nonatomic, strong)   NSDate *dateLastScanned;
@property (nonatomic, strong)   NSDate *dateMostRecentPhoto;
//@property (nonatomic, strong)   NSString *filePath;
//@property (nonatomic, strong)   NSURL *filePathURL;
//@property (nonatomic, strong)   NSImage *thumbnailImage;

@end

@interface PIXAlbum (CoreDataGeneratedAccessors)

- (void)insertObject:(PIXPhoto *)value inPhotosAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPhotosAtIndex:(NSUInteger)idx;
- (void)insertPhotos:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePhotosAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPhotosAtIndex:(NSUInteger)idx withObject:(PIXPhoto *)value;
- (void)replacePhotosAtIndexes:(NSIndexSet *)indexes withPhotos:(NSArray *)values;
- (void)addPhotosObject:(PIXPhoto *)value;
- (void)removePhotosObject:(PIXPhoto *)value;
- (void)addPhotos:(NSOrderedSet *)values;
- (void)removePhotos:(NSOrderedSet *)values;
@end
