//
//  PIXPhotoCollectionViewItem.m
//  UnboundApp
//
//  Created by Ditriol Wei on 14/9/16.
//  Copyright © 2016 Pixite Apps LLC. All rights reserved.
//

#import "PIXPhotoCollectionViewItem.h"
#import "PIXPhoto.h"
#import "PIXDefines.h"
#import "PIXSelectionLayer.h"

@interface PIXPhotoCollectionViewItem ()

@end

@implementation PIXPhotoCollectionViewItem

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
}

- (void)setRepresentedObject:(id)obj
{
    PIXPhotoCollectionViewItemView * view = (PIXPhotoCollectionViewItemView *)self.view;
    view.photo = obj;
}

- (id)representedObject
{
    PIXPhotoCollectionViewItemView * view = (PIXPhotoCollectionViewItemView *)self.view;
    return view.photo;
}

- (void)setSelected:(BOOL)s
{
    NSLog(@"Selected: %d", s);
    PIXPhotoCollectionViewItemView * view = (PIXPhotoCollectionViewItemView *)self.view;
    view.selected = s;
    if( view.photo != nil )
        [view setNeedsDisplay:YES];
}

- (BOOL)isSelected
{
    PIXPhotoCollectionViewItemView * view = (PIXPhotoCollectionViewItemView *)self.view;
    return view.selected;
}

- (void)refresh
{
    [self.view updateLayer];
}

@end


@interface PIXPhotoCollectionViewItemView ()
@property CALayer * imageLayer;
@property (nonatomic, strong) CALayer * selectionLayer;
@property (nonatomic, strong) NSImageView * videoLayover;
@property BOOL isVideo;
@end

@implementation PIXPhotoCollectionViewItemView
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if( self != nil )
    {
        [self setup];
    }
    
    return self;
}

- (id)representedObject {
    return self.photo;
}

- (void)setup
{
    self.layer = [CALayer layer];
    self.imageLayer = [CALayer layer];
    
    self.imageLayer.borderColor = [[NSColor whiteColor] CGColor];
    self.imageLayer.shadowColor = [[NSColor colorWithGenericGamma22White:0.0 alpha:1.0] CGColor];
    self.imageLayer.shadowOffset = CGSizeMake(0, 1);
    self.imageLayer.shadowRadius = 3.0;
    self.imageLayer.shadowOpacity = 0.4;
    self.imageLayer.borderWidth = 3.0;
    
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


+ (NSImage *)dragImageForPhotos:(NSArray *)photoArray size:(NSSize)size
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
        // save this as a local property for performance reasons
        self.isVideo = [newPhoto isVideo];
        
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
        if(self.isVideo)
        {
            // no camera icon on videos
            self.itemImage = [NSImage imageNamed:@"tempVideo"];
        }
        
        else
        {
            self.itemImage = [NSImage imageNamed:@"temp"];
        }
    }
    
    
    
    //[self setNeedsDisplay:YES];
    [self updateLayer];
}

-(BOOL)wantsUpdateLayer
{
    return YES;
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
    if(CGRectEqualToRect(self.frame, frameRect)) return;

    [super setFrame:frameRect];
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
    
    if(value) {
        [self.layer addSublayer:self.selectionLayer];
    } else {
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
    
    //[CATransaction begin];
    //[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    if(self.isVideo) // use local property for performance reasons (set when photo is set)
    {
        [self.layer addSublayer:self.videoLayover.layer];
    }
    
    else
    {
        [_videoLayover.layer removeFromSuperlayer];
        self.videoLayover = nil;
    }
    
    
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
    
    
    
    self.imageLayer.frame = imageFrame;

    CGRect videoThumbFrame = CGRectMake(0, 0, 80, 80);
    
    if(imageFrame.size.width > 0 && imageFrame.size.height >  0)
    {
        if(imageFrame.size.width / imageFrame.size.height > rect.size.width / rect.size.height)
        {
            float mulitplier = rect.size.width / 200.0;
            
            videoThumbFrame.size.width = rint(mulitplier * videoThumbFrame.size.width);
            videoThumbFrame.size.height = rint(mulitplier * videoThumbFrame.size.height);
            
            videoThumbFrame.origin.y = rint((rect.size.height - videoThumbFrame.size.height)/2 + rect.origin.y);
            videoThumbFrame.origin.x = rint((rect.size.width - videoThumbFrame.size.width)/2 + rect.origin.x);
        }
        
        else
        {
            float mulitplier = rect.size.height / 200.0;
            
            videoThumbFrame.size.width = rint(mulitplier * videoThumbFrame.size.width);
            videoThumbFrame.size.height = rint(mulitplier * videoThumbFrame.size.height);
            
            videoThumbFrame.origin.y = rint((rect.size.height - videoThumbFrame.size.height)/2 + rect.origin.y);
            videoThumbFrame.origin.x = rint((rect.size.width - videoThumbFrame.size.width)/2 + rect.origin.x);
        }
    }
    
    [_videoLayover setFrame:videoThumbFrame];
    
    
    //CGMutablePathRef path = CGPathCreateMutable();
    //CGPathAddRect(path, NULL, self.imageLayer.bounds);
    
    CGPathRef path = CGPathCreateWithRect(self.imageLayer.bounds, NULL);
    
    self.imageLayer.shadowPath = path;
    
    CGPathRelease(path);
    
    [self.imageLayer setContents:self.itemImage];

    self.contentFrame = imageFrame;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end