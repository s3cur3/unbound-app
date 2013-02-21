//
//  PIXSidebarTableCellView.m
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXSidebarTableCellView.h"
#import "Album.h"
#import "PIXAlbum.h"
#import "PIXDefines.h"

@implementation PIXSidebarTableCellView

- (void)awakeFromNib {
    // We want it to appear "inline"
    //[[self.button cell] setBezelStyle:NSInlineBezelStyle];
    NSImage *anImage = [NSImage imageNamed:@"nophoto"];
    
    
    [self.imageView setImage:anImage];
    [self.imageView setImageScaling:NSImageScaleNone];
    //[self.imageView setImageFrameStyle:NSImagef:]
    [self.detailTextLabel setStringValue:@"Loading..."];
    
    [self.imageView setWantsLayer:YES];
    
    
    
    //[self.imageView.layer setShadowOffset:CGSizeMake(0, -1)];
}

-(void)updateLayer
{
    [self.imageView.layer setBorderColor:[[NSColor colorWithCalibratedWhite:0.0 alpha:0.4] CGColor]];
    [self.imageView.layer setBorderWidth:1.0];
    [self.imageView.layer setCornerRadius:2.5];
    
    /*
    
    CGColorRef color = CGColorCreateGenericGray(1.0, 1.0);
    [self.imageView.layer setBackgroundColor:color];
    [self.imageView.layer setShadowOpacity:1.0];
    [self.imageView.layer setShadowRadius:2.0];
    [self.imageView.layer setShadowColor:[NSColor blackColor].CGColor];
    [self.imageView.layer setShadowOffset:CGSizeMake(0, -1)];*/
}

- (void)dealloc {

}

-(void)setFrame:(NSRect)frameRect
{
    // i wasn't able to figure out where the 10px inset was coming
    // from in the cells. I'm fixing it here but it's a bit of a hack. (scott)
    frameRect.size.width += 10;
    [super setFrame:frameRect];
    
}

-(void)updateSubtitle
{
    
    if ([self.detailTextLabel.stringValue isEqualToString:[_album imageSubtitle]]==NO) {
        DLog(@"Update subtitle for view with album : %@", self.album.title);
        [self.detailTextLabel setStringValue:[self.album imageSubtitle]];
        [self setNeedsDisplay:YES];
    }
}

-(void)updateAlbumView:(NSNotification *)note
{
    //if (note.object == self.album) {
    
    if([self.album.stackPhotos count] > 0)
    {
        NSImage * thumb = [[self.album.stackPhotos objectAtIndex:0] thumbnailImage];
        [self.imageView setImage:thumb];
    }
    
    else
    {
        self.imageView.image = nil;
    }
        
        
    if(self.imageView.image == nil)
    {
        [self.imageView setImage:[NSImage imageNamed:@"nophoto"]];
    }
    
    [self updateSubtitle];
    [self setNeedsDisplay:YES];
    /*} else {
        DLog(@"Received a notification for incorrect album : %@", note.object);
    }*/
}


-(void)setAlbum:(PIXAlbum *)newAlbum
{
    if (newAlbum!=_album)
    {
        if (_album != nil) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AlbumDidChangeNotification object:_album];
        }
        _album = newAlbum;
        if (_album != nil) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAlbumView:) name:AlbumDidChangeNotification object:_album];
            //            [[NSNotificationCenter defaultCenter] addObserverForName:AlbumPhotoCountDidChangeNotification object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            //                [self.detailTextLabel setStringValue:[_album imageSubtitle]];
            //            }];
            
            [self updateAlbumView:nil];
        }
        
        

    }
//    else {
//        [self updateSubtitle];
//    }
    
}


//-(void)setAlbum:(id)album
//{
//    BOOL firstLoad = NO;
//    //The first time album is set, no need to reload
//    if (_album==nil && album!=nil)
//    {
//        firstLoad = YES;
//    }
//    _album = album;
//    if (album) {
//        //[[[PIXAppDelegate sharedAppDelegate] window] setTitle:[self.album title]];
//        if (firstLoad == NO)
//        {
//            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAlbumView:) name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:album];
//        }
//    }
//}



// use this to switch text color when highligthed
- (void)setBackgroundStyle:(NSBackgroundStyle)style
{

        [super setBackgroundStyle:style];
        
        // If the cell's text color is black, this sets it to white
        //[((NSCell *)self.detailTextLabel.cell) setBackgroundStyle:style];
        
        // Otherwise you need to change the color manually
        switch (style) {
            case NSBackgroundStyleLight:
                [self.textField setTextColor:[NSColor blackColor]];
                [self.detailTextLabel setTextColor:[NSColor colorWithCalibratedWhite:0.4 alpha:1.0]];
                break;
                
            case NSBackgroundStyleDark:
            default:
                [self.textField setTextColor:[NSColor whiteColor]];
                [self.detailTextLabel setTextColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]];
                break;
        }

}


@end
