//
//  PIXFileParser.h
//  UnboundApp
//
//  Created by Scott Sykora on 2/20/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PIXAlbum;

@interface PIXFileParser : NSObject

/**
 * observedDirectories is an array of the directories this class observes
 */
@property (nonatomic, strong) NSArray *observedDirectories;

@property BOOL isWorking;

/**
 * This is a singleton accessor to get the shared instance of this 
 * class. We should only ever use this instance
 */
+(PIXFileParser *)sharedFileParser;


-(void)startObserving;

-(void)stopObserving;

/**
 * This method will do a deep scan of the entire directory structure
 */

- (void)scanFullDirectory;

/**
 * This method will scan a specific album for changed files
 * this will not go any deeper than the current album
 */
- (void)shallowScanAlbum:(PIXAlbum *)url;

/**
 *  This method will scan a specific path in a shallow manner.
 *  It will recurse to subdirectories only if it find's subdirectories
 *  that arent already in the database structure. It will also track
 *  current scans so new ones arent started
 */
- (void)scanURLForChanges:(NSURL *)url;

/**
 *  cancelScans will cancel any current directory scans and any current parsing threads
 */
- (void)cancelScans;


@end
