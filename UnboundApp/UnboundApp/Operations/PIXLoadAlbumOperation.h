//
//  PIXLoadAlbumOperation.h
//  UnboundApp
//
//  Created by Bob on 1/22/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

//// key for obtaining the current scan count
//extern NSString *kScanCountKey;
//
//// key for obtaining the path of an image
//extern NSString *kPathKey;

// NSNotification name to tell the Window controller an image file as found
extern NSString *kLoadAlbumDidFinish;

@interface PIXLoadAlbumOperation : NSOperation

//- (id)initWithURL:(NSURL *)url scanCount:(NSInteger)scanCount;

- (id)initWithRootURL:(NSURL *)url queue:(NSOperationQueue *)qq scanCount:(NSInteger)scanCount;

@end
