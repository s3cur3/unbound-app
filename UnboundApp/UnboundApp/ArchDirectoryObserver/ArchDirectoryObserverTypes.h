//
//  ArchDirectoryObserverTypes.h
//  ArchDirectoryObserver
//
//  Created by Brent Royal-Gordon on 2/19/12.
//  Copyright (c) 2012 Architechies. All rights reserved.
//

#import <Foundation/Foundation.h>

// This opaque token is used to resume observation at a given point in time.  Each ArchDirectoryObserver callback passes you one; if you save it (in a plist or NSCoder archive) and pass it back in when registering the observer, observation will pick up where it left off, even if the process has quit since then.
typedef id <NSCopying, NSCoding> ArchDirectoryObservationResumeToken;


// These constants indicate the reason that the observation center believes a descendant scan is needed.
typedef enum {
    // You added an observer with a nil resume token, so the directory's history is unknown.
    ArchDirectoryObserverNoHistoryReason = 0,
    // The observation center coalesced events that occurred only a couple seconds apart.
    ArchDirectoryObserverCoalescedReason,
    // Events came too fast and some were dropped.
    ArchDirectoryObserverEventDroppedReason,
    // Event ID numbers have wrapped and so the history is not reliable.
    ArchDirectoryObserverEventIDsWrappedReason,
    // A volume was mounted in a subdirectory.
    ArchDirectoryObserverVolumeMountedReason,
    // A volume was unmounted in a subdirectory.
    ArchDirectoryObserverVolumeUnmountedReason
} ArchDirectoryObserverDescendantReason;

@protocol ArchDirectoryObserver <NSObject>

// At least one file in the directory indicated by changedURL has changed.  You should examine the directory at changedURL to see which files changed.
// observedURL: the URL of the dorectory you're observing.
// changedURL: the URL of the actual directory that changed. This could be a subdirectory.
// historical: if YES, the event occured sometime before the observer was added.  If NO, it occurred just now.
// resumeToken: the resume token to save if you want to pick back up from this event.
- (void)observedDirectory:(NSURL*)observedURL childrenAtURLDidChange:(NSURL*)changedURL historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken;

// At least one file somewhere inside--but not necessarily directly descended from--changedURL has changed.  You should examine the directory at changedURL and all subdirectories to see which files changed.
// observedURL: the URL of the dorectory you're observing.
// changedURL: the URL of the actual directory that changed. This could be a subdirectory.
// reason: the reason the observation center can't pinpoint the changed directory.  You may want to ignore some reasons--for example, "ArchDirectoryObserverNoHistoryReason" simply means that you didn't pass a resume token when adding the observer, and so you should do an initial scan of the directory.
// historical: if YES, the event occured sometime before the observer was added.  If NO, it occurred just now.
// resumeToken: the resume token to save if you want to pick back up from this event.
- (void)observedDirectory:(NSURL*)observedURL descendantsAtURLDidChange:(NSURL*)changedURL reason:(ArchDirectoryObserverDescendantReason)reason historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken;

// An ancestor of the observedURL has changed, so the entire directory tree you're observing may have vanished. You should ensure it still exists.
// observedURL: the URL of the dorectory you're observing.
// changedURL: the URL of the actual directory that changed. For this call, it will presumably be an ancestor directory.
// historical: if YES, the event occured sometime before the observer was added.  If NO, it occurred just now.
// resumeToken: the resume token to save if you want to pick back up from this event.
- (void)observedDirectory:(NSURL*)observedURL ancestorAtURLDidChange:(NSURL*)changedURL historical:(BOOL)historical resumeToken:(ArchDirectoryObservationResumeToken)resumeToken;

@end
