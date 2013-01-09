//
//  PIXThumbnail.h
//  UnboundApp
//
//  Created by Bob on 1/8/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PIXPhoto;

@interface PIXThumbnail : NSManagedObject

@property (nonatomic, retain) NSData * imageData;
@property (nonatomic, retain) PIXPhoto *photo;

@end
