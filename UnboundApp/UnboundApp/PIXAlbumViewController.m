//
//  PIXAlbumViewController.m
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXAlbumViewController.h"
#import "PIXAppDelegate.h"
#import "PIXAppDelegate+CoreDataUtils.h"
#import "PIXFileSystemDataSource.h"
#import "PIXDefines.h"
#import "PIXSplitViewController.h"
#import "PIXNavigationController.h"
#import "Album.h"


@interface PIXAlbumViewController ()
{
    
}

@property (nonatomic, strong) NSToolbarItem * trashbutton;
@property (nonatomic, strong) NSToolbarItem * settingsButton;


@end

@implementation PIXAlbumViewController 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //NSImage *seedImage = [NSImage imageNamed:NSImageNameComputer];
        //NSDictionary *seedObject = @{@"title" : @"test", @"image" : seedImage};
        //self.albums = [NSMutableArray arrayWithObject:seedObject];
        //self.albums = [[PIXFileSystemDataSource sharedInstance] albums];
    }
    
    return self;
}

-(void)awakeFromNib
{
    if (arrayController == nil) {
        assert(NO);
    }
    
    [self.collectionView setMaxItemSize:NSSizeFromCGSize(CGSizeMake(300, 200))];
    [self.collectionView setMinItemSize:NSSizeFromCGSize(CGSizeMake(200, 200))];
    
    [self.collectionView setWantsLayer:YES];

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(albumsChanged:)
                                                 name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM
                                               object:nil];
    
    /*[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(photosChanged:)
                                                 name:kUB_PHOTOS_LOADED_FROM_FILESYSTEM
                                               object:[PIXFileSystemDataSource sharedInstance]];*/
    
    
}

-(void)setupToolbar
{
    NSArray * items = @[self.navigationViewController.middleSpacer, self.trashbutton, self.settingsButton];
    
    [self.navigationViewController setToolbarItems:items];
    
}
                        
- (NSToolbarItem *)trashbutton
{
    if(_trashbutton != nil) return _trashbutton;
    
    _trashbutton = [[NSToolbarItem alloc] initWithItemIdentifier:@"TrashButton"];
    _trashbutton.image = [NSImage imageNamed:NSImageNameTrashEmpty];
    
    [_trashbutton setLabel:@"Trash"];
    [_trashbutton setPaletteLabel:@"Trash"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_trashbutton setToolTip:@"View Trash"];
    
    // Tell the item what message to send when it is clicked
    //[_trashbutton setTarget:self];
    //[_trashbutton setAction:@selector(showTrash)];
#ifdef DEBUG
    // Tell the item what message to send when it is clicked
    [_trashbutton setTarget:[PIXAppDelegate sharedAppDelegate]];
    [_trashbutton setAction:@selector(deleteAllAlbums:)];
#endif
    
    return _trashbutton;
    
}

- (NSToolbarItem *)settingsButton
{
    if(_settingsButton != nil) return _settingsButton;
    
    _settingsButton = [[NSToolbarItem alloc] initWithItemIdentifier:@"SettingsButton"];
    _settingsButton.image = [NSImage imageNamed:NSImageNameSmartBadgeTemplate];
    
    [_settingsButton setLabel:@"Settings"];
    [_settingsButton setPaletteLabel:@"Settings"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_settingsButton setToolTip:@"Load Files"];
    
    // Tell the item what message to send when it is clicked
    [_settingsButton setTarget:[PIXAppDelegate sharedAppDelegate]];
    [_settingsButton setAction:@selector(showLoadingWindow:)];
    
    return _settingsButton;
    
}

-(void)showTrash
{
    
}

-(NSMutableArray *)albums
{
    //return [[PIXFileSystemDataSource sharedInstance] albums];
    return [[[PIXAppDelegate sharedAppDelegate] fetchAllAlbums] mutableCopy];
}

-(void)albumsChanged:(NSNotification *)notifcation
{
    [arrayController setContent:self.albums];
}

/*-(void)photosChanged:(NSNotification *)notifcation
{
    [arrayController setContent:self.albums];
}*/

-(void)showPhotosForAlbum:(id)anAlbum
{
    PIXSplitViewController *aSplitViewController  = [[PIXSplitViewController alloc] initWithNibName:@"PIXSplitViewController" bundle:nil];
    aSplitViewController.selectedAlbum = anAlbum;
    [aSplitViewController.view setFrame:self.view.bounds];
    [self.navigationViewController pushViewController:aSplitViewController];
}

- (void)doubleClick:(id)sender {
	NSLog(@"Double clicked on icon: %@", [[sender representedObject] valueForKey:@"title"]);
    id anAlbum = [sender representedObject];
    [self showPhotosForAlbum:anAlbum];
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"ShowPhotos" object:[sender representedObject]];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.albums = nil;
}

@end

@implementation IconViewBox

// -------------------------------------------------------------------------------
//	hitTest:aPoint
// -------------------------------------------------------------------------------
- (NSView *)hitTest:(NSPoint)aPoint
{
    // don't allow any mouse clicks for subviews in this NSBox
    if(NSPointInRect(aPoint,[self convertRect:[self bounds] toView:[self superview]])) {
		return self;
	} else {
		return nil;
	}
}

-(void)mouseDown:(NSEvent *)theEvent {
	[super mouseDown:theEvent];
    
	// check for click count above one, which we assume means it's a double click
	if([theEvent clickCount] > 1) {
		DLog(@"double click!");
		if(delegate && [delegate respondsToSelector:@selector(doubleClick:)]) {
            [delegate performSelector:@selector(doubleClick:) withObject:theEvent];
        }
	}
    
    if(( [NSEvent modifierFlags] & NSCommandKeyMask ) != 0 ) {
        DLog(@"mouseDown with command pressed");
        if(delegate && [delegate respondsToSelector:@selector(rightMouseDown:)]) {
            [delegate performSelector:@selector(rightMouseDown:) withObject:theEvent];
        }
    } else {
        DLog(@"mouseDown");
    }
}

-(void)rightMouseDown:(NSEvent *)theEvent {
    DLog(@"rightMouseDown:%@", theEvent);
    
    if(delegate && [delegate respondsToSelector:@selector(rightMouseDown:)]) {
        [delegate performSelector:@selector(rightMouseDown:) withObject:theEvent];
    }
}


@end
