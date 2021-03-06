//
//  PIXImageViewController.m
//  UnboundApp
//
//  Created by Bob on 12/16/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXImageViewController.h"
#import "AutoSizingImageView.h"
#import "PIXPhoto.h"
#import "PIXDefines.h"

@interface PIXImageViewController ()

@property CGFloat startPinchZoom;
@property NSPoint startPinchPosition;

@end

@implementation PIXImageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)awakeFromNib
{
    //self.imageView.delegate = self;
}

-(void)dealloc
{
    //self.imageView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)setRepresentedObject:(id)representedObject
{
//    if (representedObject==nil) {
//        //[super setRepresentedObject:representedObject];
//    }
    [self setPhoto:(PIXPhoto *)representedObject];
}

-(void)photoFullsizeChanged:(NSNotification *)notification
{
    //DLog(@"photoFullsizeChanged: %@", notification);
    NSCAssert(notification.object == self.representedObject, @"Notification received for wrong photo");
    //PIXPhoto *aPhoto = (PIXPhoto *)notification.object;
    id obj = notification.object;
    //DLog(@"obj class : %@", [obj class]);
    PIXPhoto *aPhoto = (PIXPhoto *)obj;
    NSCParameterAssert(aPhoto.fullsizeImage);
    self.imageView.image = aPhoto.fullsizeImage;
    [self.imageView setNeedsDisplay:YES];
}

-(void)setPhoto:(PIXPhoto *)newPhoto
{
    if (self.representedObject != newPhoto)
    {
        if (self.representedObject!=nil)
        {
            //[[NSNotificationCenter defaultCenter] removeObserver:self name:PhotoThumbDidChangeNotification object:self.representedObject];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:PhotoFullsizeDidChangeNotification object:self.representedObject];
//            if (newPhoto!=nil) {
//                [self.representedObject cancelFullsizeLoading];
//            }
        }
        
        [super setRepresentedObject:newPhoto];
    
        if (self.representedObject!=nil) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoFullsizeChanged:) name:PhotoFullsizeDidChangeNotification object:self.representedObject];
            
            //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoChanged:) name:PhotoThumbDidChangeNotification object:self.representedObject];
            self.imageView.image = [newPhoto fullsizeImageForFullscreenDisplay];
			self.imageView.needsDisplay = YES;
            NSCParameterAssert(self.imageView.image);
            
        }
    
    } else if (newPhoto!=nil) {
        //DLog(@"same non-nil representedObject being set.");
    }
}


-(void)setIsCurrentView:(BOOL)value
{
    if(_isCurrentView != value)
    {
        _isCurrentView = value;
    }
}

-(void)leapPanZoomStart
{
    if(![self.view.window isKeyWindow]) return;
    
    self.startPinchZoom = [self.scrollView magnification];
    
    CGRect bounds = [[self.scrollView contentView] bounds];
    
    self.startPinchPosition= CGPointMake(bounds.origin.x + (bounds.size.width / 2),
                                         bounds.origin.y + (bounds.size.height / 2));
}

-(void)leapPanZoomPosition:(NSPoint)position andScale:(CGFloat)scale
{
    if(![self.view.window isKeyWindow]) return;
    
    
    CGFloat magnification = self.startPinchZoom * scale;
    
    
    if(!isnan(magnification))
    {
        [self.scrollView setMagnification:magnification];
    }
    
    // tweak the position depen
    position.x *= 1.0 + (([self.scrollView magnification]-1.0) / 3.0);
    position.y *= 1.0 + (([self.scrollView magnification]-1.0) / 3.0);
    
    CGRect bounds = [[self.scrollView contentView] bounds];
    
    NSPoint scaledPosition = NSMakePoint(position.x * [[self.scrollView contentView] bounds].size.width,
                                         position.y * [[self.scrollView contentView] bounds].size.height);
    
    
    NSPoint newScrollPosition =  NSMakePoint(self.startPinchPosition.x - (bounds.size.width / 2) - scaledPosition.x,
                                             self.startPinchPosition.y - (bounds.size.height / 2) - scaledPosition.y);
    
    
    if(!isnan(newScrollPosition.x) && !isnan(newScrollPosition.y))
    {
        [[self.scrollView documentView] scrollPoint:newScrollPosition];
    }
    
    [self.scrollView setNeedsDisplay:YES];
}

@end
