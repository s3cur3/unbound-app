//
//  Album.m
//  Unbound5
//
//  Created by Bob on 10/10/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "Album.h"
#import "SCEvents.h"
#import "SearchItem.h"
#import "Photo.h"

NSString *AlbumDidChangeNotification = @"AlbumDidChangeNotification";

@implementation Album
/*- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"Untitled";
    }
    return self;
}*/

- (id)initWithFilePath:(NSString *) aPath
{
    self = [super init];
    if (self) {
        self.filePath = [aPath copy];
        self.title = [aPath lastPathComponent];
        self.photos = [NSMutableArray array];
        /*self.events = [[SCEvents alloc] init];
        NSString *watchPath = [NSString stringWithFormat:@"%@/", self.filePath];
        if ([self.events startWatchingPaths:[NSArray arrayWithObject:watchPath]])
        {
            [self.events setDelegate:self];
        }*/
    }
    return self;
}

-(void)addPhotosObject:(id)object
{
    [self.photos addObject:object];
}

-(void)updatePhotosFromFileSystem
{
    
    NSError *error = nil;
    NSURL *myDir = [NSURL fileURLWithPath:self.filePath isDirectory:YES];
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:myDir
                                                        includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLLocalizedNameKey, NSURLIsDirectoryKey, NSURLTypeIdentifierKey, nil]
                                                                           options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                        error:&error];
    
    if (error!=nil) {
        DLog(@"%@", error);
    }
    NSMutableArray *somePhotos = [NSMutableArray arrayWithCapacity:content.count];
    for (NSURL *itemURL in content)
    {
        NSString *utiValue;
        [itemURL getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:nil];
        
        if (UTTypeConformsTo((__bridge CFStringRef)(utiValue), kUTTypeImage)) {
            Photo *aPhoto = [[Photo alloc] initWithURL:itemURL];
            //[self addPhotosObject:aPhoto];
            [somePhotos addObject:aPhoto];
        }
    }
    if ([somePhotos count]==0)
    {
        self.photos = nil;
    } else {
        self.photos = somePhotos;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self];
    
}

- (void)pathWatcher:(SCEvents *)pathWatcher eventOccurred:(SCEvent *)event;
{
    DLog(@"%@", event);
    [self updatePhotosFromFileSystem];
    [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self];
    /*NSMutableArray *itemsToDelete = [[NSMutableArray alloc] init];
    for (SearchItem *searchItem in self.photos)
    {
        NSMetadataItem *anItem = [searchItem metadataItem];
        NSNumber *fileSize= [anItem valueForAttribute:(NSString *)kMDItemFSSize];
        if (fileSize == nil) {
            //[self.photos removeObject:anItem];
            [itemsToDelete addObject:searchItem];
            
        }
    }
    [self.photos removeObjectsInArray:itemsToDelete];*/
    
    
    
    //SearchItem *searchItem = (SearchItem *)[self.photos lastObject];
    //[[NSNotificationCenter defaultCenter] postNotificationName:SearchItemDidChangeNotification object:searchItem];
    
    //SearchItem *searchItem = (SearchItem *)[self.photos lastObject];
    //NSString *newTitle = [anItem valueForAttribute:(NSString *)kMDItemDisplayName];
    //DLog(@"new title : %@", newTitle);
    //[searchItem setTitle:nil];
    
}

-(void)dealloc
{

}
@end
