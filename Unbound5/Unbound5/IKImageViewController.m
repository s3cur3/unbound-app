//
//  IKImageViewController.m
//  Unbound5
//
//  Created by Bob on 10/5/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "IKImageViewController.h"
#import <Quartz/Quartz.h>

@interface IKImageViewController ()

@end

@implementation IKImageViewController

- (void)openImageURL: (NSURL*)url
{
    // use ImageIO to get the CGImage, image properties, and the image-UTType
    //
    CGImageRef          image = NULL;
    CGImageSourceRef    isr = CGImageSourceCreateWithURL( (__bridge CFURLRef)url, NULL);
    
    if (isr)
    {
		NSDictionary *options = [NSDictionary dictionaryWithObject: (id)kCFBooleanTrue  forKey: (id) kCGImageSourceShouldCache];
        image = CGImageSourceCreateImageAtIndex(isr, 0, (__bridge CFDictionaryRef)options);
        
        if (image)
        {
            _imageProperties = (NSDictionary*)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(isr, 0, (__bridge CFDictionaryRef)_imageProperties));
            
            _imageUTType = (__bridge NSString*)CGImageSourceGetType(isr);
        }
		CFRelease(isr);
        
    }
    
    if (image)
    {
        [_imageView setImage: image
             imageProperties: _imageProperties];
		
		CGImageRelease(image);
        
        [_window setTitleWithRepresentedFilename: [url path]];
    }
}

-(void)awakeFromNib
{
    //NSString *   path = [[NSBundle mainBundle] pathForResource: @"earring"
                                                        //ofType: @"jpg"];
    //NSURL *      url = [NSURL fileURLWithPath: path];
    //self.url = self.representedObject;
    
    if (_imageView.image == nil)
    {
        [_imageView setImageWithURL: self.url];
    } else {
        
        NSLog(@"No need to fetch image.");

    }
     
    
    // customize the IKImageView...
    [_imageView setDoubleClickOpensImageEditPanel: YES];
    [_imageView setCurrentToolMode: IKToolModeNone];
    //[_imageView zoomImageToActualSize: self];

    [_imageView setDelegate: self];
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
             url:(NSURL *)aURL
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        self.url = aURL;
    }
    
    return self;
}

@end
