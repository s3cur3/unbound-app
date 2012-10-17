//
//  Album.h
//  Unbound5
//
//  Created by Bob on 10/10/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCEvents.h"

extern NSString *AlbumDidChangeNotification;

/*
 * A class representing an album of photos backed by image files contained
 * in a common directory on the file system.
 */

@interface Album : NSObject <SCEventListenerProtocol>
{
    
}

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) SCEvents *events;

- (id)initWithFilePath:(NSString *) aPath;
-(void)addPhotosObject:(id)object;
-(void)updatePhotosFromFileSystem;

@end
