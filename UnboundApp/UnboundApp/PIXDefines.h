//
//  PIXDefines.h
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#ifndef UnboundApp_PIXDefines_h
#define UnboundApp_PIXDefines_h

#define kPhotoEntityName @"PIXPhoto"
#define kAlbumEntityName @"PIXAlbum"

#define kSearchDidFinishNotification @"kSearchDidFinishNotification"
#define kCreateThumbDidFinish @"kCreateThumbDidFinish"

#define kUnboundAlbumMetadataFileName @".unbound"

#define ALBUM @"Album"
#define PHOTO @"Photo"

#define AlbumCreatedNotification @"AlbumCreatedNotification"
#define AlbumDidChangeNotification @"AlbumDidChangeNotification"
#define AlbumDeletedNotification @"AlbumDeletedNotification"

#define PhotoThumbDidChangeNotification @"PhotoThumbDidChangeNotification"

#define kUB_ALBUMS_LOADED_FROM_FILESYSTEM @"UB_ALBUMS_LOADED_FROM_FILESYSTEM"
#define kUB_PHOTOS_LOADED_FROM_FILESYSTEM @"UB_PHOTOS_LOADED_FROM_FILESYSTEM"


// key for obtaining the current scan count
#define kScanCountKey @"scanCount"

// key for obtaining the path of an image field
#define kPathKey @"path"

// key for obtaining the directory containing an image field
#define kDirectoryPathKey @"dirPath"

// key for obtaining the size of an image file
#define kSizeKey @"size"

// key for obtaining the name of an image file
#define kNameKey @"name"

// key for obtaining the name of an image file
#define kIsUnboundFileKey @"isUnboundFile"

// key for obtaining the mod date of an image file
#define kModifiedKey @"modified"

// key for obtaining the mod date of an image file
#define kFileSizeKey @"fileSize"

#define kCreatedKey @"created"

// NSNotification name to tell the Window controller an image file as found
#define kLoadImageDidFinish @"LoadImageDidFinish"

#define FFString(msg, description) NSLocalizedStringFromTableInBundle(msg, @"Unbound", [NSBundle bundleForClass:[PIXMainWindowController class]], description)

// ===========================
// = Constant Localized NSStrings =
// ===========================

#define MSG_WINDOW_TITLE                     FFString(@"Unbound",       @"Default window title.")


#endif
