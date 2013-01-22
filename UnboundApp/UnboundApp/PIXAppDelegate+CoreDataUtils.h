//
//  PIXAppDelegate+CoreDataUtils.h
//  UnboundApp
//
//  Created by Bob on 1/8/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXAppDelegate.h"

@class PIXAlbum;

@interface PIXAppDelegate (CoreDataUtils)

-(void)photosFinishedLoading:(NSNotification *)note;

-(void)loadPhotos;

-(void)loadAlbums;

-(void)updateAlbumsPhotos;

-(IBAction)testFetchAllPhotos:(id)sender;

-(NSArray *)fetchAllPhotos;

-(IBAction)deleteAllPhotos:(id)sender;

-(IBAction)testFetchAllAlbums:(id)sender;

-(NSArray *)fetchAllAlbums;

-(IBAction)deleteAllAlbums:(id)sender;

-(PIXAlbum *)fetchAlbumWithPath:(NSString *)aPath inContext:(NSManagedObjectContext *)context;

-(BOOL)deleteObjectsForEntityName:(NSString *)entityName withUpdateDateBefore:(NSDate *)lastUpdated inContext:(NSManagedObjectContext *)context;

@end

