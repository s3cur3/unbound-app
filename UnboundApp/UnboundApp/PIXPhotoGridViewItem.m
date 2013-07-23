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

#import "PIXSelectionLayer.h"

#import <Quartz/Quartz.h>

@interface PIXPhotoGridViewItem ()

@property CALayer * imageLayer;
@property (nonatomic, strong) CALayer * selectionLayer;

@property (nonatomic, retain) NSImageView * videoLayover;


@end

@implementation PIXPhotoGridViewItem

@synthesize videoLayover = _videoLayover;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer = [CALayer layer];
        self.imageLayer = [CALayer layer];
        
        self.imageLayer.borderColor = [[NSColor whiteColor] CGColor];
        self.imageLayer.shadowColor = [[NSColor colorWithGenericGamma22White:0.0 alpha:1.0] CGColor];
        self.imageLayer.shadowOffset = CGSizeMake(0, 1);
        self.imageLayer.shadowRadius = 3.0;
        self.imageLayer.shadowOpacity = 0.4;
        
        // disable all animatsion on the image layer
        NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"onOrderIn",
                                           [NSNull null], @"onOrderOut",
                                           [NSNull null], @"sublayers",
                                           [NSNull null], @"contents",
                                           [NSNull null], @"bounds",
                                           nil];
        self.imageLayer.actions = newActions;
        self.layer.actions = newActions;
        
        
        
        [self.layer addSublayer:self.imageLayer];
        [self setWantsLayer:YES];
    }
    return self;
}

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
    return NO;
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

    [self updateLayer];
    if([self.photo isVideo])
    {
        [self.layer addSublayer:self.videoLayover.layer];
    }
    else
    {
        [_videoLayover.layer removeFromSuperlayer];
        self.videoLayover = nil;
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

-(void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    [_selectionLayer setFrame:self.bounds];

    if (_videoLayover!=nil) {
        //DLog(@"self.frame.origin.x: %f, self.frame.origin.y: %f, self.frame.size.height: %f, self.frame.size.width: %f", frameRect.origin.x, frameRect.origin.y, frameRect.size.height, frameRect.size.width);
        NSImage * photo = self.itemImage;
        CGRect rect = CGRectInset(self.bounds, 15, 15);
        
        // calculate the proportional image frame
        CGSize imageSize = [photo size];
        
        CGRect imageFrame = self.bounds;//CGRectMake(0, 0, 40, 40);
        
        if(imageSize.width > 0 && imageSize.height > 0)
        {
            if(imageSize.width / imageSize.height > rect.size.width / rect.size.height)
            {
                float mulitplier = rect.size.width / imageSize.width;
                
                imageFrame.size.width = rint(mulitplier * imageFrame.size.width);
                imageFrame.size.height = rint(mulitplier * imageFrame.size.height);
                
                imageFrame.origin.y = rint((rect.size.height - imageFrame.size.height)/2 + rect.origin.y);
                imageFrame.origin.x = rint((rect.size.width - imageFrame.size.width)/2 + rect.origin.x);
            }
            
            else
            {
                float mulitplier = rect.size.height / imageSize.height;
                
                imageFrame.size.width = rint(mulitplier * imageFrame.size.width);
                imageFrame.size.height = rint(mulitplier * imageFrame.size.height);
                
                imageFrame.origin.y = rint((rect.size.height - imageFrame.size.height)/2 + rect.origin.y);
                imageFrame.origin.x = rint((rect.size.width - imageFrame.size.width)/2 + rect.origin.x);
            }
        }
        [_videoLayover setFrame:imageFrame];
        //[_videoLayover setNeedsDisplay];
    }

    [self updateLayer];
}

-(NSImageView *)videoLayover
{
	if(_videoLayover != nil) return _videoLayover;
	
	_videoLayover = [[NSImageView alloc] init];
    _videoLayover.image = [NSImage imageNamed:@"playbutton"];
    [_videoLayover setAutoresizesSubviews:YES];
    [_videoLayover.image setScalesWhenResized:YES];
    [_videoLayover setImageScaling:NSImageScaleProportionallyDown];
    
    [_videoLayover setWantsLayer:YES];
    
	return _videoLayover;
	
}


-(void)setSelected:(BOOL)value
{
    [super setSelected:value];
    
    if(value)
    {
        [self.layer addSublayer:self.selectionLayer];
    }
    
    else
    {
        [_selectionLayer removeFromSuperlayer];
    }
    
    
}

-(CALayer *)selectionLayer
{
    if(_selectionLayer != nil) return _selectionLayer;
    
    _selectionLayer = [[PIXSelectionLayer alloc] init];
    
    [_selectionLayer setFrame:self.bounds];
    
    _selectionLayer.contentsScale = self.layer.contentsScale;

    
    return _selectionLayer;
}

-(void)updateLayer
{
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    
    NSImage * photo = self.itemImage;
    CGRect rect = CGRectInset(self.bounds, 15, 15);
    
    // calculate the proportional image frame
    CGSize imageSize = [photo size];
    
    CGRect imageFrame = CGRectMake(0, 0, imageSize.width, imageSize.height);
    
    if(imageSize.width > 0 && imageSize.height > 0)
    {
        if(imageSize.width / imageSize.height > rect.size.width / rect.size.height)
        {
            float mulitplier = rect.size.width / imageSize.width;
            
            imageFrame.size.width = rint(mulitplier * imageFrame.size.width);
            imageFrame.size.height = rint(mulitplier * imageFrame.size.height);
            
            imageFrame.origin.x = rint(rect.origin.x);
            imageFrame.origin.y = rint((rect.size.height - imageFrame.size.height)/2 + rect.origin.y);
        }
        
        else
        {
            float mulitplier = rect.size.height / imageSize.height;
            
            imageFrame.size.width = rint(mulitplier * imageFrame.size.width);
            imageFrame.size.height = rint(mulitplier * imageFrame.size.height);
            
            imageFrame.origin.y = rint(rect.origin.y);
            imageFrame.origin.x = rint((rect.size.width - imageFrame.size.width)/2 + rect.origin.x);
        }
    }
    
    
    CGFloat borderThickness = 6;
    
    if(rect.size.width < 120)
    {
        borderThickness = 4;
    }
    
    self.imageLayer.frame = imageFrame;
    
    //CGRect borderFrame = CGRectInset(imageFrame, -(borderThickness-1), -(borderThickness-1));
    
    
    self.imageLayer.borderWidth = borderThickness;
    
    
    
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.imageLayer.bounds);
    
    self.imageLayer.shadowPath = path;
    
    CGPathRelease(path);
    
    
    
    
    [self.imageLayer setContents:self.itemImage];
    
    [CATransaction commit];
    
    self.contentFrame = imageFrame;
}

/*
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
     
    
}*/

@end
