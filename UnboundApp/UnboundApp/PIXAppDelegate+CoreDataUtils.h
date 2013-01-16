//
//  PIXAppDelegate+CoreDataUtils.h
//  UnboundApp
//
//  Created by Bob on 1/8/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXAppDelegate.h"

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

-(BOOL)deleteObjectsForEntityName:(NSString *)entityName withUpdateDateBefore:(NSDate *)lastUpdated inContext:(NSManagedObjectContext *)context;

@end
