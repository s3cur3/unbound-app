//
//  PIXGetAlbumPathsOperation.h
//  UnboundApp
//
//  Created by Bob on 1/22/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PIXGetAlbumPathsOperation : NSOperation

- (id)initWithRootURL:(NSURL *)url queue:(NSOperationQueue *)qq scanCount:(NSInteger)scanCount;

@end
