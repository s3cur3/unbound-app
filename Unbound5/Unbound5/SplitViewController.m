//
//  SplitViewController.m
//  Unbound
//
//  Created by Bob on 11/7/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "SplitViewController.h"
#import "Album.h"
#import "ImageBrowserViewController.h"
#import "SidebarViewController.h"
#import "PINavigationViewController.h"

@interface SplitViewController ()

@end

@implementation SplitViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil albums:(NSArray *)newAlbums selectedAlbum:(Album *)aSelectedAlbum
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        self.imageBrowserViewController = [[ImageBrowserViewController alloc] initWithNibName:@"ImageBrowserViewController" bundle:nil album:aSelectedAlbum];
        self.albums = newAlbums;
        self.selectedAlbum = aSelectedAlbum;
        
        self.sidebarViewController = [[SidebarViewController alloc] initWithNibName:@"SidebarViewController" bundle:nil];
        self.sidebarViewController.splitViewController = self;
        //self.sidebarViewController.outlineView.dataSource = self;
        
        self.sidebarViewController.mainWindow = (MainWindowController *) [[[NSApplication sharedApplication] mainWindow] delegate];
    }
    
    return self;
}

-(void)awakeFromNib
{
    self.sidebarViewController.selectedAlbum = self.selectedAlbum;
    self.sidebarViewController.directoryArray = [self.albums mutableCopy];
    
    [self.sidebarViewController.view setFrame:self.leftPane.bounds];
    [self.leftPane addSubview:self.sidebarViewController.view];
    [self.sidebarViewController.outlineView reloadData];
    
    self.imageBrowserViewController.album = self.selectedAlbum;
    [self.imageBrowserViewController.view setFrame:self.rightPane.bounds];
    [self.rightPane addSubview:self.imageBrowserViewController.view];
    //self.rightPane = self.imageBrowserViewController.browserView;
    [self.imageBrowserViewController.browserView reloadData];
}

-(void)setNavigationViewController:(PINavigationViewController *)newNavigationViewController
{
    super.navigationViewController = newNavigationViewController;
    self.imageBrowserViewController.navigationViewController = newNavigationViewController;
}

-(void)updateViewsForDragDrop
{
    [self.imageBrowserViewController.album updatePhotosFromFileSystem];
    self.imageBrowserViewController.browserData = self.imageBrowserViewController.album.photos;
    [self.imageBrowserViewController.browserView reloadData];
    //[self.imageBrowserViewController.browserView reloadData]
}



@end

@implementation SplitViewController(NSOutlineViewDataSource)

//Working with Items in a View
-(CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    return 55;
}

- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    return [self.albums count];
}


- (NSArray *)_childrenForItem:(id)item {
    NSArray *children;
    if (item == nil) {
        children = self.albums;
    } else {
        children = [NSArray arrayWithObject:self.selectedAlbum];
    }
    return children;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return [self.albums objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return NO;
}

-(id)outlineView:(NSOutlineView *) aView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return [item title];
}


//

//Drag and Drop Support

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
        
        
        if ( [[[info draggingSource] identifier] isEqualToString:@"MyImageBrowserView"]) {
            //DLog(@"Drag and drop is from browser view - default to move operation");
            if ([PIViewController optionKeyIsPressed]) {
                [fileManager copyItemAtURL:srcURL toURL:destinationURL error:&anError];
            } else {
                [fileManager moveItemAtPath:srcURL.path toPath:destinationURL.path error:&anError];
                refreshSrcDir = YES;
                srcpath = [srcURL.path stringByDeletingLastPathComponent];
            }
        } else {
            //DLog(@"Drag and drop is outside source - default to copy operation");
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
    
    [self.dragDropDestination updatePhotosFromFileSystem];
    [self updateViewsForDragDrop];
	
	/*if([self.browserData count] > 0) {
     [self.dragDropDestination updatePhotosFromFileSystem];
     if (refreshSrcDir && srcpath) {
     Album *srcAlbum = [self.fileSystemEventController.albumLookupTable valueForKey:srcpath];
     [srcAlbum updatePhotosFromFileSystem];
     }
     [self.browserView reloadData];
     return YES;
     }*/
	
	return NO;
    
}



-(NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    if (index != -1)
    {
        return NSDragOperationNone;
    }
    
    self.dragDropDestination = item;
    
    if ( [[[info draggingSource] identifier] isEqualToString:@"MyImageBrowserView"])
    {
		
        if ([PIViewController optionKeyIsPressed]) {
            DLog(@"Drag and drop is from browser WITH alt key pressed - copy operation");
            return NSDragOperationCopy;
        } else {
            DLog(@"Drag and drop is from browser - move operation");
            return NSDragOperationMove;
        }
	} else {
        
        if (![PIViewController optionKeyIsPressed])
        {
            DLog(@"Drag and drop is outside source - default to copy operation");
            return NSDragOperationCopy;
        } else {
            DLog(@"Drag and drop is outside source with alt pressed - use move operation");
            return NSDragOperationMove;
        }
	}
    
}


@end
