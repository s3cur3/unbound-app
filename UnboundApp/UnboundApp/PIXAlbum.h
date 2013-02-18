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

@class PIXAccount, PIXPhoto;

@interface PIXAlbum : NSManagedObject<PIXThumbnailLoadingDelegate, NSPasteboardWriting>
{
    //    @private
    //    PIXPhoto *_mostRecentPhoto;
    //    NSDate *_dateMostRecentPhoto;

}

@property (nonatomic, retain) NSDate * albumDate;
@property (nonatomic, retain) NSDate * dateLastUpdated;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) NSData * thumbnail;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) PIXAccount *account;
@property (nonatomic, retain) PIXPhoto *datePhoto;
@property (nonatomic, retain) NSOrderedSet *photos;
@property (nonatomic, retain) NSOrderedSet *stackPhotos;
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

-(void)setPhotos:(NSOrderedSet *)photos updateCoverImage:(BOOL)shouldUpdateCoverImage;

-(void)cancelThumbnailLoading;

-(void)updateDatePhoto;
-(void)updateAlbumBecausePhotosDidChange;

//non-core data
- (NSURL *)filePathURL;
- (NSString *) imageSubtitle;

-(void) flush;


@end
