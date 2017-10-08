//
//  ArchDirectoryObserver.h
//  Packer
//
//  Created by Brent Royal-Gordon on 12/29/10.
//  Copyright 2010 Architechies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import "ArchDirectoryObserverTypes.h"

// The observation center is where all the action happens.  You usually only need to work with it if you want to observe on a background thread.  The interface is not terribly different from the NSURL (DirectoryObserver) category.

@interface ArchDirectoryObservationCenter : NSObject {
@private
    NSMutableArray * eventStreams;
    NSRunLoop * runLoop;
}

+ (ArchDirectoryObservationCenter*)mainObservationCenter;

- (id)initWithRunLoop:(NSRunLoop*)runLoop;

@property (readonly) NSRunLoop * runLoop;

// We will retain the url, but you have to retain the observer.
- (void)addObserver:(id <ArchDirectoryObserver>)observer forDirectoryAtURL:(NSURL*)url ignoresSelf:(BOOL)ignoresSelf responsive:(BOOL)responsive resumeToken:(id)resumeToken;
- (void)removeObserver:(id <ArchDirectoryObserver>)observer forDirectoryAtURL:(NSURL*)url;
- (void)removeObserverForAllDirectories:(id <ArchDirectoryObserver>)observer;

- (ArchDirectoryObservationResumeToken)laterOfResumeToken:(ArchDirectoryObservationResumeToken)token1 andResumeToken:(ArchDirectoryObservationResumeToken)token2;

@end

