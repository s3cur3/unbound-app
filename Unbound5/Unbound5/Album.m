//
//  Album.m
//  Unbound5
//
//  Created by Bob on 10/10/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "Album.h"

@implementation Album
/*- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"Untitled";
    }
    return self;
}*/

- (id)initWithFilePath:(NSString *) aPath
{
    self = [super init];
    if (self) {
        self.filePath = aPath;
        self.title = [aPath lastPathComponent];
        self.photos = [NSMutableArray array];
    }
    return self;
}

-(void)addPhotosObject:(id)object
{
    [self.photos addObject:object];
}
@end
