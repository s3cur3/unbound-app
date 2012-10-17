//
//  NSURL+DirectoryObserver.h
//  Packer
//
//  Created by Brent Royal-Gordon on 1/2/11.
//  Copyright 2011 Architechies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ArchDirectoryObserverTypes.h"

typedef enum {
    // Receive events for this process's actions.  If absent, file system changes initiated by the current process will not cause the directory observer to be notified.
    ArchDirectoryObserverObservesSelf = 1,
    // Favor quicker notifications over reduced number of notifications.
    // If this flag is ABSENT, a timer is started upon the first change, and after five seconds, an observation for all changes during that period is delivered.
    // If this flag is PRESENT, an observation is sent immediately upon the first change; then a 1 second timer is started, and a second observation is delivered for all changes during that period.
    // Use this flag if you're going to refresh an on-screen list or otherwise show the user that things have changed.
    ArchDirectoryObserverResponsive = 2
} ArchDirectoryObserverOptions;

@interface NSURL (DirectoryObserver)

// Start observing this URL.
// observer: the object to send observation messages to.
// options: modifies the observation's characteristics.  See ArchDirectoryObserverOptions above for more details.
// resumeToken: if you're interested in what has happened to this folder since your app last stopped observing it, pass in the last resume token your directory observer received.  If you don't, pass nil (and ignore the callback with a NoHistory reason).
// NOTE: Observation is currently only done on the main thread (and particularly, the main run loop).  To use other run loops, you'll need to create your own ArchDirectoryObservationCenter and go from there.
- (void)addDirectoryObserver:(id <ArchDirectoryObserver>)observer options:(ArchDirectoryObserverOptions)options resumeToken:(ArchDirectoryObservationResumeToken)resumeToken;

// Remove the observer.  You should do this in dealloc—ArchDirectoryObserver does not use weak pointers.
- (void)removeDirectoryObserver:(id <ArchDirectoryObserver>)observer;

// Class method to remove all observations using a given observer.
+ (void)removeObserverForAllDirectories:(id <ArchDirectoryObserver>)observer;

// Utility method; given two resume tokens, returns the one that represents a later point in time.  You may find this useful when saving resume tokens.
+ (ArchDirectoryObservationResumeToken)laterOfDirectoryObservationResumeToken:(ArchDirectoryObservationResumeToken)token1 andResumeToken:(ArchDirectoryObservationResumeToken)token2;

@end

