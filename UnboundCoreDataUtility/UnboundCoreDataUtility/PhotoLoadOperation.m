//
//  PhotoLoadOperation.m
//  Unbound Mac
//
//  Created by Robert Edmonston on 12/31/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PhotoLoadOperation.h"
#import "PIXAppDelegate.h"
// #import "PIXAppDelegate+CoreDataOperations.h"
#import "PIXAppDelegate+CoreDataUtils.h"
#import "Photo.h"

// key for obtaining the path of an image fiel
extern NSString *kPathKey;

// key for obtaining the path of an image fiel
extern NSString *kDirectoryPathKey;

// key for obtaining the size of an image file
//extern NSString *kSizeKey;

// key for obtaining the name of an image file
extern NSString *kNameKey;

// key for obtaining the mod date of an image file
extern NSString *kModifiedKey;

@implementation PhotoLoadOperation

- (id)initWithData:(NSArray *)newItems
{
    self = [super init];
    if (self) {
        _items = [newItems copy];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        
        // setup our Core Data scratch pad and persistent store
        self.managedObjectContext = [[NSManagedObjectContext alloc] init];
        [self.managedObjectContext setUndoManager:nil];
        
        PIXAppDelegate *appDelegate = (PIXAppDelegate *)[[NSApplication sharedApplication] delegate];
        [self.managedObjectContext setPersistentStoreCoordinator:appDelegate.persistentStoreCoordinator];
        
        self.currentParseBatch = [NSMutableArray new];
        itemCounter = 0;
    }
    return self;
}

-(void)main
{
    int counter = 0;
    NSEntityDescription *ent = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:self.managedObjectContext];
    for (NSDictionary *anItem in self.items)
    {
        if (self.isCancelled) {
            return;
        } else if (counter++>1000) {
            break;
        }
        
        
        // create an earthquake managed object, but don't insert it in our moc yet
        Photo *aPhoto = [[Photo alloc] initWithEntity:ent insertIntoManagedObjectContext:nil];
        aPhoto.path = [anItem valueForKey:kPathKey];
        aPhoto.name = [anItem valueForKey:kNameKey];
        [self.currentParseBatch addObject:aPhoto];
    }
    
    if (![self isCancelled]) {
        if ([self.currentParseBatch count] > 0) {
            [self performSelectorOnMainThread:@selector(addItemToList:)
                                   withObject:self.currentParseBatch
                                waitUntilDone:YES];
        }
    }
    
    self.currentParseBatch = nil;
    if (![self isCancelled])
    {
        // for the purposes of this sample, we're just going to post the information
        // out there and let whoever might be interested receive it (in our case its MyWindowController).
        //
        PIXAppDelegate *appDelegate = (PIXAppDelegate *)[[NSApplication sharedApplication] delegate];
        [appDelegate performSelectorOnMainThread:@selector(testPhotosFetch) withObject:nil waitUntilDone:NO];
    }
}

// a batch of earthquakes are ready to be added
- (void)addItemToList:(NSArray *)items {
    assert([NSThread isMainThread]);
    
    //NSString *logStr = [NSString stringWithFormat:@"Saving %ld items", [items count]];
    //NSLog(@"%@", logStr);
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *ent = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = ent;
    
    // narrow the fetch to these two properties
    fetchRequest.propertiesToFetch = [NSArray arrayWithObjects:@"name", @"path", nil];
    
    // before adding the earthquake, first check if there's a duplicate in the backing store
    NSError *error = nil;
    //Photo *anItem = nil;
    for (Photo *item in items) {

        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@ AND path = %@", item.name, item.path];
        
        NSArray *fetchedItems = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (fetchedItems.count == 0) {
            // we found no duplicate earthquakes, so insert this new one
            [self.managedObjectContext insertObject:item];
        }
    }
    
    if ([self.managedObjectContext hasChanges]==NO)
    {
        //NSLog(@"No changes to SAVE!!");
        return;
    } else {
        NSLog(@"SAVING %ld INSERTED OBJECTS", [[self.managedObjectContext insertedObjects] count]);
        return;
    }
    //[fetchRequest release];
    
    if (![self.managedObjectContext save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate.
        // You should not use this function in a shipping application, although it may be useful
        // during development. If it is not possible to recover from the error, display an alert
        // panel that instructs the user to quit the application by pressing the Home button.
        //
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

@end
