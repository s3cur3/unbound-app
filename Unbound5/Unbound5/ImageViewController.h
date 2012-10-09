//
//  ImageViewController.h
//  Unbound5
//
//  Created by Bob on 10/6/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SearchItem.h"

@interface ImageViewController : NSViewController
{
    IBOutlet NSImageView *_imageView;
}

@property (nonatomic, strong) IBOutlet SearchItem *searchItem;
@property (nonatomic, strong) IBOutlet NSImage *image;

@end