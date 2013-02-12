//
//  PIXFileManager.h
//  UnboundApp
//
//  Created by Bob on 1/31/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PIXFileManager : NSObject

+(PIXFileManager *)sharedInstance;

-(void)moveFiles:(NSArray *)items;
-(void)copyFiles:(NSArray *)items;

- (NSMenu *)openWithMenuItemForFile:(NSString *)filePath;

@end
