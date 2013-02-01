//
//  PIXAlbumGridViewItem.m
//  UnboundApp
//
//  Created by Scott Sykora on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXAlbumGridViewItem.h"
#import "PIXAlbum.h"
#import "PIXBorderedImageView.h"
#import <QuartzCore/QuartzCore.h>
#import "PIXDefines.h"
#include <stdlib.h>

@interface PIXAlbumGridViewItem()

@property (strong, nonatomic) IBOutlet NSTextField *mainLabel;
@property (strong, nonatomic) IBOutlet NSTextField * detailLabel;

@property (strong, nonatomic) NSImage * albumThumb;

@property (strong, nonatomic) NSImage * stackThumb1;
@property (strong, nonatomic) NSImage * stackThumb2;
@property (strong, nonatomic) NSImage * stackThumb3;

@property CGFloat stackThumb1Rotate;
@property CGFloat stackThumb2Rotate;

@end

@implementation PIXAlbumGridViewItem

- (id)init
{
    self = [super init];
    if (self) {
        
        self.stackThumb1 = [NSImage imageNamed:@"temp"];
        self.stackThumb2 = [NSImage imageNamed:@"temp-portrait"];
        
        // randomly rotate the first between -.05 and .05
        self.stackThumb1Rotate = (CGFloat)(arc4random() % 1000)/10000 - .05;
        
        // the second needs to be the difference so that we rotate the object back
        self.stackThumb2Rotate = (CGFloat)(arc4random() % 1000)/10000 - .05 - self.stackThumb1Rotate;
    }
    return self;
}

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
        
        
        self.albumThumb = [_album thumbnailImage];
        
        if(self.albumThumb == nil)
        {
            self.albumThumb = [NSImage imageNamed:@"temp"];
        }

        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumChanged:) name:AlbumDidChangeNotification object:_album];
                                                                                                    
    }
}

-(void)albumChanged:(NSNotification *)note
{
    [self setItemTitle:[self.album title]];
    //[self.albumImageView setImage:[self.album thumbnailImage]];
    self.albumThumb = [_album thumbnailImage];
    
    [self setNeedsDisplay:YES];
}

-(BOOL)isOpaque
{
    return YES;
}


- (void)drawRect:(NSRect)rect
{
    NSRect bounds = self.bounds;
    
    
    
    
    NSBezierPath *contentRectPath = [NSBezierPath bezierPathWithRect:rect];
    
    NSColor * textColor = nil;
    NSColor * subtitleColor = nil;
    NSColor * bgColor = nil;
    
    if([[NSUserDefaults standardUserDefaults] integerForKey:@"backgroundTheme"] == 0)
    {
        bgColor = [NSColor colorWithCalibratedWhite:0.912 alpha:1.000];
        textColor = [NSColor colorWithCalibratedWhite:0.10 alpha:1.0];
        subtitleColor = [NSColor colorWithCalibratedWhite:0.35 alpha:1.0];
    }
    
    else
    {
        bgColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"dark_bg"]];
        textColor = [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
        subtitleColor = [NSColor colorWithCalibratedWhite:0.55 alpha:1.0];
    }
    
    [bgColor setFill];
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
                          NSHeight(bounds) - 50,
                          NSWidth(bounds) - 6,
                          20);
    
    NSRect subTitleRect = NSMakeRect(bounds.origin.x + 3,
                                 NSHeight(bounds) - 28,
                                 NSWidth(bounds) - 6,
                                 20);
    
    NSShadow *textShadow    = [[NSShadow alloc] init];
    [textShadow setShadowColor: [NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
    [textShadow setShadowOffset: NSMakeSize(0, -1)];
    
    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    [textStyle setAlignment: NSCenterTextAlignment];
    
    NSDictionary * attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont fontWithName:@"Helvetica Neue Bold" size:14], NSFontAttributeName,
     //                           textShadow,                                 NSShadowAttributeName,
     //                           bgColor,                                    NSBackgroundColorAttributeName,
                                textColor,                                  NSForegroundColorAttributeName,
                                textStyle,                                  NSParagraphStyleAttributeName,
                                nil];
    

    
    [self.itemTitle drawInRect:textRect withAttributes:attributes];
    
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                  [NSFont fontWithName:@"Helvetica Neue" size:11], NSFontAttributeName,
                  //                           textShadow,                                 NSShadowAttributeName,
                  //                           bgColor,                                    NSBackgroundColorAttributeName,
                  subtitleColor,                                  NSForegroundColorAttributeName,
                  textStyle,                                  NSParagraphStyleAttributeName,
                  nil];
    
    NSString * itemSubtitle = self.album.imageSubtitle;
    
    [itemSubtitle drawInRect:subTitleRect withAttributes:attributes];
    
    
    CGRect albumFrame = CGRectInset(self.bounds, 15, 35);
    albumFrame.origin.y -= 20;
    
    // draw the stack of imagess
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSaveGState(context);
    
    CGContextTranslateCTM(context, self.bounds.size.width/2, self.bounds.size.height/2);
    CGContextRotateCTM(context, self.stackThumb1Rotate);
    CGContextTranslateCTM(context, -self.bounds.size.width/2, -self.bounds.size.height/2);
    
    [self drawBorderedPhoto:self.stackThumb1 inRect:albumFrame];
    
    CGContextTranslateCTM(context, self.bounds.size.width/2, self.bounds.size.height/2);
    CGContextRotateCTM(context, self.stackThumb2Rotate);
    CGContextTranslateCTM(context, -self.bounds.size.width/2, -self.bounds.size.height/2);
    
    [self drawBorderedPhoto:self.stackThumb2 inRect:albumFrame];
    
    CGContextRestoreGState(context);
    
    
    // draw the top image
    [self drawBorderedPhoto:self.albumThumb inRect:albumFrame];
    
    self.contentFrame = albumFrame;

}


- (void)prepareForReuse
{
    [super prepareForReuse];
    
    if (self.album )  {
        [self.album cancelThumbnailLoading];
        
        //[[NSNotificationCenter defaultCenter] removeObserver:self name:AlbumDidChangeNotification object:self.album];
        //self.album = nil;
    }
    
    self.stackThumb1 = [NSImage imageNamed:@"temp"];
    self.stackThumb2 = [NSImage imageNamed:@"temp-portrait"];
    self.stackThumb3 = [NSImage imageNamed:@"temp"];

}

/*
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
}*/


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
