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

#define ALBUM @"ALBUM"
#define PHOTO @"PHOTO"

#define AlbumCreatedNotification @"AlbumCreatedNotification"
#define AlbumDidChangeNotification @"AlbumDidChangeNotification"
#define AlbumDeletedNotification @"AlbumDeletedNotification"

#define PhotoThumbDidChangeNotification @"PhotoThumbDidChangeNotification"

#define kUB_ALBUMS_LOADED_FROM_FILESYSTEM @"UB_ALBUMS_LOADED_FROM_FILESYSTEM"
#define kUB_PHOTOS_LOADED_FROM_FILESYSTEM @"UB_PHOTOS_LOADED_FROM_FILESYSTEM"

#define FFString(msg, description) NSLocalizedStringFromTableInBundle(msg, @"Unbound", [NSBundle bundleForClass:[PIXMainWindowController class]], description)

// ===========================
// = Constant Localized NSStrings =
// ===========================

#define MSG_WINDOW_TITLE                     FFString(@"Unbound",       @"Default window title.")


#endif
