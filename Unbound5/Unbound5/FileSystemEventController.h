//
//  FileSystemEventController.h
//  Unbound5
//
//  Created by Bob on 10/17/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ArchDirectoryObserver/ArchDirectoryObserver.h>

@interface FileSystemEventController : NSObject <ArchDirectoryObserver>
{
    
}

@property (copy) NSURL *rootFilePathURL;
@property (weak) NSDictionary *albumLookupTable;

-(id)initWithPath:(NSURL *)aFilePathURL
      albumsTable:(NSDictionary *)anAlbumsDict;

-(void)startObserving;
-(void)stopObserving;

@end
