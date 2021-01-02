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
// Data is an array of PIXAlbum
#define AlbumsCreatedNotification @"AlbumsCreatedNotification"
#define AlbumDidChangeNotification @"AlbumDidChangeNotification"
#define AlbumWasRenamedNotification @"AlbumWasRenamedNotification"
#define AlbumStackDidChangeNotification @"AlbumStackDidChangeNotification"
#define AlbumDeletedNotification @"AlbumDeletedNotification"

#define PhotoThumbDidChangeNotification @"PhotoThumbDidChangeNotification"
#define PhotoFullsizeDidChangeNotification @"PhotoFullsizebDidChangeNotification"

#define kUB_ALBUMS_LOADED_FROM_FILESYSTEM @"UB_ALBUMS_LOADED_FROM_FILESYSTEM"
#define kUB_PHOTOS_LOADED_FROM_FILESYSTEM @"UB_PHOTOS_LOADED_FROM_FILESYSTEM"

#define kAppFirstRun @"appFirstRun"

#define kAppDidNotExitCleanly @"appDidNotExitCleanly"
#define kAppShowedCrashDialog @"appShowedCrashDialog"

#define kAppObservedDirectoriesChanged @"observedDirectoriesChanged"
#define kAppObservedDirectoryUnavailable @"observedDirectoryUnavailable"
#define kAppObservedDirectoryUnavailableSupressAlert @"observedDirectoryUnavailableSupressAlert"
#define kRootFolderUnavailableDetailMessage @"Cannot Access Your Photos Folder"
#define kRootFolderUnavailableTitle @"Make sure that your network drives are connected or open the Preferences to load another folder. "

// key for obtaining the current scan count
#define kScanCountKey @"scanCount"

#define kDeepScanIncompleteKey @"deepScanIncomplete"

//MARK Notifications
#define kNotePhotoStyleChanged @"photoStyleChanged"

//MARK Preference Keys
#define kPrefPhotoStyle @"photoStyle"
#define kPrefSupressDeleteWarning @"PIX_supressDeleteWarning"
#define kPrefSupressAlbumDeleteWarning @"PIX_supressAlbumDeleteWarning"
#define kPrefShowMoreExifInfo @"showExifMore"
#define kPrefShowInfoPanel @"showInfoPanel"

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

// key for the length of time in between transitions in the slideshow
#define kSlideshowTimeInterval @"slideshowTimeInterval"

#define FFString(msg, description) NSLocalizedStringFromTableInBundle(msg, @"Unbound", [NSBundle bundleForClass:[MainWindowController class]], description)

#define kAppStoreUrl @"https://itunes.apple.com/us/app/unbound/id690375005?ls=1&mt=12"
#define kUpgradeTrialUrl [kAppStoreUrl stringByAppendingString:@"&uo=demo"]
#define kHomepageUrl @"https://www.unboundapp.com/"
#define kSupportUrl @"mailto:support@unboundapp.com?subject=Unbound%20support"
#define kFeatureRequestUrl @"mailto:tyler@unboundapp.com?subject=Feature%20request:"
#define kReviewUrl [kAppStoreUrl stringByAppendingString:@"&uo=full&action=write-review"]

// ===========================
// = Constant Localized NSStrings =
// ===========================

#define MSG_WINDOW_TITLE                     FFString(@"Unbound",       @"Default window title.")


#endif
