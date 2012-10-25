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
        //DLog(@"Album created at path : %@", self.filePath);
    }
    return self;
}

-(void)addPhotosObject:(id)object
{
    [self.photos addObject:object];
}


-(NSArray *)children
{
    NSError *error = nil;
    NSURL *myDir = [NSURL fileURLWithPath:self.filePath isDirectory:YES];
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:myDir
                                                     includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLLocalizedNameKey, NSURLIsDirectoryKey, NSURLTypeIdentifierKey, nil]
                                                                        options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                          error:&error];
    
    if (error!=nil) {
        DLog(@"%@", error);
        return [NSArray array];
    }
    return content;
}

-(void)updatePhotosFromFileSystem
{
    
    /*NSError *error = nil;
    NSURL *myDir = [NSURL fileURLWithPath:self.filePath isDirectory:YES];
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:myDir
                                                        includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLLocalizedNameKey, NSURLIsDirectoryKey, NSURLTypeIdentifierKey, nil]
                                                                           options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                        error:&error];
    
    if (error!=nil) {
        DLog(@"%@", error);
    }*/
    NSArray *content = [self children];
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

-(BOOL)albumExists
{
    BOOL isDir;
    if (self.filePath && [[NSFileManager defaultManager] fileExistsAtPath:self.filePath isDirectory:&isDir] && isDir)
    {
        return YES;
    }
    return NO;
}



-(BOOL)albumExistsWithPhotos
{
    BOOL existsWithPhotos = NO;
    if ([self albumExists])
    {
        NSArray *content = [self children];
        for (NSURL *itemURL in content)
        {
            NSString *utiValue;
            [itemURL getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:nil];
            
            if (UTTypeConformsTo((__bridge CFStringRef)(utiValue), kUTTypeImage)) {
                existsWithPhotos = YES;
                break;
            }
        }
    }
    return existsWithPhotos;
}

-(void)dealloc
{

}
@end
