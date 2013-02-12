//
//  PIXFileSystemDataSource.h
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ArchDirectoryObserver.h"

@interface PIXFileSystemDataSource : NSObject <ArchDirectoryObserver>
{
    NSUInteger scanCount;
    NSMutableArray *tableRecords;    // the data source for the table
}

+ (PIXFileSystemDataSource *)sharedInstance;

//TODO: remove unused ivars
@property (nonatomic,strong) NSString *rootFilePath;
@property (nonatomic,strong) NSMutableArray *albums;
@property (nonatomic,strong) NSMutableArray *sortedAlbums;
@property (nonatomic,strong) NSDictionary *albumLookupTable;
@property (assign) BOOL finishedLoading;
@property (nonatomic,strong) NSArray *sortDescriptors;
@property (nonatomic,strong) NSSortDescriptor *dateMostRecentPhotoDescriptor;
@property (nonatomic, strong) NSArray *observedDirectories;


//New stufff
//@property (nonatomic,strong) NSMutableDictionary *tableRecords;


-(void)startLoadingAllAlbumsAndPhotosInObservedDirectories;


-(NSURL *)rootFilePathURL;



-(void)loadAllAlbums;

@end

@interface PIXFileSystemDataSource(ArchDirectoryObserver)

-(void)startObserving;
-(void)stopObserving;

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
