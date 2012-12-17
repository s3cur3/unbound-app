//
//  PIXDataSource.h
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PIXFileSystemDataSource.h"
//@class PIXFileSystemDataSource;

@interface PIXDataSource : NSObject

+ (PIXFileSystemDataSource *)fileSystemDataSource;

@end
