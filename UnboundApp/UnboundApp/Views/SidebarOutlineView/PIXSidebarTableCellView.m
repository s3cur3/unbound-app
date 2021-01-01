//
//  PIXSidebarTableCellView.m
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXSidebarTableCellView.h"
#import "PIXAlbum.h"
#import "PIXPhoto.h"
#import "PIXDefines.h"
#import "PIXFileManager.h"
#import "PIXAlbumCollectionViewItem.h"

@implementation PIXSidebarTableCellView

- (void)awakeFromNib {
    // We want it to appear "inline"
    //[[self.button cell] setBezelStyle:NSInlineBezelStyle];
    NSImage *anImage = [NSImage imageNamed:@"nophoto"];


    [self.imageView setImage:anImage];
    [self.imageView setImageScaling:NSImageScaleNone];
    //[self.imageView setImageFrameStyle:NSImagef:]
    [self.detailTextLabel setStringValue:@"Loading..."];


    //[self setWantsLayer:NO];



    //[self.imageView.layer setShadowOffset:CGSizeMake(0, -1)];
}

- (void)updateLayer {
    [self.imageView.layer setBorderColor:[[NSColor colorWithCalibratedWhite:0.0 alpha:0.4] CGColor]];
    [self.imageView.layer setBorderWidth:1.0];
    [self.imageView.layer setCornerRadius:2.5];

    self.titleTextLabel.textColor = NSColor.textColor;
    self.detailTextLabel.textColor = NSColor.textColor;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setFrame:(NSRect)frameRect {
    // i wasn't able to figure out where the 10px inset was coming
    // from in the cells. I'm fixing it here but it's a bit of a hack. (scott)
    frameRect.size.width += 10;
    [super setFrame:frameRect];

}

- (void)updateSubtitle {

    if ([self.detailTextLabel.stringValue isEqualToString:[_album imageSubtitle]] == NO) {
        //DLog(@"Update subtitle for view with album : %@", self.album.title);

        NSString *subtitle = [self.album subtitle];
        if (subtitle) {
            [self.detailTextLabel setStringValue:subtitle];
        } else {
            [self.detailTextLabel setStringValue:@""];
        }
        [self setNeedsDisplay:YES];
    }
}

- (void)updateAlbumView:(NSNotification *)note {
    //if (note.object == self.album) {

    if ([self.album.stackPhotos count] > 0) {
        PIXPhoto *thumbPhoto = [self.album.stackPhotos objectAtIndex:0];
        //thumbPhoto.stackPhotoAlbum = self.album;

        NSImage *thumb = [thumbPhoto thumbnailImage];
        [self.imageView setImage:thumb];
    } else {
        self.imageView.image = nil;
    }


    if (self.imageView.image == nil) {
        [self.imageView setImage:[NSImage imageNamed:@"nophoto"]];
    }

    self.titleTextLabel.stringValue = self.album.title;
    [self updateSubtitle];
    [self setNeedsDisplay:YES];
    /*} else {
        DLog(@"Received a notification for incorrect album : %@", note.object);
    }*/
}


- (void)setAlbum:(PIXAlbum *)newAlbum {
    if (newAlbum != _album) {
        if (_album != nil) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AlbumStackDidChangeNotification object:_album];
        }
        _album = newAlbum;
        if (_album != nil) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAlbumView:) name:AlbumStackDidChangeNotification object:_album];
            [self updateAlbumView:nil];
        }
    }

}

- (IBAction) deleteItems:(id)inSender {
    // if we have nothing to delete then do nothing
    if (!self.album) return;

    NSSet *itemsToDelete = [NSSet setWithObject:self.album];

    [[PIXFileManager sharedInstance] deleteItemsWorkflow:itemsToDelete];
}


- (IBAction) revealInFinder:(id)inSender {
    PIXAlbum *anAlbum = self.album;
    NSSet *aSet = [NSSet setWithObject:anAlbum];
    [aSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {

        NSString *path = [obj path];
        NSString *folder = [path stringByDeletingLastPathComponent];
        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:folder];

    }];
}

- (IBAction)getInfo:(id)sender {
    PIXAlbum *anAlbum = self.album;
    NSSet *aSet = [NSSet setWithObject:anAlbum];
    [aSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {

        NSPasteboard *pboard = [NSPasteboard pasteboardWithUniqueName];
        [pboard declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
        [pboard setString:[obj path] forType:NSPasteboardTypeString];
        NSPerformService(@"Finder/Show Info", pboard);

    }];

}

// use this to switch text color when highligthed
- (void)setBackgroundStyle:(NSBackgroundStyle)style {

    [super setBackgroundStyle:style];

    // If the cell's text color is black, this sets it to white
    [((NSCell *) self.detailTextLabel.cell) setBackgroundStyle:style];
    [((NSCell *) self.titleTextLabel.cell) setBackgroundStyle:style];

    NSShadow *textShadow = [[NSShadow alloc] init];
    [textShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1]];
    [textShadow setShadowOffset:NSMakeSize(0, 1)];
    [textShadow setShadowBlurRadius:1.0];

    // Otherwise you need to change the color manually
    if (@available(macOS 10.14, *)) {
        self.titleTextLabel.textColor = NSColor.textColor;
        self.detailTextLabel.textColor = NSColor.textColor;
    } else {
        switch (style) {
            case NSBackgroundStyleLight:
                [self.titleTextLabel setTextColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
                [self.detailTextLabel setTextColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
                break;

            case NSBackgroundStyleDark:
            default:
                [self.titleTextLabel setTextColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
                [self.detailTextLabel setTextColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
                break;
        }
    }
}

//// Only called if the 'selected' property is yes.
//- (void)drawSelectionInRect:(NSRect)dirtyRect {
//    // Check the selectionHighlightStyle, in case it was set to None
//    if (self.hasContextMenuOpen) {
//        // We want a hard-crisp stroke, and stroking 1 pixel will border half on one side and half on another, so we offset by the 0.5 to handle this
//        NSRect selectionRect = NSInsetRect(self.bounds, 5.5, 5.5);
//        [[NSColor colorWithCalibratedWhite:.72 alpha:1.0] setStroke];
//        [[NSColor colorWithCalibratedWhite:.82 alpha:1.0] setFill];
//        NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:10 yRadius:10];
//        [selectionPath fill];
//        [selectionPath stroke];
//    }
//}
//
//- (void)drawBackgroundInRect:(NSRect)dirtyRect {
//    // Custom background drawing. We don't call super at all.
//    [self.backgroundColor set];
//    // Fill with the background color first
//    NSRectFill(self.bounds);
//    
//    // Draw a white/alpha gradient
//    if (self.hasContextMenuOpen) {
//        NSGradient *gradient = gradientWithTargetColor([NSColor whiteColor]);
//        [gradient drawInRect:self.bounds angle:0];
//    }
//}

- (void)menuWillOpen:(NSMenu *)menu {
    self.hasContextMenuOpen = YES;
    CGColorRef color = CGColorCreateGenericRGB(0.346, 0.531, 0.792, 1.000);
    //NSColor *color = [NSColor itemSelectionRingColor];
    //[self.layer setBackgroundColor:color];
    [self.layer setBorderWidth:2.0f];
    [self.layer setBorderColor:color];
    [self.layer setCornerRadius:4];

    CGColorRelease(color);

//    [super drawFocusRingMask];
//    //self.backgroundStyle =
//    [self.detailTextLabel setStringValue:@"Context menu..."];
//    self.backgroundStyle = NSBackgroundStyleRaised;
    [self setNeedsDisplay:YES];
}

- (void)menuDidClose:(NSMenu *)menu {
    self.hasContextMenuOpen = NO;
    [self.layer setBorderWidth:0.0f];
    //[self.layer setBorderColor:color];
}

- (void)rightMouseDown:(NSEvent *)theEvent {
    [super rightMouseDown:theEvent];
    DLog(@"rightMouseDown : %@", theEvent);
}

//- (void)drawDraggingDestinationFeedbackInRect:(NSRect)dirtyRect;
//{
//    //[super drawDraggingDestinationFeedbackInRect:dirtyRect];
//    //[super drawFocusRingMask];
//}

- (NSArray *)draggingImageComponents {
    NSDraggingImageComponent *imageComponent = [[NSDraggingImageComponent alloc] initWithKey:NSDraggingImageComponentIconKey];

    NSImage *dragImage = [PIXAlbumCollectionViewItemView dragImageForAlbums:@[self.album] size:NSMakeSize(180, 180)];
    [imageComponent setContents:dragImage];
    [imageComponent setFrame:NSMakeRect(0, 0, 180, 180)];

    return @[imageComponent];
}


@end
