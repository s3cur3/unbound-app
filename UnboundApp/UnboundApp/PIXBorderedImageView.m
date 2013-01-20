//
//  BorderedImageView.m
//  Unbound
//
//  Created by Scott Sykora on 11/18/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXBorderedImageView.h"
 #import <QuartzCore/QuartzCore.h>

@interface PIXBorderedImageView ()
{
    
}

@property (strong, nonatomic) CALayer * borderLayer;
@property (strong, nonatomic) CALayer * shadowLayer;
@property CGRect imageFrame;
@end

@implementation PIXBorderedImageView

/*
-(BOOL)wantsDefaultClipping
{
    return NO;
}*/

- (id)init
{
    self = [super init];
    if (self) {
        [self initialSetup];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self initialSetup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initialSetup];
    }
    return self;
}

-(void)initialSetup
{
    //self.layer = [CALayer layer];
    //[self setWantsLayer:YES];
}

-(BOOL)isOpaque
{
    return NO;
}

/*
-(void)setObjectValue:(id<NSCopying>)obj
{
    [super setObjectValue:obj];
    
    if(self.image == nil)
    {
        self.image = [NSImage imageNamed:@"temp-portrait"];
        return;
    }
    
    //[self setupBorder];
        
}*/

-(void)setImage:(NSImage *)newImage
{
    
    if(newImage == self.image) return;
    
    
    // calculate the proportional image frame
    CGSize imageSize = [newImage size];
    
    CGRect anImageFrame = CGRectMake(0, 0, imageSize.width, imageSize.height);
    
    if(imageSize.width > 0 && imageSize.height > 0)
    {
        if(imageSize.width / imageSize.height > self.bounds.size.width / self.bounds.size.height)
        {
            float mulitplier = self.bounds.size.width / imageSize.width;
            
            anImageFrame.size.width = mulitplier * anImageFrame.size.width;
            anImageFrame.size.height = mulitplier * anImageFrame.size.height;
            
            anImageFrame.origin.y = (self.bounds.size.height - anImageFrame.size.height)/2;
        }
        
        else
        {
            float mulitplier = self.bounds.size.height / imageSize.height;
            
            anImageFrame.size.width = mulitplier * anImageFrame.size.width;
            anImageFrame.size.height = mulitplier * anImageFrame.size.height;
            
            anImageFrame.origin.x = (self.bounds.size.width - anImageFrame.size.width)/2;
        }
    }
    
    self.imageFrame = anImageFrame;
    
    _image = newImage;
    
    //[super setImage:newImage];
    [self setNeedsDisplay:YES];
   
    //[self setupBorder];
}

-(void)setupBorder
{
    // make this a layer hosting view, not a layer backed view
    //self.layer = [CALayer layer];
    //[self setWantsLayer:YES];
    
    // calculate the proportional image frame
    CGSize imageSize = [self.image size];
    
    CGRect imageFrame = CGRectMake(0, 0, imageSize.width, imageSize.height);
    
    if(imageSize.width > 0 && imageSize.height > 0)
    {
        if(imageSize.width / imageSize.height > self.bounds.size.width / self.bounds.size.height)
        {
            float mulitplier = self.bounds.size.width / imageSize.width;
            
            imageFrame.size.width = mulitplier * imageFrame.size.width;
            imageFrame.size.height = mulitplier * imageFrame.size.height;
            
            imageFrame.origin.y = (self.bounds.size.height - imageFrame.size.height)/2;
        }
        
        else
        {
            float mulitplier = self.bounds.size.height / imageSize.height;
            
            imageFrame.size.width = mulitplier * imageFrame.size.width;
            imageFrame.size.height = mulitplier * imageFrame.size.height;
            
            imageFrame.origin.x = (self.bounds.size.width - imageFrame.size.width)/2;
        }
    }
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    
    imageFrame = CGRectInset(imageFrame, -2, -2);
    
    // do your sublayer rearrangement here
    [self.borderLayer setFrame:imageFrame];
    [self.shadowLayer setFrame:imageFrame];
    _shadowLayer.contents = self.image;
    
    [CATransaction commit];
    
    //[self.layer setShouldRasterize:YES];
    

}

-(void)setSelected:(BOOL)selected
{
    _selected = selected;
    
    if(_selected)
    {
        self.borderLayer.borderColor = CGColorCreateGenericRGB(0.189, 0.657, 0.859, 1.000);
        self.borderLayer.cornerRadius = 4.0;
        self.shadowLayer.cornerRadius = 4.0;
    }
    
    else
    {
        self.borderLayer.borderColor = [[NSColor whiteColor] CGColor];
        self.borderLayer.cornerRadius = 0;
        self.shadowLayer.cornerRadius = 0;
    }
}


-(CALayer *)borderLayer
{
    if(_borderLayer != nil) return _borderLayer;
    
    _borderLayer = [CALayer layer];
    
    _borderLayer.borderColor = [[NSColor whiteColor] CGColor];
    _borderLayer.borderWidth = 6;
    _borderLayer.zPosition = 1;
    
    //[self setWantsLayer:YES];
    [self.layer addSublayer:_borderLayer];
    
    return _borderLayer;
}


-(void)drawRect:(NSRect)dirtyRect
{
    
    //[super drawRect:dirtyRect];
    
    
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetShadowWithColor(context, CGSizeZero, 4.0, [[NSColor colorWithGenericGamma22White:0.0 alpha:.5] CGColor]);
    
   
    
    CGRect borderRect = CGRectInset(self.imageFrame, 4, 4);
    
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:borderRect]; // will give a 2 pixel wide border
    CGContextSetShadowWithColor(context, CGSizeZero, 4.0, NULL);
    
    CGRect imageRect = CGRectInset(self.imageFrame, 10, 10);
    [self.image drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
     
    
    /*
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSetLineWidth(context, 6.0);
    
    CGContextSetStrokeColorWithColor(context, [NSColor whiteColor].CGColor);
    
    
    CGContextAddRect(context, self.imageFrame);
    
    CGContextStrokePath(context);
    */
    

}


-(CALayer *)shadowLayer
{
    if(_shadowLayer != nil) return _shadowLayer;
    
    _shadowLayer = [CALayer layer];
    
    
    CGColorRef color = CGColorCreateGenericGray(1.0, 1.0);
    [_shadowLayer setBackgroundColor:color];
    [_shadowLayer setShadowOpacity:0.5];
    CFRelease(color);
    
    /*
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, _shadowLayer.bounds);
    
    [photoBackgroundLayer setShadowPath:path];
    CGPathRelease(path);*/
    
    _shadowLayer.zPosition = 0;
    
    //[self setWantsLayer:YES];
    [self.layer addSublayer:_shadowLayer];
    
    return _shadowLayer;
}


@end
