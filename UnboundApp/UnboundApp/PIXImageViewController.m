//
//  PIXImageViewController.m
//  UnboundApp
//
//  Created by Bob on 12/16/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXImageViewController.h"
#import "AutoSizingImageView.h"

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
}

@end
