//
//  NSURL+DirectoryObserver.m
//  Packer
//
//  Created by Brent Royal-Gordon on 1/2/11.
//  Copyright 2011 Architechies. All rights reserved.
//

#import "NSURL+DirectoryObserver.h"
#import "ArchDirectoryObservationCenter.h"

@implementation NSURL (DirectoryObserver)

- (void)addDirectoryObserver:(id <ArchDirectoryObserver>)observer options:(ArchDirectoryObserverOptions)options resumeToken:(id)resumeToken {
    BOOL ignoresSelf =  !(options & ArchDirectoryObserverObservesSelf);
    BOOL responsive  = !!(options & ArchDirectoryObserverResponsive);
    
    [[ArchDirectoryObservationCenter mainObservationCenter] addObserver:observer forDirectoryAtURL:self ignoresSelf:ignoresSelf responsive:responsive resumeToken:resumeToken];
}

- (void)removeDirectoryObserver:(id <ArchDirectoryObserver>)observer {
    [[ArchDirectoryObservationCenter mainObservationCenter] removeObserver:observer forDirectoryAtURL:self];
}

+ (void)removeObserverForAllDirectories:(id <ArchDirectoryObserver>)observer {
    [[ArchDirectoryObservationCenter mainObservationCenter] removeObserverForAllDirectories:observer];
}

+ (ArchDirectoryObservationResumeToken)laterOfDirectoryObservationResumeToken:(ArchDirectoryObservationResumeToken)token1 andResumeToken:(ArchDirectoryObservationResumeToken)token2 {
    return [[ArchDirectoryObservationCenter mainObservationCenter] laterOfResumeToken:token1 andResumeToken:token2];
}

@end
