//
//  PIXPhotoCollectionViewItem.h
//  UnboundApp
//
//  Created by Ditriol Wei on 14/9/16.
//  Copyright © 2016 Pixite Apps LLC. All rights reserved.
//

#import "PIXCollectionViewItem.h"

@class PIXPhoto;

@interface PIXPhotoCollectionViewItem : PIXCollectionViewItem

@end

@interface PIXPhotoCollectionViewItemView : PIXCollectionViewItemView

@property (strong, nonatomic) PIXPhoto * photo;

+(NSImage *)dragImageForPhotos:(NSArray<PIXPhoto *> *)photoArray size:(NSSize)size;
+(NSImage *)dragImageForPhotos:(NSArray<PIXPhoto *> *)photoArray count:(NSUInteger)count size:(NSSize)size;

@end