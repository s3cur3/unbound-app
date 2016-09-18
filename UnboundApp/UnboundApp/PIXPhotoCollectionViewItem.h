//
//  PIXPhotoCollectionViewItem.h
//  UnboundApp
//
//  Created by Ditriol Wei on 14/9/16.
//  Copyright © 2016 Pixite Apps LLC. All rights reserved.
//

#import "PIXCollectionViewItem.h"

@interface PIXPhotoCollectionViewItem : PIXCollectionViewItem

@end

@class PIXPhoto;
@interface PIXPhotoCollectionViewItemView : PIXCollectionViewItemView

@property (strong, nonatomic) PIXPhoto * photo;

+(NSImage *)dragImageForPhotos:(NSArray *)photoArray size:(NSSize)size;

@end