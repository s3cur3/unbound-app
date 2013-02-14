//
//  PIXPhotoGridViewItem.m
//  UnboundApp
//
//  Created by Scott Sykora on 1/30/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXPhotoGridViewItem.h"
#import "PIXPhoto.h"
#import "PIXDefines.h"

@implementation PIXPhotoGridViewItem

+(NSImage *)dragImageForPhotos:(NSArray *)photoArray size:(NSSize)size
{
    if([photoArray count] == 0) return [NSImage imageNamed:@"nophoto"];
        
    
    // set up the images
    NSImage * image1 = nil;
    NSImage * image2 = nil;
    NSImage * image3 = nil;
    
    NSMutableArray * imageArray = [NSMutableArray new];
    
    if([photoArray count])
    {
        image1 = [[photoArray objectAtIndex:0] thumbnailImage];
        
        if(image1 == nil)
        {
            image1 =[NSImage imageNamed:@"temp"];
        }
        
        [imageArray addObject:image1];
        
        if([photoArray count] > 1)
        {
            image2 = [[photoArray objectAtIndex:1] thumbnailImage];
            
            if(image2 == nil)
            {
                image2 =[NSImage imageNamed:@"temp-portrait"];
            }
            
            [imageArray addObject:image2];
            
            if([photoArray count] > 2)
            {
                image3 = [[photoArray objectAtIndex:2] thumbnailImage];
                
                if(image3 == nil)
                {
                    image3 =[NSImage imageNamed:@"temp"];
                }
                
                [imageArray addObject:image3];
            }
        }
        
        
    }
    
    
    
    
    
    NSString * title = @"1 Photo";
    
    // set up the title
    if([photoArray count] > 1)
    {
        title = [NSString stringWithFormat:@"%ld Photos", [photoArray count]];
    }
    
    return [self dragStackForImages:imageArray size:size title:title andBadgeCount:[photoArray count]];
}


-(BOOL)isOpaque
{
    return YES;
}

-(void)setPhoto:(PIXPhoto *)newPhoto
{
    if(_photo != newPhoto)
    {
        if (_photo!=nil)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:PhotoThumbDidChangeNotification object:_photo];
        }
        
        _photo = newPhoto;
        [self photoChanged:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoChanged:) name:PhotoThumbDidChangeNotification object:_photo];
    }
}


-(void)photoChanged:(NSNotification *)note
{
    self.itemImage = [self.photo thumbnailImage];
    
    if(self.itemImage == nil)
    {
        self.itemImage = [NSImage imageNamed:@"temp"];
    }
    
    [self setNeedsDisplay:YES];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    if (self.photo )  {
        [self.photo cancelThumbnailLoading];
        
        //[[NSNotificationCenter defaultCenter] removeObserver:self name:AlbumDidChangeNotification object:self.album];
        self.photo = nil;
    }
    
    
}

- (void)drawRect:(NSRect)rect
{
    
    NSBezierPath *contentRectPath = [NSBezierPath bezierPathWithRect:rect];
    
    
    if([[NSUserDefaults standardUserDefaults] integerForKey:@"backgroundTheme"] == 0)
    {
        [[NSColor colorWithCalibratedWhite:0.912 alpha:1.000] setFill];
    }
    
    else
    {
        NSColor * color = [NSColor colorWithPatternImage:[NSImage imageNamed:@"dark_bg"]];
        //[[self enclosingScrollView] setBackgroundColor:color];
        [color setFill];
    }
    
    
    [contentRectPath fill];
    
    /// draw selection ring
    if (self.selected) {
        
        NSRect innerbounds = CGRectInset(self.bounds, 6, 6);
        NSBezierPath *selectionRectPath = [NSBezierPath bezierPathWithRoundedRect:innerbounds xRadius:10 yRadius:10];
        [[NSColor colorWithCalibratedRed:0.189 green:0.657 blue:0.859 alpha:1.000] setStroke];
        [selectionRectPath setLineWidth:4];
        [selectionRectPath stroke];
    }
    
    
    
    
    CGRect albumFrame = CGRectInset(self.bounds, 15, 15);

    // draw the  image
    CGRect photoFrame = [[self class] drawBorderedPhoto:self.itemImage inRect:albumFrame];
    self.contentFrame = photoFrame;
    
}

@end
