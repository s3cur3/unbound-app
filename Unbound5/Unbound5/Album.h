//
//  Album.h
//  Unbound5
//
//  Created by Bob on 10/10/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "SCEvents.h"
@class FileSystemEventController;

extern NSString *AlbumDidChangeNotification;
enum {
    AlbumStateThumbnailLoading = 1 << 1,
    AlbumStateThumbnailLoaded = 1 << 2,
    AlbumStateImageLoading = 1 << 3,
    AlbumStateImageLoaded = 1 << 3,
};

/*
 * A class representing an album of photos backed by image files contained
 * in a common directory on the file system.
 */

@interface Album : NSObject
{
@private
    //NSImage *_thumbnailImage;
    NSInteger _state;
    NSSize _imageSize;
    NSSortDescriptor *_dateLastModifiedSortDescriptor;
}

@property (strong) FileSystemEventController *fileSystemEventController;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSDate *dateLastScanned;
@property (nonatomic, strong) NSImage *thumbnailImage;

//@property NSSize imageSize;

- (id)initWithFilePath:(NSString *) aPath;
-(void)addPhotosObject:(id)object;
-(void)updatePhotosFromFileSystem;
-(BOOL)albumExistsWithPhotos;

-(NSSortDescriptor *) dateLastModifiedSortDescriptor;

/* The thumbnail image may return nil if it isn't loaded. The first access of it will request it to load.
 */
- (NSImage *)thumbnailImage;
- (NSString *) imageSubtitle;

@end
