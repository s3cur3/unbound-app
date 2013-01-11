//
//  Album.m
//  UnboundCoreDataUtility
//
//  Created by Bob on 1/7/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "Album.h"
#import "Photo.h"
#import "PIXAppDelegate.h"


@implementation Album

@dynamic dateLastModified;
@dynamic name;
@dynamic title;
@dynamic path;
@dynamic thumbnail;
@dynamic dateLastUpdated;
@dynamic photos;

- (void)awakeFromFetch {
    
    [super awakeFromFetch];
    //NSImage *anImage = [NSImage imageNamed:@"nophoto"];
    //NSData *data = [anImage TIFFRepresentation];
    //self.thumbnail = data;
    //NSData *thumbnailData = [self thumbnail];
    //if (thumbnailData != nil) {
    //TODO: possibly some background low priority thumb loading?
    //NSColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
    //[self setPrimitiveColor:color];
    //}
}

-(NSImage *)thumbnailImage
{
    if (_thumbnailImage != nil)
    {
        return _thumbnailImage;
    }
    if (self.photos.count) {
        Photo *latestPhoto = [self.photos objectAtIndex:0];
        if (latestPhoto.thumbnail !=nil) {
            self.thumbnail = latestPhoto.thumbnail;
            _thumbnailImage = [[NSImage alloc] initWithData:self.thumbnail];
            return _thumbnailImage;
        } else {
            [latestPhoto loadThumbnailImage];
        }
    }
    return [NSImage imageNamed:@"nophoto"];
}

- (NSData *)thumbnail
{
    [self willAccessValueForKey:@"thumbnail"];
    NSData *tmpValue = [self primitiveValueForKey:@"thumbnail"];
    [self didAccessValueForKey:@"thumbnail"];
    return tmpValue;
}
            
- (void)setThumbnail:(NSData *)newThumbnail
{
    [self willChangeValueForKey:@"thumbnail"];
    [self setPrimitiveValue:newThumbnail forKey:@"thumbnail"];
    [self didChangeValueForKey:@"thumbnail"];
}

- (NSString *)name
{
    [self willAccessValueForKey:@"name"];
    NSString *tmpValue = [self primitiveValueForKey:@"name"];
    [self didAccessValueForKey:@"name"];
    return tmpValue;
}
            
- (void)setName:(NSString *)value;
{
    [self willChangeValueForKey:@"name"];
    [self setPrimitiveValue:value forKey:@"name"];
    [self didChangeValueForKey:@"name"];
}

- (NSString *)path
{
    [self willAccessValueForKey:@"path"];
    NSString *tmpValue = [self primitiveValueForKey:@"path"];
    [self didAccessValueForKey:@"path"];
    return tmpValue;
}

- (void)setPath:(NSString *)value
{
    [self willChangeValueForKey:@"path"];
    [self setPrimitiveValue:value forKey:@"path"];
    
    NSString *fileName = [value lastPathComponent];
    [self setName:fileName];
    [self setTitle:fileName];
    
    [self didChangeValueForKey:@"path"];
}


-(NSEnumerator *)children
{
    // Create a local file manager instance
    NSFileManager *localFileManager=[[NSFileManager alloc] init];
    NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants;
    NSURL *filePathURL = [NSURL fileURLWithPath:self.path isDirectory:YES];
    NSDirectoryEnumerator *dirEnumerator = [localFileManager enumeratorAtURL:filePathURL
                                                  includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey,
                                                                              NSURLIsDirectoryKey,nil]
                                                                     options:options
                                                                errorHandler:^(NSURL *url, NSError *error) {
                                                                    // Handle the error.
                                                                    [PIXAppDelegate presentError:error];
                                                                    // Return YES if the enumeration should continue after the error.
                                                                    return YES;
                                                                }];
    
    NSAssert(dirEnumerator!=nil, @"Failed to get a directoryEnumerator for an album's URL");
    return dirEnumerator;
    
    
    
}

/*-(void)updatePhotosFromFileSystem
{
#ifdef DEBUG
    NSAssert(![[NSThread currentThread] isMainThread], @"-[Album updatePhotosFromFileSystem] should not be run on main thread");
#endif
    //dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW,0),^(void){
    
    NSEnumerator *content = [self children];
    NSMutableArray *somePhotos = [NSMutableArray array];
    NSDate *aDateMostRecentPhoto = nil;
    NSError *error;
    
    NSURL *itemURL = nil;
    while (itemURL = (NSURL*)[content nextObject])
    {
        NSString *utiValue;
        
        if (![itemURL getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:&error]) {
            [PIXAppDelegate presentError:error];
        }
        if (UTTypeConformsTo((__bridge CFStringRef)(utiValue), kUTTypeImage)) {
            Photo *aPhoto = [[Photo alloc] initWithURL:itemURL];
            NSDate *modDate = nil;
            NSError *error;
            if (![itemURL getResourceValue:&modDate forKey:NSURLContentModificationDateKey error:&error]) {
                [[NSApplication sharedApplication] performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
                //Unable to get the dateLastModified - for now just set the modDate to the distantPast as a temporary placeholder for sorting
                //TODO: find the best way to handle this
                modDate = [NSDate distantPast];
            }
            aPhoto.dateLastModified = modDate;
            if (!aDateMostRecentPhoto || [modDate isGreaterThanOrEqualTo:aDateMostRecentPhoto])
            {
                aDateMostRecentPhoto = modDate;
            }
            [somePhotos addObject:aPhoto];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(),^(void){
        
        self.photos = somePhotos;
        if (aDateMostRecentPhoto) {
            self.dateMostRecentPhoto = aDateMostRecentPhoto;
        } else {
            NSDate *folderDate = nil;
            NSError *error;
            NSURL *albumURL = [NSURL fileURLWithPath:self.filePath isDirectory:YES];
            if (![albumURL getResourceValue:&folderDate forKey:NSURLContentModificationDateKey error:&error]) {
                [[NSApplication sharedApplication] presentError:error];
            } else {
                self.dateMostRecentPhoto = folderDate;
            }
        }
        
        self.dateLastScanned = [NSDate date];
        
        [self createOrUpdateUnboundMetadataFile];
        
        [self resetThumbImage];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:self];
        
        //TODO make sure if this is necessary
        //[self.photos makeObjectsPerformSelector:@selector(setAlbum:) withObject:self];
        
        //[self thumbnailImage];
    });
    
    //});
    
    
    
    
}*/

@end
