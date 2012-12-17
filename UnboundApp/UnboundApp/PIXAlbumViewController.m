//
//  PIXAlbumViewController.m
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXAlbumViewController.h"
#import "PIXAppDelegate.h"
#import "PIXFileSystemDataSource.h"
#import "PIXDefines.h"
#import "PIXSplitViewController.h"
#import "PIXNavigationController.h"
#import "Album.h"

extern NSString *kUB_ALBUMS_LOADED_FROM_FILESYSTEM;

@interface PIXAlbumViewController ()
{
    
}



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
                                               object:[PIXFileSystemDataSource sharedInstance]];
}

-(NSMutableArray *)albums
{
    return [[PIXFileSystemDataSource sharedInstance] albums];
}

-(void)albumsChanged:(NSNotification *)notifcation
{
    [arrayController setContent:self.albums];
}

-(void)showPhotosForAlbum:(Album *)anAlbum
{
    PIXSplitViewController *aSplitViewController  = [[PIXSplitViewController alloc] initWithNibName:@"PIXSplitViewController" bundle:nil];
    aSplitViewController.selectedAlbum = anAlbum;
    [aSplitViewController.view setFrame:self.view.bounds];
    [self.navigationViewController pushViewController:aSplitViewController];
}

- (void)doubleClick:(id)sender {
	NSLog(@"Double clicked on icon: %@", [[sender representedObject] valueForKey:@"title"]);
    Album *anAlbum = [sender representedObject];
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
