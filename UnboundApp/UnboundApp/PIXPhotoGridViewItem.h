//
//  PIXPhotoGridViewItem.h
//  UnboundApp
//
//  Created by Scott Sykora on 1/30/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXGridViewItem.h"

@class PIXPhoto;

@interface PIXPhotoGridViewItem : PIXGridViewItem

@property (strong, nonatomic) PIXPhoto * photo;

+(NSImage *)dragImageForPhotos:(NSArray *)photoArray size:(NSSize)size;

@end
