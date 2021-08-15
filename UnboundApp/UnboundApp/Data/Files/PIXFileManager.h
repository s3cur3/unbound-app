//
//  PIXFileManager.h
//  UnboundApp
//
//  Created by Bob on 1/31/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PIXAlbum;
@class PIXPhoto;

@interface PIXFileManager : NSObject

+(PIXFileManager *)sharedInstance;

- (void) duplicatePhotos:(NSSet<PIXPhoto *> *)selectedPhotos;

- (void) deleteItemsWorkflow:(NSSet *)selectedItems;

-(void)moveFiles:(NSArray *)items;
-(void)copyFiles:(NSArray *)items;

-(void)recyclePhotos:(NSArray *)photos;

-(void)recycleAlbums:(NSArray *)items;
-(BOOL)renameAlbum:(PIXAlbum *)anAlbum withName:(NSString *)aNewName;
-(BOOL)renamePhoto:(PIXPhoto *)aPhoto withName:(NSString *)aNewName;
-(PIXAlbum *)createAlbumWithName:(NSString *)aName;
-(PIXAlbum *)createAlbumAtPath:(NSString *)aPath withName:(NSString *)aName;

-(void)setDesktopImage:(PIXPhoto *)aPhoto;

//-(NSString *)trashFolderPath;

- (NSString *)defaultAppPathForOpeningFileWithPath:(NSString *)filePath;
- (NSString *)defaultAppNameForOpeningFileWithPath:(NSString *)filePath;
//- (NSMenu *)openWithMenuItemForFile:(NSString *)filePath;
- (NSMenu *)openWithMenuItemForFiles:(NSArray<NSString *> *)filePaths;
- (void)openFileWithPath:(NSString *)filePath withApplication:(NSString *)appPath;

-(NSArray *)itemsForDraggingInfo:(id <NSDraggingInfo>) draggingInfo forDestination:(NSString *)destPath;


-(IBAction)importPhotosToAlbum:(PIXAlbum *)album allowDirectories:(BOOL)allowDirectories;

+ (BOOL)fileIsMetadataFile:(NSURL *)url;

@end
