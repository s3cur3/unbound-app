//
//  ArchDirectoryObserver.m
//  Packer
//
//  Created by Brent Royal-Gordon on 12/29/10.
//  Copyright 2010 Architechies. All rights reserved.
//

#import "ArchDirectoryObservationCenter.h"

@interface ArchDirectoryEventStream : NSObject {
    @private
    NSURL * URL;
    FSEventStreamRef eventStream;
    id <ArchDirectoryObserver> observer;
    ArchDirectoryObservationCenter * center;
    BOOL historical;
}

- (id)initWithObserver:(id<ArchDirectoryObserver>)obs center:(ArchDirectoryObservationCenter*)cent directoryURL:(NSURL *)url ignoresSelf:(BOOL)ignoresSelf responsive:(BOOL)responsive resumeAtEventID:(FSEventStreamEventId)eventID;

@property (readonly) ArchDirectoryObservationCenter * center;
@property (readonly) NSURL * URL;
@property (readonly) FSEventStreamEventId lastEventID;
@property (readonly) FSEventStreamRef eventStream;
@property (readonly) id <ArchDirectoryObserver> observer;
@property (assign) BOOL historical;

@end

@implementation ArchDirectoryObservationCenter

+ (ArchDirectoryObservationCenter*)mainObservationCenter {
    static ArchDirectoryObservationCenter * singleton;
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        singleton = [[ArchDirectoryObservationCenter alloc] initWithRunLoop:[NSRunLoop mainRunLoop]];
    });
    
    return singleton;
}

@synthesize runLoop;

- (id)initWithRunLoop:(NSRunLoop*)rloop {
    if ((self = [super init])) {
        runLoop = rloop;
        eventStreams = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (ArchDirectoryEventStream*)eventStreamWithObserver:(id<ArchDirectoryObserver>)observer forDirectoryAtURL:(NSURL*)url {
    for(ArchDirectoryEventStream * eventStream in eventStreams) {
        if(observer == eventStream.observer && [url isEqual:eventStream.URL]) {
            return eventStream;
        }
    }
    
    return nil;
}

- (id)resumeTokenForEventID:(FSEventStreamEventId)eventID {
    return [NSKeyedArchiver archivedDataWithRootObject:[NSNumber numberWithUnsignedLongLong:eventID]];
}

- (FSEventStreamEventId)eventIDForResumeToken:(ArchDirectoryObservationResumeToken)token {
    if(token == nil || token == [NSNull null]) {
        return kFSEventStreamEventIdSinceNow;
    }
    
    return [[NSKeyedUnarchiver unarchiveObjectWithData:(NSData*)token] unsignedLongLongValue];
}

- (ArchDirectoryObservationResumeToken)laterOfResumeToken:(ArchDirectoryObservationResumeToken)token1 andResumeToken:(ArchDirectoryObservationResumeToken)token2 {
    if([self eventIDForResumeToken:token1] > [self eventIDForResumeToken:token2]) {
        return token1;
    }
    else {
        return token2;
    }
}

- (void)addObserver:(id<ArchDirectoryObserver>)observer forDirectoryAtURL:(NSURL *)url ignoresSelf:(BOOL)ignoresSelf responsive:(BOOL)responsive resumeToken:(id)resumeToken {
    if([self eventStreamWithObserver:observer forDirectoryAtURL:url]) {
        @throw [NSException exceptionWithName:NSRangeException
                                       reason:[NSString stringWithFormat:@"The observer %@ is already observing the directory %@.", observer, url]
                                     userInfo:nil];
    }
    
    FSEventStreamEventId eventID = [self eventIDForResumeToken:resumeToken];
    
    ArchDirectoryEventStream * eventStream = [[ArchDirectoryEventStream alloc] initWithObserver:observer center:self directoryURL:url ignoresSelf:ignoresSelf responsive:responsive resumeAtEventID:eventID];
    
    [eventStreams addObject:eventStream];
}

- (void)removeObserver:(id<ArchDirectoryObserver>)observer forDirectoryAtURL:(NSURL *)url {
    ArchDirectoryEventStream * eventStream = [self eventStreamWithObserver:observer forDirectoryAtURL:url];
    
    if(!eventStream) {
        @throw [NSException exceptionWithName:NSRangeException
                                       reason:[NSString stringWithFormat:@"The observer %@ is not observing the directory %@.", observer, url]
                                     userInfo:nil];

    }
    
    [eventStreams removeObject:eventStream];
}

- (void)removeObserverForAllDirectories:(id <ArchDirectoryObserver>)observer {
    NSMutableIndexSet * doomedIndexes = [NSMutableIndexSet indexSet];
    
    [eventStreams enumerateObjectsUsingBlock:^(ArchDirectoryEventStream * stream, NSUInteger idx, BOOL *stop) {
        if(stream.observer == observer) {
            [doomedIndexes addIndex:idx];
        }
    }];
    
    [eventStreams removeObjectsAtIndexes:doomedIndexes];
}

@end

@implementation ArchDirectoryEventStream

@synthesize center, eventStream, observer, URL, historical;

const FSEventStreamEventFlags kArchDirectoryEventStreamNeedsDescendantScanMask = kFSEventStreamEventFlagMustScanSubDirs | kFSEventStreamEventFlagMount | kFSEventStreamEventFlagUnmount | kFSEventStreamEventFlagEventIdsWrapped;

static void ArchDirectoryEventStreamCallback(
                                      const FSEventStreamRef streamRef,
                                      void * context,
                                      size_t numEvents,
                                      NSArray * eventPaths,
                                      const FSEventStreamEventFlags eventFlags[],
                                      const FSEventStreamEventId eventIds[]) {
    ArchDirectoryEventStream * self = (__bridge id)context;
    
    for(size_t i = 0; i < numEvents; i++) {
        NSURL * thisEventURL = [NSURL fileURLWithPath:[eventPaths objectAtIndex:i]];
        FSEventStreamEventFlags thisEventFlags = eventFlags[i];
        id thisResumeToken = [self.center resumeTokenForEventID:eventIds[i]];
        
        if(thisEventFlags & kFSEventStreamEventFlagHistoryDone) {
            self.historical = NO;
        }
        else if(thisEventFlags & kArchDirectoryEventStreamNeedsDescendantScanMask) {
            ArchDirectoryObserverDescendantReason reason = ArchDirectoryObserverCoalescedReason;
            
            if(thisEventFlags & (kFSEventStreamEventFlagKernelDropped | kFSEventStreamEventFlagUserDropped)) {
                reason = ArchDirectoryObserverEventDroppedReason;
            }
            else if(thisEventFlags & kFSEventStreamEventFlagMount) {
                reason = ArchDirectoryObserverVolumeMountedReason;
            }
            else if(thisEventFlags & kFSEventStreamEventFlagUnmount) {
                reason = ArchDirectoryObserverVolumeUnmountedReason;
            }
            else if(thisEventFlags & kFSEventStreamEventFlagEventIdsWrapped) {
                reason = ArchDirectoryObserverEventIDsWrappedReason;
            }
            
            [self.observer observedDirectory:self.URL descendantsAtURLDidChange:thisEventURL reason:reason historical:self.historical resumeToken:thisResumeToken];
        }
        else if(thisEventFlags & kFSEventStreamEventFlagRootChanged) {
            [self.observer observedDirectory:self.URL ancestorAtURLDidChange:thisEventURL historical:self.historical resumeToken:thisResumeToken];
        }
        else {
            [self.observer observedDirectory:self.URL childrenAtURLDidChange:thisEventURL historical:self.historical resumeToken:thisResumeToken];
        }
    }
}

- (id)initWithObserver:(id<ArchDirectoryObserver>)obs center:(ArchDirectoryObservationCenter*)cent directoryURL:(NSURL *)url ignoresSelf:(BOOL)ignoresSelf responsive:(BOOL)responsive resumeAtEventID:(FSEventStreamEventId)eventID {
    if((self = [super init])) {
        center = cent;
        observer = obs;
        URL = [url copy];
        
        FSEventStreamContext context;
        context.copyDescription = NULL;
        context.release = NULL;
        context.retain = NULL;
        context.version = 0;
        context.info = (__bridge void*)self;
        
        FSEventStreamCreateFlags flags = kFSEventStreamCreateFlagWatchRoot | kFSEventStreamCreateFlagUseCFTypes;
        CFTimeInterval latency = 5.0;
    
        if(ignoresSelf) {
            flags |= kFSEventStreamCreateFlagIgnoreSelf;
        }
        if(responsive) {
            latency = 1.0;
            flags |= kFSEventStreamCreateFlagNoDefer;
        }
        
        eventStream = FSEventStreamCreate(NULL, (FSEventStreamCallback)ArchDirectoryEventStreamCallback, &context, (__bridge CFArrayRef)[NSArray arrayWithObject:[url path]], eventID, latency, flags);
        
        FSEventStreamScheduleWithRunLoop(eventStream, [center.runLoop getCFRunLoop], kCFRunLoopCommonModes);
        
        FSEventStreamStart(eventStream);
        
        if(eventID == kFSEventStreamEventIdSinceNow) {
            [observer observedDirectory:URL descendantsAtURLDidChange:URL reason:ArchDirectoryObserverNoHistoryReason historical:YES resumeToken:[self.center resumeTokenForEventID:eventID]];
        }
        else {
            historical = YES;
        }
    }
    
    return self;
}

- (FSEventStreamEventId)lastEventID {
    return FSEventStreamGetLatestEventId(self.eventStream);
}

- (void)finalize {
    FSEventStreamStop(eventStream);
    FSEventStreamInvalidate(eventStream);
    FSEventStreamRelease(eventStream);
}

- (void)dealloc {
    FSEventStreamStop(eventStream);
    FSEventStreamInvalidate(eventStream);
    FSEventStreamRelease(eventStream);
}

@end
