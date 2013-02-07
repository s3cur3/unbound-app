//
//  PIXAlbum.h
//  UnboundApp
//
//  Created by Bob on 1/8/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PIXThumbnailLoadingDelegate.h"

@class PIXAccount, PIXPhoto;

@interface PIXAlbum : NSManagedObject <PIXThumbnailLoadingDelegate>
{
//    @private
//    PIXPhoto *_mostRecentPhoto;
//    NSDate *_dateMostRecentPhoto;
    NSImage *_thumbnailImage;
}

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) NSDate * dateLastUpdated;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSOrderedSet *photos;
@property (nonatomic, retain) PIXAccount *account;
@property (nonatomic, retain) NSData * thumbnail;
@property (nonatomic, retain) PIXPhoto *coverPhoto;
@property (nonatomic, retain) NSArray *stackPhotos;
@property (nonatomic, retain) NSDate * albumDate;

-(void)setPhotos:(NSOrderedSet *)photos updateCoverImage:(BOOL)shouldUpdateCoverImage;

-(void)cancelThumbnailLoading;

-(void)updateCoverPhoto;
-(void)updateAlbumBecausePhotosDidChange;

//
//@property (nonatomic, strong, readonly) NSDate *dateMostRecentPhoto;
//@property (nonatomic, strong, readonly) PIXPhoto *mostRecentPhoto;


//@property (nonatomic, retain, readonly) NSEntityDescription *photoEntityDescription;
//@property (nonatomic, retain, readonly) NSExpressionDescription *expressionDescription;

//@property (nonatomic, strong)   NSDate *dateLastScanned;
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

@interface PIXAlbum(Customizations)

//fetches photo with the most recent dateLastModified
//- (PIXPhoto *)fetchMostRecentPhoto;

//non-core data
- (NSURL *)filePathURL;
- (NSImage *)thumbnailImage;
- (NSString *) imageSubtitle;


@end
