//
//  ImageViewController.h
//  Unbound5
//
//  Created by Bob on 10/6/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SearchItem.h"

@class AutoSizingImageView;

@interface ImageViewController : NSViewController 
{
    
}


@property (nonatomic, strong) IBOutlet NSScrollView * scrollView;
@property (nonatomic, strong) IBOutlet AutoSizingImageView *imageView;

@end