//
//  PIXDataSource.m
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXDataSource.h"

@implementation PIXDataSource

+ (PIXFileSystemDataSource *)fileSystemDataSource;
{
    return [PIXFileSystemDataSource sharedInstance];
}

@end
