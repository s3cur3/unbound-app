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
    self.imageView.delegate = self;
}

-(void)dealloc
{
    self.imageView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)setRepresentedObject:(id)representedObject
{
    [self setPhoto:(PIXPhoto *)representedObject];
    //[super setRepresentedObject:representedObject];
}

-(void)photoFullsizeChanged:(NSNotification *)notification
{
    DLog(@"photoFullsizeChanged: %@", notification);
    NSCAssert(notification.object == self.representedObject, @"Notification received for wrong photo");
    PIXPhoto *aPhoto = (PIXPhoto *)notification.object;
    NSCParameterAssert(aPhoto.fullsizeImage);
    self.imageView.image = aPhoto.fullsizeImage;
}

-(void)setPhoto:(PIXPhoto *)newPhoto
{
    if (self.representedObject != newPhoto)
    {
        if (self.representedObject!=nil)
        {
            //[[NSNotificationCenter defaultCenter] removeObserver:self name:PhotoThumbDidChangeNotification object:self.representedObject];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:PhotoFullsizeDidChangeNotification object:self.representedObject];
            [self.representedObject cancelFullsizeLoading];
        }
        
        [super setRepresentedObject:newPhoto];
    
        if (self.representedObject!=nil) {
            //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoChanged:) name:PhotoThumbDidChangeNotification object:self.representedObject];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoFullsizeChanged:) name:PhotoFullsizeDidChangeNotification object:self.representedObject];
        }
        
        self.imageView.image = [newPhoto fullsizeImageForFullscreenDisplay];
    
    } else {
        DLog(@"same representedObject being set.");
    }
}

@end
