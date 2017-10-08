//
//  PIXThumbnailLoadingDelegate.h
//  UnboundApp
//
//  Created by Bob on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#ifndef UnboundApp_PIXThumbnailLoadingDelegate_h
#define UnboundApp_PIXThumbnailLoadingDelegate_h

@protocol PIXThumbnailLoadingDelegate

-(NSImage *)thumbnailImage;

@optional

-(void)cancelThumbnailLoading;

@end

#endif
