//
//  PIXAlbum.h
//  UnboundApp
//
//  Created by Scott Sykora on 2/7/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PIXThumbnailLoadingDelegate.h"

@class PIXPhoto;

typedef enum {
    
    PIXAlbumSortNewToOld = 0,
    PIXAlbumSortOldToNew = 1,
    PIXAlbumSortAtoZ = 2,
    PIXAlbumSortZtoA = 3
    
} PIXAlbumSort;

typedef enum {
    
    PIXPhotoSortNewToOld = 0,
    PIXPhotoSortOldToNew = 1,
    PIXPhotoSortAtoZ = 2,
    PIXPhotoSortZtoA = 3
    
} PIXPhotoSort;

@interface PIXAlbum : NSManagedObject<PIXThumbnailLoadingDelegate>
{
    //    @private
    //    PIXPhoto *_mostRecentPhoto;
    //    NSDate *_dateMostRecentPhoto;

}

@property (nonatomic, retain) NSDate * albumDate;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSDate * dateLastUpdated;
@property (nonatomic, retain) NSDate * dateReadUnboundFile;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) PIXPhoto *datePhoto;
@property (nonatomic, retain) NSSet<PIXPhoto *> *photos;
@property (nonatomic, retain) NSOrderedSet<PIXPhoto *> *stackPhotos;
@property (nonatomic, retain) NSNumber *needsDateScan;
@end

@interface PIXAlbum (CoreDataGeneratedAccessors)

// photos
- (void)addPhotosObject:(PIXPhoto *)value;
- (void)removePhotosObject:(PIXPhoto *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

// stack photos
- (void)insertObject:(PIXPhoto *)value inStackPhotosAtIndex:(NSUInteger)idx;
- (void)removeObjectFromStackPhotosAtIndex:(NSUInteger)idx;
- (void)insertStackPhotos:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeStackPhotosAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInStackPhotosAtIndex:(NSUInteger)idx withObject:(PIXPhoto *)value;
- (void)replaceStackPhotosAtIndexes:(NSIndexSet *)indexes withStackPhotos:(NSArray *)values;
- (void)addStackPhotosObject:(PIXPhoto *)value;
- (void)removeStackPhotosObject:(PIXPhoto *)value;
- (void)addStackPhotos:(NSOrderedSet *)values;
- (void)removeStackPhotos:(NSOrderedSet *)values;
@end


@interface PIXAlbum(Customizations)

//fetches photo with the most recent dateLastModified
//- (PIXPhoto *)fetchMostRecentPhoto;


+(NSArray *)sortedAlbums;
+(NSArray *)sortedAlbums:(NSString *)filterString;

-(void)setPhotos:(NSSet *)photos updateCoverImage:(BOOL)shouldUpdateCoverImage;

-(NSArray<PIXPhoto *> *)sortedPhotos;
-(NSArray *)photoSortDescriptors;

-(void)updateDatePhoto;
//-(void)updateAlbumBecausePhotosDidChange;

//non-core data
- (NSURL *)filePathURL;
- (NSString *) imageSubtitle;

-(void) flush;
-(void) checkDates;
-(void) updateUnboundFile;
-(void) updateUnboundFileinBackground;

-(void) setUnboundFileCaptionForPhoto:(PIXPhoto *)photo;

-(BOOL) isReallyDeleted;


@end
