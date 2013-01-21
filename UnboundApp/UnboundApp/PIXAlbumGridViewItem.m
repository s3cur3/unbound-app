//
//  PIXAlbumGridViewItem.m
//  UnboundApp
//
//  Created by Scott Sykora on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXAlbumGridViewItem.h"
#import "CNGridViewItem.h"
#import "PIXAlbum.h"
#import "PIXBorderedImageView.h"
#import <QuartzCore/QuartzCore.h>
#import "PIXDefines.h"

@implementation PIXAlbumGridViewItem



-(void)setAlbum:(PIXAlbum *)album
{
    NSAssert(album!=nil, @"Unexpected setting of album to nil in PIXAlbuGridViewItem.");

    // only set it if it's different
    if(_album != album)
    {
        [self layout];
        
        if (album!=nil)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AlbumDidChangeNotification object:_album];
        }

        _album = album;
        
        [self setItemTitle:[_album title]];
        
        NSImage * albumThumb = [_album thumbnailImage];
        
        [self.albumImageView setImage:albumThumb];
        
        [self.albumImageView setNeedsDisplay:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumChanged:) name:AlbumDidChangeNotification object:_album];
                                                                                                    
    }
}

-(void)albumChanged:(NSNotification *)note
{
    [self setItemTitle:[self.album title]];
    [self.albumImageView setImage:[self.album thumbnailImage]];
    
    [self setNeedsDisplay:YES];
}

-(BOOL)isOpaque
{
    return YES;
}

-(void)layout
{
    
    CGRect albumFrame = CGRectInset(self.bounds, 15, 25);
    albumFrame.origin.y -= 10;
    
    // only layout if the bounds have changed
    if(!CGRectEqualToRect(albumFrame, self.albumImageView.frame) && albumFrame.size.width > 0)
    {
    
        
        
        //[self addSubview:self.stackPhoto1];
        [self.stackPhoto1 setFrame:albumFrame];
        //[self addSubview:self.stackPhoto2];
        [self.stackPhoto2 setFrame:albumFrame];
        //[self addSubview:self.stackPhoto3];
        [self.stackPhoto3 setFrame:albumFrame];
        
        [self.stackPhoto1.layer setZPosition:2];
        [self.stackPhoto2.layer setZPosition:1];
        [self.stackPhoto3.layer setZPosition:0];
        
        
        
        self.stackPhoto1.image = [NSImage imageNamed:@"temp"];
        self.stackPhoto2.image = [NSImage imageNamed:@"temp-portrait"];
        self.stackPhoto3.image = [NSImage imageNamed:@"temp"];
        
        //[self.stackPhoto1 setFrameCenterRotation:3.0];
        //[self.stackPhoto2 setFrameCenterRotation:4.0];
        //[self.stackPhoto3 setFrameCenterRotation:-2.0];
        
        
        [self.albumImageView setFrame:albumFrame];
        
        NSImage * albumThumb = [_album thumbnailImage];
        [self.albumImageView setImage:albumThumb];
        
        [self addSubview:self.albumImageView];
        
        [self.albumImageView setNeedsDisplay:YES];
        
        
        
        [self.albumImageView.layer setZPosition:3];
        
        
    }
    
    //[self setWantsLayer:YES];
    //[self.layer setShouldRasterize:YES];

    [super layout];
}

- (void)drawRect:(NSRect)rect
{
    NSRect bounds = self.bounds;
    
    
    NSBezierPath *contentRectPath = [NSBezierPath bezierPathWithRect:rect];
    [[NSColor colorWithCalibratedWhite:0.912 alpha:1.000] setFill];
    [contentRectPath fill];
    
    /// draw selection ring
    if (self.selected) {
        
        NSRect innerbounds = CGRectInset(self.bounds, 6, 6);
        NSBezierPath *selectionRectPath = [NSBezierPath bezierPathWithRoundedRect:innerbounds xRadius:10 yRadius:10];
        [[NSColor colorWithCalibratedRed:0.189 green:0.657 blue:0.859 alpha:1.000] setStroke];
        [selectionRectPath setLineWidth:4];
        [selectionRectPath stroke];
    }
    
    
    NSRect srcRect = NSZeroRect;
    srcRect.size = self.itemImage.size;
    
    NSRect textRect = NSMakeRect(bounds.origin.x + 3,
                          NSHeight(bounds) - 30,
                          NSWidth(bounds) - 6,
                          20);
    
    NSColor *textColor      = [NSColor colorWithCalibratedWhite:0.0 alpha:0.7];
    NSShadow *textShadow    = [[NSShadow alloc] init];
    [textShadow setShadowColor: [NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
    [textShadow setShadowOffset: NSMakeSize(0, -1)];
    
    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    [textStyle setAlignment: NSCenterTextAlignment];
    
    NSDictionary * attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont fontWithName:@"Helvetica Bold" size:14], NSFontAttributeName,
     //                           textShadow,                                 NSShadowAttributeName,
                                textColor,                                  NSForegroundColorAttributeName,
                                textStyle,                                  NSParagraphStyleAttributeName,
                                nil];
    

    
    [self.itemTitle drawInRect:textRect withAttributes:attributes];

}


- (void)prepareForReuse
{
    [super prepareForReuse];
    
    if (self.album )  {
        [self.album cancelThumbnailLoading];
        
//        [[NSNotificationCenter defaultCenter] removeObserver:self name:AlbumDidChangeNotification object:self.album];
//        self.album = nil; 
    }
    
    
    
    
//    self.itemImage = nil;
//    self.itemTitle = @"";
//    self.index = CNItemIndexUndefined;
//    self.selected = NO;
//    self.selectable = YES;
//    self.hovered = NO;
}

-(PIXBorderedImageView *)albumImageView
{
    if(_albumImageView) return _albumImageView;
    
    _albumImageView = [[PIXBorderedImageView alloc] initWithFrame:NSZeroRect];
    [self addSubview:_albumImageView];
    
    return _albumImageView;
}

-(PIXBorderedImageView *)stackPhoto1
{
    if(_stackPhoto1) return _stackPhoto1;
    
    _stackPhoto1 = [[PIXBorderedImageView alloc] initWithFrame:NSZeroRect];
    [self addSubview:_stackPhoto1];
     
    return _stackPhoto1;
}

-(PIXBorderedImageView *)stackPhoto2
{
    if(_stackPhoto2) return _stackPhoto2;
    
    _stackPhoto2 = [[PIXBorderedImageView alloc] initWithFrame:NSZeroRect];
    [self addSubview:_stackPhoto2];
    
    return _stackPhoto2;
}

-(PIXBorderedImageView *)stackPhoto3
{
    if(_stackPhoto3) return _stackPhoto3;
    
    _stackPhoto3 = [[PIXBorderedImageView alloc] initWithFrame:NSZeroRect];
    [self addSubview:_stackPhoto3];
    
    return _stackPhoto3;
}


@end
