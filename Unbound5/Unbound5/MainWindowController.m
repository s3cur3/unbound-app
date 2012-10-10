//
//  MainWindowController.m
//  Unbound5
//
//  Created by Bob on 10/4/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "MainWindowController.h"
#import "SearchQuery.h"
//#import "IKBBrowserItem.h"
#import "PageViewController.h"
#import "ImageViewController.h"
#import "IKImageViewController.h"

@interface MainWindowController()

@property (strong) NSURL *searchLocation;
//- (void)updatePathControl;

@end

@implementation MainWindowController


- (void)awakeFromNib {
    
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
    } else {
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        [openPanel setAllowsMultipleSelection:NO];
        [openPanel setMessage:@"Choose a location to search for photos and images:"];
        [openPanel setCanChooseDirectories:YES];
        [openPanel setCanChooseFiles:NO];
        [openPanel setPrompt:@"Choose"];
        [openPanel setTitle:@"Choose Location"];
        
        // set the default location to the Documents folder
        NSArray *documentsFolderPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSURL *dbURL = [NSURL URLWithString:@"/Users/inzan/Documents/Dropbox"];
        [openPanel setDirectoryURL:dbURL];
        //[openPanel setDirectoryURL:[NSURL fileURLWithPath:[documentsFolderPath objectAtIndex:0]]];
        [openPanel beginSheetModalForWindow:window
                          completionHandler:^(NSInteger returnCode) {
                              /* the completion handler */
                              NSLog(@"done open panel");
                          }];
        //[NSApp runModalForWindow:panel];
        //[window addChildWindow:panel ordered:NSWindowAbove];
        return;
    }
    
    self.directoryArray = [[NSMutableArray alloc] init];
    self.browserData = [[NSMutableArray alloc] init];
    iSearchQueries = [[NSMutableArray alloc] init];
    //iThumbnailSize = 32.0;
    

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(queryChildrenChanged:)
                                                 name:SearchQueryChildrenDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(searchItemChanged:)
                                                 name:SearchItemDidChangeNotification
                                               object:nil];
    /*iGroupRowCell = [[NSTextFieldCell alloc] init];
    [iGroupRowCell setEditable:NO];
    [iGroupRowCell setLineBreakMode:NSLineBreakByTruncatingTail];
    

    [resultsOutlineView setTarget:self];
    [resultsOutlineView setDoubleAction:@selector(resultsOutlineDoubleClickAction:)];
    
    NSString *placeHolderStr = NSLocalizedString(@"Select an item to show its location.", @"Placeholder string for location items");
    [[pathControl cell] setPlaceholderString:placeHolderStr];
    [pathControl setTarget:self];
    [pathControl setDoubleAction:@selector(pathControlDoubleClick:)];
    
    [predicateEditor setRowHeight:25];
    
    // add some rows
    [[predicateEditor enclosingScrollView] setHasVerticalScroller:NO];
    iPreviousRowCount = 3;
    [predicateEditor addRow:self];
    
    // put the focus in the text field
    id displayValue = [[predicateEditor displayValuesForRow:1] lastObject];
    if ([displayValue isKindOfClass:[NSControl class]])
        [window makeFirstResponder:displayValue];
    
    [self updatePathControl];*/
    
    [window setDelegate:self];  // we want to be notified when this window is closed
    
#ifdef DEBUG
    [self.browserView setCellsStyleMask:IKCellsStyleTitled | IKCellsStyleSubtitled];
#endif
    
    if (self.searchLocation == nil)
    {
        // we don't have a default search location setup yet,
        // default our searchLocation pointing to "Pictures" folder
        //
        //NSArray *picturesDirectory = NSSearchPathForDirectoriesInDomains(NSPicturesDirectory, NSUserDomainMask, YES);
        //self.searchLocation = [NSURL fileURLWithPath:[picturesDirectory objectAtIndex:0]];
        
        // write out the NSURL as a security-scoped bookmark to NSUserDefaults
        // (so that we can resolve it again at re-launch)
        //
        /*NSData *bookmarkData = [self.searchLocation bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                             includingResourceValuesForKeys:nil
                                                              relativeToURL:nil
                                                                      error:&error];*/
        //[[NSUserDefaults standardUserDefaults] setObject:bookmarkData forKey:@"searchLocationKey"];
        //[[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        /*NSData *bookmarkData = [self.searchLocation bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                             includingResourceValuesForKeys:nil
                                                              relativeToURL:nil
                                                                      error:nil];
        [[NSUserDefaults standardUserDefaults] setObject:bookmarkData forKey:@"searchLocationKey"];
        [[NSUserDefaults standardUserDefaults] synchronize];*/
        
        [self.searchLocation startAccessingSecurityScopedResource];
        [self refreshBrowser];
    }
    
    // lastly, point our searchLocation NSPathControl to the search location
    [searchLocationPathControl setURL:self.searchLocation];
    

}

- (BOOL)windowShouldClose:(id)sender {
    NSLog(@"windowShouldClose was called");
    for (SearchQuery *query in iSearchQueries) {
        // we are no longer interested in accessing SearchQuery's bookmarked search location,
        // so it's important we balance the start/stop access to security scoped bookmarks here
        //
        //[[query _searchURL] stopAccessingSecurityScopedResource];
    }
    [self.searchLocation stopAccessingSecurityScopedResource];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    return YES;
}

-(void)showMainView
{
    [window setContentView:self.mainContentView];
}

//- (void)createNewSearchForPredicate:(NSPredicate *)predicate withTitle:(NSString *)title withScopeURL:(NSURL *)url
- (void)createNewSearchForWithScopeURL:(NSURL *)url {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(kMDItemContentTypeTree = 'public.image') OR  (kMDItemContentTypeTree = 'public.movie')"];

        
    //TODO: add video/custom query support
    //predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:imagesPredicate, predicate, nil]];
    
    // we are interested in accessing this bookmark for our SearchQuery class
    //NSURL *url = self.searchLocation;
    //[url startAccessingSecurityScopedResource];
    
    // Create an instance of our datamodel and keep track of things.
    SearchQuery *searchQuery = [[SearchQuery alloc] initWithSearchPredicate:predicate title:@"Search" scopeURL:url];
    [iSearchQueries addObject:searchQuery];
    //[searchQuery release];
    
    // Reload the children of the root item, "nil". This only works on 10.5 or higher
    /*[resultsOutlineView reloadItem:nil reloadChildren:YES];
    [resultsOutlineView expandItem:searchQuery];
    NSInteger row = [resultsOutlineView rowForItem:searchQuery];
    [resultsOutlineView scrollRowToVisible:row];
    [resultsOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];*/
    
}

-(NSMutableArray *)searchItemsFromResults:(NSArray *)children forDirectory:(NSString *)path
{
    //Add a trailing slash to match the metdataitems
    if (![path hasSuffix:@"/"])
    {
        path = [NSString stringWithFormat:@"%@/",path];
    }
    NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity:[children count] ];
    for (SearchItem *item in children)
    {
        if ([self.browserData containsObject:item])
        {
            continue;
        }
        //NSLog(@"item : %@", [item debugDescription]);

        NSString *fullPath = [item.metadataItem valueForAttribute:(NSString *)kMDItemPath];
        NSString *fileName = [item.metadataItem valueForAttribute:(NSString *)kMDItemFSName];
        NSScanner *scanner = [NSScanner scannerWithString:fullPath];
        NSString *dirPath = nil;
        [scanner scanUpToString:fileName intoString:&dirPath];

        if ([path isEqualToString:dirPath])
        {
            [tmpArray addObject:item];
        }
        
    }
    return tmpArray;
}

- (void)queryChildrenChanged:(NSNotification *)note {
    NSLog(@"searchItemChanged : %@", note);
    SearchQuery *query = (SearchQuery *)[note object];
    NSLog(@"children : %@", query.children);
    /*for (SearchItem *item in query.children)
    {
        NSLog(@"item : %@", [item debugDescription]);
        if (item.thumbnailImage!=nil)
        {
            IKBBrowserItem *bItem = [[IKBBrowserItem alloc] init];
            bItem.url = item.filePathURL;
            bItem.image = item.thumbnailImage;
            [self.browserData addObject:bItem];
        }
    }*/
    
    //Filter for the correct directory
    //NSString *path = [_item valueForAttribute:(NSString *)kMDItemPath];
    
    
    self.browserData = [self searchItemsFromResults:query.children forDirectory:[query._searchURL path]];//[NSMutableArray arrayWithArray:query.children];
    [self.browserView reloadData];
    //[resultsOutlineView reloadItem:[note object] reloadChildren:YES];
}

- (void)searchItemChanged:(NSNotification *)note {
    NSLog(@"searchItemChanged : %@", note);
    SearchItem *item = (SearchItem *)[note object];
    NSLog(@"item : %@", [item debugDescription]);
    /*if (item.thumbnailImage!=nil)
    {
        IKBBrowserItem *bItem = [[IKBBrowserItem alloc] init];
        bItem.url = item.filePathURL;
        bItem.image = item.thumbnailImage;
        [self.browserData addObject:bItem];
        [self.browserView reloadData];
    }*/
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

-(void)loadSubDirectoryInfo:(NSURL *)dirURL
{
    [self.directoryArray removeAllObjects];
    NSMutableDictionary *currentDirectory = [[NSMutableDictionary alloc] init];
    //FileSystemItem anItem = [[[FileSystemItem alloc] init];
    [currentDirectory setObject:[dirURL lastPathComponent] forKey:@"Name"];
    NSImage *image = [NSImage imageNamed:@"NSFolder"];
    [currentDirectory setObject:image forKey:@"Image"];
    [currentDirectory setObject:dirURL forKey:@"URL"];
    [self.directoryArray addObject:currentDirectory];
    
    NSDirectoryEnumerator *itr = [[NSFileManager defaultManager] enumeratorAtURL:dirURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLLocalizedNameKey, NSURLEffectiveIconKey, NSURLIsDirectoryKey, NSURLTypeIdentifierKey, nil] options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants /*| NSDirectoryEnumerationSkipsSubdirectoryDescendants*/ errorHandler:nil];
    
    for (NSURL *url in itr) {
        //NSString *utiValue;
        //[url getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:nil];
        
        NSError *error = nil;
        id isDirectoryValue;
        if ([url getResourceValue:&isDirectoryValue forKey:NSURLIsDirectoryKey error:&error])
        {
            NSLog(@"isDirectoryValue : %@", isDirectoryValue);
        } else {
            NSLog(@"error : %@", error);
        }
        
        
        if ([isDirectoryValue boolValue])//(UTTypeConformsTo((__bridge CFStringRef)(utiValue), kUTTypeFolder)) {
        {
            NSMutableDictionary *aSubDir = [[NSMutableDictionary alloc] init];
            //FileSystemItem anItem = [[[FileSystemItem alloc] init];
            [aSubDir setObject:[url lastPathComponent] forKey:@"Name"];
            NSImage *image = [NSImage imageNamed:@"NSFolder"];
            [aSubDir setObject:image forKey:@"Image"];
            [aSubDir setObject:url forKey:@"URL"];
            [self.directoryArray addObject:aSubDir];
            NSLog(@"Adding subdir at url : %@", url.path);
        }
        
        /*if (UTTypeConformsTo((__bridge CFStringRef)(utiValue), kUTTypeImage)) {
            NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
            IKBBrowserItem *anObject = [[IKBBrowserItem alloc] init];
            anObject.image = image;
            anObject.url = url;
            [self.browserData addObject:anObject];
        } else if (UTTypeConformsTo((__bridge CFStringRef)(utiValue), kUTTypeFolder)) {
            NSMutableDictionary *aSubDir = [[NSMutableDictionary alloc] init];
            //FileSystemItem anItem = [[[FileSystemItem alloc] init];
            [aSubDir setObject:[url lastPathComponent] forKey:@"Name"];
            NSImage *image = [NSImage imageNamed:@"NSFolder"];
            [aSubDir setObject:image forKey:@"Image"];
            [aSubDir setObject:url forKey:@"URL"];
            [self.directoryArray addObject:aSubDir];
            NSLog(@"Adding subdir at url : %@", url.path);
        } else {
            NSLog(@"Skipping file at url : %@", url.path);
        }*/
    }
    
    [self.tableView reloadData];
}

-(void)refreshBrowser
{
    //[self.browserData removeAllObjects];
    //[self.browserView reloadData];
    //NSURL *url = self.searchLocation;
    
    //[self loadPhotosForURL:self.searchLocation];
    [self createNewSearchForWithScopeURL:self.searchLocation];
    [self loadSubDirectoryInfo:self.searchLocation];
    
    [self.browserView reloadData];
}

#pragma mark - NSPathControl support

- (IBAction)searchLocationChanged:(id)sender {
    
    
    
    [self.browserData removeAllObjects];
    self.searchLocation = [sender URL];
    
    
    // write out the NSURL as a security-scoped bookmark to NSUserDefaults
    // (so that we can resolve it again at re-launch)
    //
    NSData *bookmarkData = [self.searchLocation bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                         includingResourceValuesForKeys:nil
                                                          relativeToURL:nil
                                                                  error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:bookmarkData forKey:@"searchLocationKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.searchLocation startAccessingSecurityScopedResource];
    [self refreshBrowser];
    //[self.directoryArray removeAllObjects];
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
    return [self.directoryArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return [[self.directoryArray objectAtIndex:rowIndex] objectForKey:@"Name"];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSLog(@"tableViewSelectionDidChange : %@", aNotification.object);
    NSDictionary *newDir =  [self.directoryArray objectAtIndex:[self.tableView selectedRow]];
    
    //[self.browserData removeAllObjects];
    //[self.browserView reloadData];
    NSURL *searchURL = [newDir valueForKey:@"URL"];
    [self createNewSearchForWithScopeURL:searchURL];
    
    //[url startAccessingSecurityScopedResource];
    //[self loadPhotosForURL:searchURL];
    //[url stopAccessingSecurityScopedResource];
    [self.browserView reloadData];
}

// This method is optional if you use bindings to provide the data
/*- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // Group our "model" object, which is a dictionary
    NSDictionary *dictionary = [self.directoryArray objectAtIndex:row];
    
    // In IB the tableColumn has the identifier set to the same string as the keys in our dictionary
    NSString *identifier = [tableColumn identifier];
    
    if (YES || [identifier isEqualToString:@"MainCell"]) {
        // We pass us as the owner so we can setup target/actions into this main controller object
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
        // Then setup properties on the cellView based on the column
        cellView.textField.stringValue = [dictionary objectForKey:@"Name"];
        cellView.imageView.image = [dictionary objectForKey:@"Image"];
        return cellView;
    } else if ([identifier isEqualToString:@"SizeCell"]) {
        NSTextField *textField = [tableView makeViewWithIdentifier:identifier owner:self];
        NSImage *image = [dictionary objectForKey:@"Image"];
        NSSize size = image ? [image size] : NSZeroSize;
        NSString *sizeString = [NSString stringWithFormat:@"%.0fx%.0f", size.width, size.height];
        textField.objectValue = sizeString;
        return textField;
    } else {
        NSAssert1(NO, @"Unhandled table column identifier %@", identifier);
    }
    return nil;
}*/


// -------------------------------------------------------------------------------
//	imageBrowserSelectionDidChange:aBrowser
//
//	User chose a new image from the image browser.
// -------------------------------------------------------------------------------
- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser
{
	/*NSIndexSet *selectionIndexes = [aBrowser selectionIndexes];
     
     if ([selectionIndexes count] > 0)
     {
     NSDictionary *screenOptions = [[NSWorkspace sharedWorkspace] desktopImageOptionsForScreen:curScreen];
     
     MyImageObject *anItem = [images objectAtIndex:[selectionIndexes firstIndex]];
     NSURL *url = [anItem imageRepresentation];
     
     NSNumber *isDirectoryFlag = nil;
     if ([url getResourceValue:&isDirectoryFlag forKey:NSURLIsDirectoryKey error:nil] && ![isDirectoryFlag boolValue])
     {
     /*NSError *error = nil;
     [[NSWorkspace sharedWorkspace] setDesktopImageURL:url
     forScreen:curScreen
     options:screenOptions
     error:&error];
     if (error)
     {
     [NSApp presentError:error];
     }* /
     
     //IKImageEditPanel *editor = [IKImageEditPanel sharedImageEditPanel];
     IKImageView *anImageView = [[IKImageView alloc] init];
     [anImageView setImageWithURL: url];
     //[editor setDataSource: anImageView];
     //[anImageView makeKeyAndOrderFront: nil];
     
     }
     }*/
    
    NSLog(@"imageBrowserSelectionDidChange");
}

// -------------------------------------------------------------------------------
//  imageBrowser:cellWasDoubleClickedAtIndex:index
// -------------------------------------------------------------------------------
- (void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index
{
    //[_imageBrowser setHidden:YES];
    /*MyImageObject *anItem = (MyImageObject *)[_images objectAtIndex:index];
     //NSURL *dirURL = [NSURL fileURLWithPath:@"/Users/inzan/Dropbox/Camera Uploads"];
     //NSURL *url = [NSURL fileURLWithPath:[anItem imageRepresentation]];
     //[_imageView setHidden:NO];
     //NSData *data = UIImageJPEGRepresentation(anItem.image, 1.0);
     NSImage *anImage = anItem.image;
     //CIImage * image = [CIImage imageWithContentsOfURL: anItem.url];
     NSImageView *anImageView = [[NSImageView alloc] initWithFrame:CGRectMake(0,0,400,400)];
     [anImageView setImage:anImage];
     //CGImageRef imageRef = anImage.CGImage;
     //[_imageView setImageWithURL:url];
     
     [anImageView setNeedsDisplay:YES];
     [aBrowser addSubview:anImageView];
     [aBrowser setNeedsDisplay:YES];*/
    
    
    
    //[[[AppDelegate applicationDelegate] mainWindowController] showPageViewForIndex:index];
    
    
    self.pageViewController = [[PageViewController alloc] initWithNibName:@"PageViewController" bundle:nil];
    NSInteger selectedRow = self.tableView.selectedRow;
    if (selectedRow<0 || selectedRow>[self.directoryArray count]) {
        selectedRow = 0;
    }
    NSURL *aURL = [[self.directoryArray objectAtIndex:selectedRow ] valueForKey:@"URL"];
    self.pageViewController.directoryURL = aURL;
    
    self.pageViewController.searchData = self.browserData;
    self.pageViewController.parentWindowController = self;
    self.pageViewController.view.frame = ((NSView*)window.contentView).bounds;
    self.mainContentView = window.contentView;
    self.pageViewController.pageController.selectedIndex = index;
    [window setContentView:self.pageViewController.view];
    
    
    
    
    

    
    
    /*ImageViewController *aViewController = [[ImageViewController alloc] initWithNibName:@"ImageViewController" bundle:nil];
    aViewController.view.frame = ((NSView*)window.contentView).bounds;
    [window setContentView:aViewController.view];*/
    
    
    NSLog(@"cellWasDoubleClickedAtIndex");
}


@end
