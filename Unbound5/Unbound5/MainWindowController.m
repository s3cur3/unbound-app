
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
#import "SidebarTableCellView.h"
#import "AlbumViewController.h"
#import "ImageBrowserViewController.h"
#import "PINavigationViewController.h"
#import "SplitViewController.h"

#define kMinContrainValue 245.0f

NSString *searchLocationKey  = @"searchLocationKey";
NSString *dropboxHomeLocationKey  = @"dropboxHomeLocationKey";
NSString *dropboxHomeStringKey = @"dropboxHomeStringKey";

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
@property (strong) NSURL *cameraUploadsLocation;
@property (strong) NSURL *dropboxHome;
@property (strong) NSString *dropboxHomePath;
@property (strong) FileSystemEventController *fileSystemEventController;

@end

@implementation MainWindowController


- (void)awakeFromNib {
    
    //TODO: Sort descriptors not working when bound to tableView
    self.albumSortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]];
    
    [window setDelegate:self];  // we want to be notified when this window is closed
    
    //New file-based notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(albumChanged:)
                                                 name:AlbumDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showPhotosViewForAlbum:)
                                                 name:@"ShowPhotos"
                                               object:nil];
    
    [self.browserView setDraggingDestinationDelegate:self];
    
    
    
    [self.outlineView registerForDraggedTypes:[NSArray arrayWithObject: NSURLPboardType]];
    
    NSColor * color = [NSColor colorWithPatternImage:[NSImage imageNamed:@"dark_bg"]];
    [self.browserScrollView setBackgroundColor:color];
    
    //[self.browserView setWantsLayer:YES];
    //[self.browserScrollView setWantsLayer:YES];
    
    [self.outlineView setHidden:YES];
    [self.browserView setHidden:YES];
    
    self.albumViewController = [[AlbumViewController alloc] initWithNibName:@"Collection" bundle:nil];
    self.splitViewController = [[SplitViewController alloc] initWithNibName:@"SplitViewController" bundle:nil];
    //[self showAlbumView];
    [self.navigationViewController pushViewController:self.albumViewController];
    //[self.navigationViewController pushViewController:self.splitViewController];
    
    
    
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

-(void)albumsUpdatedLoading:(NSNotification *)note
{
    NSMutableArray *albums = (NSMutableArray *)[note.userInfo valueForKey:@"albums"];
    [albums sortUsingDescriptors:self.albumSortDescriptors];

    self.directoryArray = albums;
    if (self.selectedAlbum == nil)
    {
        self.selectedAlbum = [self.directoryArray lastObject];
        self.browserData = self.selectedAlbum.photos;
    }
    
    //[self.tableView reloadData];
    //[self.outlineView reloadData];
    //[self.browserView reloadData];
    
    
    [self.albumViewController updateContent:self.directoryArray];
    //[self.fileSystemEventController startObserving];
}

-(void)albumsFinishedLoading:(NSNotification *)note
{
    [self albumsUpdatedLoading:note];
}

-(void)albumsWereDeleted:(NSNotification *)note
{
    NSArray *albumsDeleted = (NSArray *) [note.userInfo valueForKey:@"Albums"];
    DLog(@"the following albums were deleted : %@", albumsDeleted);
    if ([albumsDeleted containsObject:self.selectedAlbum])
    {
        self.selectedAlbum = [self.albumArray objectAtIndex:0];
    }
    [self.directoryArray removeObjectsInArray:albumsDeleted];
    //[self.albumArray removeObject:anAlbum];
    //[self.directoryDict removeObjectForKey:anAlbum.filePath];
    [self.tableView reloadData];
    [self.outlineView reloadData];
}

-(void)loadAlbumsFromFileSystem
{
    if (self.fileSystemEventController)
    {
        [self.fileSystemEventController stopObserving];
    }
    //self.fileSystemEventController = [[FileSystemEventController alloc] initWithPath:self.searchLocation albumsTable:self.directoryDict];
    self.fileSystemEventController = [[FileSystemEventController alloc] initWithPath:self.searchLocation
                                      dropboxHome:[NSURL fileURLWithPath:self.dropboxHomePath]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumsUpdatedLoading:) name:@"AlbumsUpdatedLoading" object:self.fileSystemEventController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumsFinishedLoading:) name:@"AlbumsFinishedLoading" object:self.fileSystemEventController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumsWereDeleted:) name:@"AlbumsWereDeleted" object:self.fileSystemEventController];
    
    [self.fileSystemEventController startObserving];
}


//called by the AppDelegate in applicationWillFinishLaunching
- (void)startLoading {
    
    //[self.fileSystemEventController stopObserving];
    [self resetProperties];
    
    // look for the saved search location in NSUserDefaults
    NSError *error = nil;
    NSData *bookMarkDataToResolve = [[NSUserDefaults standardUserDefaults] objectForKey:dropboxHomeLocationKey];
    if (bookMarkDataToResolve)
    {
        self.dropboxHomePath = [[NSUserDefaults standardUserDefaults] objectForKey:dropboxHomeStringKey];
        // resolve the bookmark data into our NSURL
        self.dropboxHome = [NSURL URLByResolvingBookmarkData:bookMarkDataToResolve
                                                        options:NSURLBookmarkResolutionWithSecurityScope
                                                  relativeToURL:nil
                                            bookmarkDataIsStale:nil
                                                          error:&error];
        [self.dropboxHome startAccessingSecurityScopedResource];
        
    } else {
        //[self punchHoleInSandboxForFile:@"/Users/inzan/Dropbox/Camera Uploads"];
        [self importFilesAndDirectories:nil];
        
        return;
    }
    
    if (self.dropboxHome == nil)
    {
        DLog(@"No searchLocation specified!");
        assert(NO);
    }
    self.dropboxHomePath = [[NSUserDefaults standardUserDefaults] objectForKey:dropboxHomeStringKey];
    NSString *aSearchString = [[NSUserDefaults standardUserDefaults] objectForKey:searchLocationKey];
#define DEBUG_ROOT_PATH 0
#if DEBUG_ROOT_PATH
    //aSearchString = @"/Users/inzan/Dropbox";
#else
    //aSearchString = @"/Users/inzan/Dropbox/Photos";
#endif
    self.searchLocation = [NSURL fileURLWithPath:aSearchString];
    //[[NSUserDefaults standardUserDefaults] objectForKey:@"sear"];
    //Point our searchLocation NSPathControl to the search location
    [searchLocationPathControl setURL:self.dropboxHome];
    
    
    //OLD SPOTLIGHT SEARCH
    //[self createNewSearchForWithScopeURLs:[self searchPaths]];
    
    [self loadAlbumsFromFileSystem];
    
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
    NSString *dropboxDir = [dirs lastObject];
    self.dropboxHomePath = dropboxDir;
    if (dropboxDir!=nil)
    {
        self.dropboxHome = [NSURL fileURLWithPath:[dirs lastObject] isDirectory:YES];
        NSData *bookmarkData = [self.dropboxHome bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                          includingResourceValuesForKeys:nil
                                                           relativeToURL:nil
                                                                   error:&error];
        DLog(@"update dropbox root Path : %@", self.dropboxHome.path);
        if(bookmarkData){
            [[NSUserDefaults standardUserDefaults] setObject:self.dropboxHomePath forKey:dropboxHomeStringKey];
            [[NSUserDefaults standardUserDefaults] setObject:bookmarkData forKey:dropboxHomeLocationKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self.dropboxHome startAccessingSecurityScopedResource];
        } else {
            DLog(@"Error creating security scoped bookmark : %@", error);
        }
        
        NSString *photosDirPath = [NSString stringWithFormat:@"%@/Photos", dropboxDir];
        self.searchLocation = [NSURL fileURLWithPath:photosDirPath isDirectory:YES];
        [searchLocationPathControl setURL:self.dropboxHome];
        [self updateRootSearchPath:self.searchLocation];
        return;
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
    //iSearchQueries = [[NSMutableArray alloc] init];
    
    
}

- (BOOL)windowShouldClose:(id)sender {
    NSLog(@"windowShouldClose was called");
    [self.searchLocation stopAccessingSecurityScopedResource];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    return YES;
}

-(void)showPhotosViewForAlbum:(NSNotification *)notification
{
    Album *anAlbum = notification.object;
    self.imageBrowserViewController  = [[ImageBrowserViewController alloc] initWithNibName:@"Collections" bundle:nil album:anAlbum];
    [self.imageBrowserViewController.view setFrame:self.targetView.bounds];
    [self.albumViewController.view removeFromSuperview];
    [self.targetView addSubview:self.imageBrowserViewController.view];// positioned:NSWindowAbove relativeTo:self.albumViewController.view];
    //[self.albumViewController.view setHidden:YES];
    //[window setContentView:self.imageBrowserViewController.view];
}

-(void)showMainView
{
    [window setContentView:self.mainContentView];
}

-(void)showAlbumView
{
    [self.albumArray makeObjectsPerformSelector:@selector(thumbnailImage)];
    //[[self window] setAutorecalculatesContentBorderThickness:YES forEdge:NSMinYEdge];
    //[[self window] setContentBorderThickness:30 forEdge:NSMinYEdge];
    
    // load our nib that contains the collection view
    [self willChangeValueForKey:@"viewController"];
    
    [self didChangeValueForKey:@"viewController"];
    
    self.albumViewController.albums = self.albumArray;
    
    //self.targetView = self.albumViewController.view;
    
    // make sure we resize the viewController's view to match its super view
    CGRect aRect = [self.targetView bounds];
    aRect.size.height -= 50;
    aRect.origin.y -= 50;
    [self.albumViewController.view setFrame:aRect];
    
    [self.albumViewController setSortingMode:0];		// ascending sort order
    [self.albumViewController setAlternateColors:NO];	// no alternate background colors (initially use gradient background)
    
    for (NSView * aView in self.targetView.subviews)
    {
        [aView removeFromSuperview];
    }
    [self.targetView addSubview:self.albumViewController.view];
    //[window setContentView:self.mainContentView];
}


-(NSMutableArray *)albumArray;
{
    return self.directoryArray;
}

-(NSArray *)searchPaths
{
    if ([self.searchLocation.path isEqualToString:self.dropboxHome.path])
    {
        return [NSArray arrayWithObject:self.dropboxHome];
    } else {
        NSAssert(self.dropboxHomePath!=nil, @"self.dropboxHomePath not set");
        NSString *aPath = [NSString stringWithFormat:@"%@/Camera Uploads", self.dropboxHomePath];
        self.cameraUploadsLocation = [NSURL fileURLWithPath:aPath];
        return [NSArray arrayWithObjects:self.searchLocation, self.cameraUploadsLocation, nil];
    }
}

#pragma mark - NSPathControl support

-(void)updateRootSearchPath:(NSURL *)newRootSearchPath
{
    self.searchLocation = newRootSearchPath;
    //self.dropboxHome = newRootSearchPath;
    [[NSUserDefaults standardUserDefaults] setObject:self.searchLocation.path forKey:searchLocationKey];
    //[[NSUserDefaults standardUserDefaults] setObject:self.dropboxHome.path forKey:dropboxHomeStringKey];
    //[[NSUserDefaults standardUserDefaults] synchronize];
    
    /*NSData *bookmarkData = [self.searchLocation bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                         includingResourceValuesForKeys:nil
                                                          relativeToURL:nil
                                                                  error:nil];
    DLog(@"updateRootSearchPath : %@", newRootSearchPath.path);
    if(bookmarkData){
        [[NSUserDefaults standardUserDefaults] setObject:bookmarkData forKey:@"searchLocationKey"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.searchLocation startAccessingSecurityScopedResource];
    }*/
    
    
    [self resetProperties];
    [self.tableView reloadData];
    [self.outlineView reloadData];
    
    //OLD SPOTLIGHT SEARCH
    //[self createNewSearchForWithScopeURLs:[self searchPaths]];
    
    [self loadAlbumsFromFileSystem];
    //[self.fileSystemEventController startObserving];
}

//NSFilePathControl calls this when user selects a new root directory
- (IBAction)searchLocationChanged:(id)sender {
    
    //NSURL *oldSearchURL = self.searchLocation;
    NSURL *newURL = (NSURL *)[sender URL];
    [self updateRootSearchPath:newURL];
    
    /*if (oldSearchURL!=nil)
    {
        [oldSearchURL stopAccessingSecurityScopedResource];
    }*/
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
#ifdef DEBUG
    [openPanel setTreatsFilePackagesAsDirectories:YES];
#endif
    
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
    if (!self.albumArray) {
        return 0;
    }
    return [self.albumArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if (rowIndex < self.albumArray.count)
    {
        Album *album = [self.albumArray objectAtIndex:rowIndex];
        return album.title;
    } else {
        return @"";
    }
    
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
    } else if (anAlbum!=nil){
        self.selectedAlbum = anAlbum;
    } else {
        DLog(@"selectedAlbum in tableView doesn't exist - no need to update browserView");
        return;
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
    [window setTitle:anAlbum.filePath];
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

- (void)showPageControllerForAlbum:(Album *)anAlbum
{
    
    self.pageViewController = [[PageViewController alloc] initWithNibName:@"PageViewController" bundle:nil];


    
    //NSURL *aURL = [NSURL fileURLWithPath:[[[self albumArray] objectAtIndex:selectedRow ] valueForKey:@"filePath"]];
    self.pageViewController.album = anAlbum;
    self.pageViewController.initialSelectedItem = [self.selectedAlbum.photos objectAtIndex:0];
    
    self.pageViewController.parentWindowController = self;
    self.pageViewController.view.frame = ((NSView*)window.contentView).bounds;
    self.mainContentView = window.contentView;
    
    //self.pageViewController.pageController.selectedIndex = index;
    [window setContentView:self.pageViewController.view];
    
    NSLog(@"cellWasDoubleClickedAtIndex");
}

#pragma mark - NSSplitViewDelegate methods

// -------------------------------------------------------------------------------
//	canCollapseSubview:
//
//	This delegate allows the collapsing of the first and last subview.
// -------------------------------------------------------------------------------
- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    return NO;
}

// -------------------------------------------------------------------------------
//	shouldCollapseSubview:subView:dividerIndex
//
//	This delegate allows the collapsing of the first and last subview.
// -------------------------------------------------------------------------------
- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
    // yes, if you can collapse you should collapse it
    return NO;
}

// -------------------------------------------------------------------------------
//	constrainMinCoordinate:proposedCoordinate:index
// -------------------------------------------------------------------------------
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedCoordinate ofSubviewAt:(NSInteger)index
{
    return kMinContrainValue;
}

// -------------------------------------------------------------------------------
//	constrainMaxCoordinate:proposedCoordinate:proposedCoordinate:index
// -------------------------------------------------------------------------------
- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedCoordinate ofSubviewAt:(NSInteger)index
{
    CGFloat constrainedCoordinate = proposedCoordinate;
    if (index == ([[splitView subviews] count] - 2))
	{
		constrainedCoordinate = proposedCoordinate - kMinContrainValue;
    }
	
    return kMinContrainValue;
}

-(void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize: (NSSize)oldSize
{
    CGFloat dividerThickness = [sender dividerThickness];
    NSRect leftRect = [[[sender subviews] objectAtIndex:0] frame];
    NSRect rightRect = [[[sender subviews] objectAtIndex:1] frame];
    NSRect newFrame = [sender frame];
    
 	leftRect.size.height = newFrame.size.height;
	leftRect.origin = NSMakePoint(0, 0);
	rightRect.size.width = newFrame.size.width - leftRect.size.width
	- dividerThickness;
	rightRect.size.height = newFrame.size.height;
	rightRect.origin.x = leftRect.size.width + dividerThickness;
    
 	[[[sender subviews] objectAtIndex:0] setFrame:leftRect];
	[[[sender subviews] objectAtIndex:1] setFrame:rightRect];
}

#pragma mark -
#pragma mark Browser Drag and Drop Methods

-(BOOL) optionKeyIsPressed
{
    if(( [NSEvent modifierFlags] & NSAlternateKeyMask ) != 0 ) {
        return YES;
    } else {
        return NO;
    }
    
}
- (unsigned int)draggingEntered:(id <NSDraggingInfo>)sender
{

	if([sender draggingSource] != self){
		NSPasteboard *pb = [sender draggingPasteboard];
		NSString * type = [pb availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]];
		
		if(type != nil){
            if ([self optionKeyIsPressed])
            {
                return NSDragOperationMove;
            } else {
                return NSDragOperationCopy;
            }
		}
	}
	return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	if([sender draggingSource] != self){
        if ([self optionKeyIsPressed])
        {
            return NSDragOperationMove;
        } else {
            return NSDragOperationCopy;
        }
	}
	return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    [self.browserView setAnimates:YES];
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSFileManager * fileManager = [NSFileManager defaultManager];
	//Get the files from the drop
	NSArray * files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	
	/*for(id file in files){
		NSImage * image = [[NSWorkspace sharedWorkspace] iconForFile:file];
		NSString * imageID = [file lastPathComponent];
		DLog(@"File dragged abd dropped onto browser : %@", imageID);
		//IKBBrowserItem * item = [[IKBBrowserItem alloc] initWithImage:image imageID:imageID];
		//[self.browserData addObject:item];
        

	}*/
    
    // handle copied files
    NSError *anError = nil;
    for (NSString * url in files)
    {
        // check if the destination folder is different from the source folder
        if ([self.selectedAlbum.filePath isEqualToString:[  url stringByDeletingLastPathComponent]])
            continue;
        
        NSURL * destinationURL = [NSURL fileURLWithPath:self.selectedAlbum.filePath];
        
        NSURL *srcURL = [NSURL fileURLWithPath:url];
        destinationURL = [destinationURL URLByAppendingPathComponent:[url lastPathComponent]];
        
        //if ([sender draggingSourceOperationMask]!=NSDragOperationCopy)
        if ([self optionKeyIsPressed])
        {
            [fileManager moveItemAtURL:srcURL toURL:destinationURL error:&anError];
        } else {
            [fileManager copyItemAtURL:srcURL toURL:destinationURL error:&anError];
        }
        
    }
    if (anError!=nil)
    {
        DLog(@"error copying dragged files : %@", anError);
    }
	
	if([self.browserData count] > 0) {
        [self.selectedAlbum updatePhotosFromFileSystem];
        [self.browserView reloadData];
        return YES;
    }
	
	return NO;
}

- (void)concludeDragOperation:(id < NSDraggingInfo >)sender
{
    [self.browserView setAnimates:NO];
	[self.browserView reloadData];
}

-(CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    return 55;
}

- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    return [self.directoryArray count];
}


- (NSArray *)_childrenForItem:(id)item {
    NSArray *children;
    if (item == nil) {
        children = self.directoryArray;
    } else {
        children = [NSArray arrayWithObject:self.selectedAlbum];
    }
    return children;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return [self.directoryArray objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return NO;
}

-(id)outlineView:(NSOutlineView *) aView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return [item title];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    if ([self.outlineView selectedRow] != -1) {
        //Album *item = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
        Album *anAlbum =  [self.outlineView itemAtRow:[self.outlineView selectedRow]];
        if (self.selectedAlbum == anAlbum) {
            DLog(@"selectedAlbum didn't seem to change - no need to update browserView");
        } else if (anAlbum!=nil){
            self.selectedAlbum = anAlbum;
        } else {
            DLog(@"selectedAlbum in tableView doesn't exist - no need to update browserView");
            return;
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
        [window setTitle:anAlbum.filePath];
        [self.browserView reloadData];
    }
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    SidebarTableCellView *result = [outlineView makeViewWithIdentifier:@"MainCell" owner:self];
    result.album = (Album *)item;
    return result;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index
{
	// get the URLs
	NSArray * urls = [[info draggingPasteboard] readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]] options:nil];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    // handle copied files
    NSError *anError = nil;
    BOOL refreshSrcDir = NO;
    NSString *srcpath = nil;
    for (NSURL * url in urls)
    {
        // check if the destination folder is different from the source folder
        if ([self.dragDropDestination.filePath isEqualToString:[  url.path stringByDeletingLastPathComponent]] || !self.dragDropDestination)
            continue;
        
        NSURL * destinationURL = [NSURL fileURLWithPath:self.dragDropDestination.filePath];
        
        NSURL *srcURL = url;//NSURL fileURLWithPath:url];
        destinationURL = [destinationURL URLByAppendingPathComponent:[url.path lastPathComponent]];
        
        
        if ([info draggingSource] == self.browserView) {
            DLog(@"Drag and drop is from browser view - default to move operation");
            if ([self optionKeyIsPressed]) {
                [fileManager copyItemAtURL:srcURL toURL:destinationURL error:&anError];
            } else {
                [fileManager moveItemAtPath:srcURL.path toPath:destinationURL.path error:&anError];
                refreshSrcDir = YES;
                srcpath = [srcURL.path stringByDeletingLastPathComponent];
            }
        } else {
            DLog(@"Drag and drop is outside source - default to copy operation");
            if (![NSEvent modifierFlags] & NSAlternateKeyMask) {
                [fileManager copyItemAtURL:srcURL toURL:destinationURL error:&anError];
            } else {
                [fileManager moveItemAtPath:srcURL.path toPath:destinationURL.path error:&anError];
                refreshSrcDir = YES;
                srcpath = [srcURL.path stringByDeletingLastPathComponent];
            }
        }
        
    }
    if (anError!=nil)
    {
        DLog(@"error copying dragged files : %@", anError);
    }
	
	if([self.browserData count] > 0) {
        [self.dragDropDestination updatePhotosFromFileSystem];
        if (refreshSrcDir && srcpath) {
            Album *srcAlbum = [self.fileSystemEventController.albumLookupTable valueForKey:srcpath];
            [srcAlbum updatePhotosFromFileSystem];
        }
        [self.browserView reloadData];
        return YES;
    }
	
	return NO;
    
	//return YES;
}

/*- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
	if ([info draggingSource] == self.browserView) {
		
        if ([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSAlternateKeyMask)
            return NSDragOperationCopy;
        else
            return NSDragOperationMove;
	} else {
		return NSDragOperationCopy;
	}
}*/

-(NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    if (index != -1)
    {
        return NSDragOperationNone;
    }
	// always accept proposed item / index
	//[mDirectoryBrowserView setDropItem:item dropChildIndex:index];
    self.dragDropDestination = item;
	//return NSDragOperationMove;
    //return NSDragOperationCopy;
    //DLog(@"validateDrop : %ld", index);
    if ([info draggingSource] == self.browserView) {
		DLog(@"Drag and drop is from browser view - default to move operation");
        if ([self optionKeyIsPressed])
            return NSDragOperationCopy;
        else
            return NSDragOperationMove;
	} else {
        
        if (![self optionKeyIsPressed])
        {
            DLog(@"Drag and drop is outside source - default to copy operation");
            return NSDragOperationCopy;
        } else {
            DLog(@"Drag and drop is outside source with alt pressed - use move operation");
            return NSDragOperationMove;
        }
	}
    
    /*if(( [[[ NSApplication sharedApplication ] currentEvent ]
          modifierFlags ] & NSAlternateKeyMask ) != 0 ) {
        return NSDragOperationCopy;
    } else {
        return NSDragOperationMove;
    }
    return [self dropOperationForKeysPressed];*/
}

@end

