//
//  MainWindowController.m
//  Unbound5
//
//  Created by Bob on 10/4/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "MainWindowController.h"
#import "SearchQuery.h"
#import "PageViewController.h"
#import "ImageViewController.h"
#import "IKImageViewController.h"
#import "Album.h"
#include <sys/types.h>
#include <pwd.h>
#import "SimpleProfiler.h"
#import "SpotlightFetchController.h"
#import "FileSystemEventController.h"
//#import "AppDelegate.h"

/*
 * Used to get the home directory of the user, UNIX/C based workaround for sandbox issues
 */
NSString * UserHomeDirectory()
{
    const struct passwd * passwd = getpwnam([NSUserName() UTF8String]);
    if(!passwd)
        return nil; // bail out cowardly
    const char *homeDir_c = getpwnam([NSUserName() UTF8String])->pw_dir;
    NSString *homeDir = [[NSFileManager defaultManager]
                         stringWithFileSystemRepresentation:homeDir_c
                         length:strlen(homeDir_c)];
    return homeDir;
}

NSArray * DropBoxDirectory()
{
    NSArray * libraryDirectories = [NSArray arrayWithObject: [UserHomeDirectory() stringByAppendingPathComponent:@"Dropbox/"]];
    return libraryDirectories;
}

@interface MainWindowController()

@property (strong) NSURL *searchLocation;
@property (strong) FileSystemEventController *fileSystemEventController;

@end

@implementation MainWindowController


- (void)awakeFromNib {
    DLog(@"awakeFromNib");
    
    self.albumSortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]];
    
    [window setDelegate:self];  // we want to be notified when this window is closed
    
    
    //Register for notifications from the fetch controller
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(searchFinished:)
                                                 name:SearchQueryDidFinishNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(queryChildrenChanged:)
                                                 name:SearchQueryChildrenDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(searchItemChanged:)
                                                 name:SearchItemDidChangeNotification
                                               object:nil];
    
    //New file-based notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(albumChanged:)
                                                 name:AlbumDidChangeNotification
                                               object:nil];
    
    
    //If a search location is already set we can begin loading...
    /*if ([[NSUserDefaults standardUserDefaults] valueForKey:@"searchLocationKey"]!=nil)
    {
        [self startLoading];
    }*/
}

-(void)albumChanged:(NSNotification *)note
{
    Album *anAlbum = (Album *)note.object;
    if (anAlbum == self.selectedAlbum)
    {
        self.browserData = anAlbum.photos;
        [self.browserView reloadData];
    }
}


//called by the AppDelegate in applicationWillFinishLaunching
- (void)startLoading {
    
    [self resetProperties];
    
    // look for the saved search location in NSUserDefaults
    NSError *error = nil;
    NSData *bookMarkDataToResolve = [[NSUserDefaults standardUserDefaults] objectForKey:@"searchLocationKey"];
    if (bookMarkDataToResolve)
    {
        // resolve the bookmark data into our NSURL
        self.searchLocation = [NSURL URLByResolvingBookmarkData:bookMarkDataToResolve
                                                        options:NSURLBookmarkResolutionWithSecurityScope
                                                  relativeToURL:nil
                                            bookmarkDataIsStale:nil
                                                          error:&error];
        [self.searchLocation startAccessingSecurityScopedResource];
    } else {
        //[self punchHoleInSandboxForFile:@"/Users/inzan/Dropbox/Camera Uploads"];
        [self importFilesAndDirectories:nil];
        
        return;
    }
    
    if (self.searchLocation == nil)
    {
        DLog(@"No searchLocation specified!");
        assert(NO);
    }
    
    //Point our searchLocation NSPathControl to the search location
    [searchLocationPathControl setURL:self.searchLocation];
    
    [self createNewSearchForWithScopeURL:self.searchLocation];
    
    
}


// -------------------------------------------------------------------------------
//	importFilesAndDirectories:
//
//	This is called when the app is first run and no root dir has been identified yet.
// -------------------------------------------------------------------------------
- (IBAction)importFilesAndDirectories:(id)sender {

    NSError *error = nil;
    // Create and configure the panel.
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setShowsHiddenFiles:NO];
    [panel setTreatsFilePackagesAsDirectories:YES];
    NSString *selectMsg = NSLocalizedString(@"Please select your Dropbox camera uploads folder", @"Select Dropbox Folder Msg");
    [panel setMessage:selectMsg];
    
    NSArray *dirs = DropBoxDirectory();
    DLog(@"dirs : %@", dirs);
    
    if ([dirs count]>0)
    {
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[dirs lastObject] error:&error];
        if (!files)
        {
            DLog(@"%@", error);
        } else if (files != nil)
        {
            NSURL *mainDropBoxFolderURL = [NSURL fileURLWithPath:[dirs lastObject] isDirectory:YES];
            NSDirectoryEnumerator *itr = [[NSFileManager defaultManager] enumeratorAtURL:mainDropBoxFolderURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLLocalizedNameKey, NSURLEffectiveIconKey, NSURLIsDirectoryKey, NSURLTypeIdentifierKey, nil] options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil];
            
            for (NSURL *url in itr) {
                if ([url.filePathURL.lastPathComponent isEqualToString:@"Camera Uploads"])
                {
                    NSURL *aFileURL = url;
                    self.searchLocation = aFileURL;
                    [searchLocationPathControl setURL:self.searchLocation];
                    [self updateRootSearchPath:self.searchLocation];
                    return;
                }
            }
            
        } 

    }
    NSString *dropboxPath = nil;
    if ([dirs count]>0)
    {
        dropboxPath = [dirs lastObject];
    } else {
        dropboxPath = @"~/Dropbox/";
    }
    //[panel setDirectoryURL:[NSURL fileURLWithPath:@"~/Dropbox/Camera Uploads/" isDirectory:YES]];
    //DLog(@"1)panel.directoryURL = %@", panel.directoryURL);
    NSURL *dropBoxHomeURL = [NSURL fileURLWithPath:dropboxPath isDirectory:YES];
    if (dropBoxHomeURL!=nil)
    {
        [panel setDirectoryURL:dropBoxHomeURL];
        DLog(@" set the panel.directoryURL : %@", panel.directoryURL);
    }
    
    // Display the panel attached to the document's window.
    [panel beginSheetModalForWindow:window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSArray* urls = [panel URLs];
            self.searchLocation = [urls lastObject];
            [searchLocationPathControl setURL:self.searchLocation];
            [self updateRootSearchPath:self.searchLocation];
            // Use the URLs to build a list of items to import.
        }
        
    }];
}


-(void)resetProperties
{
    self.selectedAlbum = nil;
    self.directoryDict = [[NSMutableDictionary alloc] init];
    self.browserData = [[NSMutableArray alloc] init];
    self.directoryArray = [[NSMutableArray alloc] init];
    iSearchQueries = [[NSMutableArray alloc] init];
    
    
}



- (BOOL)windowShouldClose:(id)sender {
    NSLog(@"windowShouldClose was called");
    [self.searchLocation stopAccessingSecurityScopedResource];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    return YES;
}

-(void)showMainView
{
    [window setContentView:self.mainContentView];
}

- (void)createNewSearchForWithScopeURL:(NSURL *)url {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(kMDItemContentTypeTree = 'public.image') OR  (kMDItemContentTypeTree = 'public.movie')"];

    
    // Create an instance of our datamodel and keep track of things.
    SearchQuery *searchQuery = [[SearchQuery alloc] initWithSearchPredicate:predicate title:@"Search" scopeURL:url];
    [iSearchQueries addObject:searchQuery];
    
}

/*- (void)createNewFetchForWithScopeURL:(NSURL *)url {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(kMDItemContentTypeTree = 'public.image') OR  (kMDItemContentTypeTree = 'public.movie')"];
    
    
    // Create an instance of our datamodel and keep track of things.
    SpotlightFetchController *searchQuery = [[SpotlightFetchController alloc] initWithSearchPredicate:predicate title:@"Search" scopeURL:url];
    [iSearchQueries addObject:searchQuery];
    
}*/

-(void)updateAlbumsWithSearchResults:(NSArray *)children //forDirectory:(NSString *)path
{
    PROFILING_START(@"FileUtils - searchItemsFromResults");
    //DLog(@"Starting searchItemsFromResults");
    //NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity:[children count] ];
    NSInteger index =0;
    for (SearchItem *item in children)
    {
        index++;
        /*if ([self.browserData containsObject:item]){
            continue;
        }*/
        //NSLog(@"item : %@", [item debugDescription]);

        NSString *fullPath = [item.metadataItem valueForAttribute:(NSString *)kMDItemPath];
        if (fullPath==nil) {
            DLog(@"SearchItem has no path item %ld of %ld", index, children.count);
            //NSAssert(fullPath!=nil, @"SearchItem has no path");
            [item dumpAttributesToLog];
            continue;
        }
        
        NSString *dirPath = [fullPath stringByDeletingLastPathComponent];
        Album *album = [self.directoryDict valueForKey:dirPath];
        if (album==nil)
        {
            album = [[Album alloc] initWithFilePath:dirPath];
            [self.directoryDict setValue:album forKey:dirPath];
            [self.directoryArray addObject:album];
            [album updatePhotosFromFileSystem];
            //[self.tableView reloadData];
        }
        /*if (![album.photos containsObject:item])
        {
            [album addPhotosObject:item];
        }*/
        
    }
    
    //DLog(@"Finished searchItemsFromResults");
    PROFILING_STOP();
    return;
}

-(void)searchFinished:(NSNotification *)note
{
    DLog(@"searchFinished")
    SearchQuery *query = (SearchQuery *)[note object];
    NSString *topLevelPath = [query._searchURL path];
    Album *topLevelAlbum = (Album *)[self.directoryDict valueForKey:topLevelPath];
    if (!topLevelAlbum)
    {
        topLevelAlbum = [[Album alloc] initWithFilePath:topLevelPath];
        [self.directoryArray addObject:topLevelAlbum];
        [self.directoryDict setValue:topLevelAlbum forKey:topLevelPath];
    }
    
    if (self.selectedAlbum == nil) {
        self.selectedAlbum = topLevelAlbum;
    }
    
    [self.directoryArray sortUsingDescriptors:self.albumSortDescriptors];
    NSInteger selectedAlbumIndex = [self.directoryArray indexOfObject:self.selectedAlbum];
    
    [self.tableView reloadData];
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedAlbumIndex] byExtendingSelection:NO];
    [self.tableView scrollRowToVisible:selectedAlbumIndex];
    [self.browserView reloadData];
    
    //Disabling spotlight updates
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SearchQueryChildrenDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SearchQueryDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SearchItemDidChangeNotification object:nil];
    //query is dealloced and stopped when removed
    [iSearchQueries removeAllObjects];
    
    self.fileSystemEventController = [[FileSystemEventController alloc] initWithPath:self.searchLocation albumsTable:self.directoryDict];
    
    [self.fileSystemEventController startObserving];
}

- (void)queryChildrenChanged:(NSNotification *)note {
    
    SearchQuery *query = (SearchQuery *)[note object];
    DLog(@"Current album count  : %ld", self.directoryArray.count);
    DLog(@"incoming item count  : %ld", query.children.count);
    //[self searchItemsFromResults:query.children forDirectory:[query._searchURL path]];
    
    
    //Update the albums and their contents based on the updated search results
    [self updateAlbumsWithSearchResults:query.children];
    Album * anAlbum = self.selectedAlbum;
    if (anAlbum!=nil)
    {
        self.browserData = anAlbum.photos;//[self.directoryDict valueForKey:anAlbum.filePath];
    } else {
        DLog(@"No selected album");
        return;
    }
    
    [self.tableView reloadData];
    [self.browserView reloadData];
    //[resultsOutlineView reloadItem:[note object] reloadChildren:YES];
}

- (void)searchItemChanged:(NSNotification *)note {
    NSLog(@"searchItemChanged : %@", note);
    SearchItem *item = (SearchItem *)[note object];
    NSLog(@"item : %@", [item debugDescription]);
    [self.browserView reloadData];

    // When an item changes, it only will affect the display state.
    // So, we only need to redisplay its contents, and not reload it
    /*NSInteger row = [resultsOutlineView rowForItem:[note object]];
    if (row != -1) {
        [resultsOutlineView setNeedsDisplayInRect:[resultsOutlineView rectOfRow:row]];
        if ([resultsOutlineView isRowSelected:row]) {
            [self updatePathControl];
        }
    }*/
}

-(NSMutableArray *)albumArray;
{
    return self.directoryArray;
}

#pragma mark - NSPathControl support

-(void)updateRootSearchPath:(NSURL *)newRootSearchPath
{
    self.searchLocation = newRootSearchPath;
    NSData *bookmarkData = [self.searchLocation bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                         includingResourceValuesForKeys:nil
                                                          relativeToURL:nil
                                                                  error:nil];
    DLog(@"updateRootSearchPath : %@", newRootSearchPath.path);
    if(bookmarkData){
        [[NSUserDefaults standardUserDefaults] setObject:bookmarkData forKey:@"searchLocationKey"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.searchLocation startAccessingSecurityScopedResource];
    }
    
    
    [self resetProperties];
    [self.tableView reloadData];
    [self createNewSearchForWithScopeURL:self.searchLocation];
}

//NSFilePathControl calls this when user selects a new root directory
- (IBAction)searchLocationChanged:(id)sender {
    
    NSURL *oldSearchURL = self.searchLocation;
    NSURL *newURL = (NSURL *)[sender URL];
    [self updateRootSearchPath:newURL];
    
    if (oldSearchURL!=nil)
    {
        [oldSearchURL stopAccessingSecurityScopedResource];
    }
}

// -------------------------------------------------------------------------------
//	willDisplayOpenPanel:openPanel:
//
//	Delegate method to NSPathControl to determine how the NSOpenPanel will look/behave.
// -------------------------------------------------------------------------------
- (void)pathControl:(NSPathControl *)pathControl willDisplayOpenPanel:(NSOpenPanel *)openPanel {
    
    // customize the open panel to choose directories
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setMessage:@"Choose a location to search for photos and images:"];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setPrompt:@"Choose"];
    [openPanel setTitle:@"Choose Location"];
    
    // set the default location to the Documents folder
    NSArray *documentsFolderPath = NSSearchPathForDirectoriesInDomains(NSUserDirectory, NSUserDomainMask, YES);
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:[documentsFolderPath objectAtIndex:0]]];
}



#pragma mark -

#pragma mark Browser Data Source Methods

- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *) aBrowser
{
	return [self.browserData count];
}

- (id) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index
{
	return [self.browserData objectAtIndex:index];
}

/* implement some optional methods of the image-browser's datasource protocol to be able to remove and reoder items */

/*	remove
 The user wants to delete images, so remove these entries from our datasource.
 */
- (void)imageBrowser:(IKImageBrowserView *)view removeItemsAtIndexes:(NSIndexSet *)indexes
{
	[self.browserData removeObjectsAtIndexes:indexes];
    [self.browserView reloadData];
}

/* action called when the zoom slider did change */
- (IBAction)zoomSliderDidChange:(id)sender
{
	/* update the zoom value to scale images */
    [self.browserView setZoomValue:[sender floatValue]];
	
	/* redisplay */
    //[self.imageBrowserController.browserView setNeedsDisplay:YES];
}

// The only essential/required tableview dataSource method
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.albumArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    Album *album = [self.albumArray objectAtIndex:rowIndex];
    return album.title;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    //NSLog(@"tableViewSelectionDidChange : %@", aNotification.object);
    if ([self.tableView selectedRow]==-1)
    {
        return;
    }
    Album *anAlbum =  [self.albumArray objectAtIndex:[self.tableView selectedRow]];
    if (self.selectedAlbum == anAlbum) {
        DLog(@"selectedAlbum didn't seem to change - no need to update browserView");
    } else {
        self.selectedAlbum = anAlbum;
    }
    
    //[self.browserData removeAllObjects];
    //[self.browserView reloadData];
   // NSURL *searchURL = [NSURL URLWithString:[newDir valueForKey:@"filePath"]];
    //Album *anAlbum = [self.directoryDict valueForKey:newDir.filePath];
    if (anAlbum!=nil)
    {
        self.browserData = anAlbum.photos;
        //[self.browserView reloadData];
    } else {
        //assert(NO);
        //NSURL *searchURL = [NSURL URLWithString:[anAlbum valueForKey:@"filePath"]];
        //[self createNewSearchForWithScopeURL:searchURL];
    }
    
    //[url startAccessingSecurityScopedResource];
    //[self loadPhotosForURL:searchURL];
    //[url stopAccessingSecurityScopedResource];
    [self.browserView reloadData];
}




// -------------------------------------------------------------------------------
//	imageBrowserSelectionDidChange:aBrowser
//
//	User chose a new image from the image browser.
// -------------------------------------------------------------------------------
- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser
{
    
    NSLog(@"imageBrowserSelectionDidChange");
}

// -------------------------------------------------------------------------------
//  imageBrowser:cellWasDoubleClickedAtIndex:index
// -------------------------------------------------------------------------------
- (void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index
{
    
    self.pageViewController = [[PageViewController alloc] initWithNibName:@"PageViewController" bundle:nil];
    NSInteger selectedRow = self.tableView.selectedRow;
    if (selectedRow<0 || selectedRow>[self.albumArray count]) {
        selectedRow = 0;
    }
    //NSURL *aURL = [NSURL fileURLWithPath:self.selectedAlbum.filePath isDirectory:YES];
    if (self.selectedAlbum == nil)
    {
        self.selectedAlbum = (Album*)[[self albumArray] objectAtIndex:selectedRow ];
    }
    
    //NSURL *aURL = [NSURL fileURLWithPath:[[[self albumArray] objectAtIndex:selectedRow ] valueForKey:@"filePath"]];
    self.pageViewController.album = self.selectedAlbum;
    self.pageViewController.initialSelectedItem = [self.selectedAlbum.photos objectAtIndex:index];
    
    self.pageViewController.parentWindowController = self;
    self.pageViewController.view.frame = ((NSView*)window.contentView).bounds;
    self.mainContentView = window.contentView;
    
    //self.pageViewController.pageController.selectedIndex = index;
    [window setContentView:self.pageViewController.view];
    
    NSLog(@"cellWasDoubleClickedAtIndex");
}


@end
