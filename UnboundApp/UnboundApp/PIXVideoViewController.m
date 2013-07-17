//
//  PIXVideoViewController.m
//  UnboundApp
//
//  Created by Bob on 7/16/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXVideoViewController.h"
//#import "AutoSizingImageView.h"
#import "PIXPhoto.h"
#import "PIXDefines.h"

#import "PIXLeapInputManager.h"
#import <QTKit/QTKit.h>

@interface PIXVideoViewController ()

@property CGFloat startPinchZoom;
@property NSPoint startPinchPosition;

@end

@implementation PIXVideoViewController

// Add C implementations of missing methods that we’ll add
// to the StdMovieUISliderCell class later.
static NSSliderType SliderType(id self, SEL _cmd)
{
    return NSLinearSlider;
}

static NSInteger NumberOfTickMarks(id self, SEL _cmd)
{
    return 0;
}

// rot13, just to be extra safe.
static NSString *ResolveName(NSString *aName)
{
    const char *_string = [aName cStringUsingEncoding:NSASCIIStringEncoding];
    NSUInteger stringLength = [aName length];
    char newString[stringLength+1];
    
    NSUInteger x;
    for(x = 0; x < stringLength; x++)
    {
        unsigned int aCharacter = _string[x];
        
        if( 0x40 < aCharacter && aCharacter < 0x5B ) // A - Z
            newString[x] = (((aCharacter - 0x41) + 0x0D) % 0x1A) + 0x41;
        else if( 0x60 < aCharacter && aCharacter < 0x7B ) // a-z
            newString[x] = (((aCharacter - 0x61) + 0x0D) % 0x1A) + 0x61;
        else  // Not an alpha character
            newString[x] = aCharacter;
    }
    newString[x] = '\0';
    
    return [NSString stringWithCString:newString encoding:NSASCIIStringEncoding];
}

// Add both methods if they aren’t already there. This should makes this
// code safe, even if Apple decides to implement the methods later on.
+ (void)load
{
    Class MovieSliderCell = NSClassFromString(ResolveName(@"FgqZbivrHVFyvqrePryy"));
    
    if (!class_getInstanceMethod(MovieSliderCell, @selector(sliderType)))
    {
        const char *types = [[NSString stringWithFormat:@"%s%s%s",
                              @encode(NSSliderType), @encode(id), @encode(SEL)] UTF8String];
        class_addMethod(MovieSliderCell, @selector(sliderType),
                        (IMP)SliderType, types);
    }
    if (!class_getInstanceMethod(MovieSliderCell, @selector(numberOfTickMarks)))
    {
        const char *types = [[NSString stringWithFormat: @"%s%s%s",
                              @encode(NSInteger), @encode(id), @encode(SEL)] UTF8String];
        class_addMethod(MovieSliderCell, @selector(numberOfTickMarks),
                        (IMP)NumberOfTickMarks, types);
    }
}

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
    self.movieView.movie = [QTMovie movieWithFile:aPhoto.path error:nil];
//    NSCParameterAssert(aPhoto.fullsizeImage);
//    self.imageView.image = aPhoto.fullsizeImage;
//    [self.imageView setNeedsDisplay:YES];
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
            //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoChanged:) name:PhotoThumbDidChangeNotification object:self.representedObject];
            self.movieView.movie = [QTMovie movieWithFile:newPhoto.path error:nil];
            //[self.imageView setNeedsDisplay];
            //NSCParameterAssert(self.imageView.image);
            //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoFullsizeChanged:) name:PhotoFullsizeDidChangeNotification object:self.representedObject];
        }
        
    } else if (newPhoto!=nil) {
        DLog(@"same non-nil representedObject being set.");
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
    
    
    float magnification = self.startPinchZoom * scale;
    
    
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
