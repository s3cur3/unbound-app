//
//  PIXFileParser.h
//  UnboundApp
//
//  Created by Scott Sykora on 2/20/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
    // No Recursion
    PIXFileParserRecursionNone = 0,
    
    // Only recurse into folders that don't already exist as albums
    PIXFileParserRecursionSemi = 1,
    
    // recurse all subfolders
    PIXFileParserRecursionFull = 2
    
} PIXFileParserRecursionOptions;

@class PIXAlbum;

@interface PIXFileParser : NSObject

/**
 * observedDirectories is an array of the directories this class observes
 */
@property (nonatomic, strong) NSArray *observedDirectories;

@property BOOL isWorking;

@property float fullScanProgress;

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
 */
- (void)scanAlbum:(PIXAlbum *)album withRecursion:(PIXFileParserRecursionOptions)recursionMode;

- (void)scanPath:(NSString *)path withRecursion:(PIXFileParserRecursionOptions)recursionMode;

/**
 *  This method will scan a specific path in a shallow manner.
 *  It will recurse to subdirectories only if it find's subdirectories
 *  that arent already in the database structure. It will also track
 *  current scans so new ones arent started
 */
- (void)scanURLForChanges:(NSURL *)url withRecursion:(PIXFileParserRecursionOptions)recursionMode;

/**
 *  cancelScans will cancel any current directory scans and any current parsing threads
 */
- (void)cancelScans;


-(NSURL *) defaultDBFolder;
-(NSURL *) defaultDBCameraUploadsFolder;

-(void)setObservedURLs:(NSArray *)direcoryURLs;

-(NSArray *)fetchAlbumsWithPaths:(NSArray *)paths;
-(NSArray *)fetchPhotosWithPaths:(NSArray *)paths;

-(PIXAlbum *)fetchAlbumWithPath:(NSString *)aPath inContext:(NSManagedObjectContext *)context;

-(void)incrementWorking;
-(void)decrementWorking;

@end
