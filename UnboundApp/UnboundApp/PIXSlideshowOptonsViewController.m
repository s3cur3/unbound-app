//
//  PIXSlideshowOptonsViewController.m
//  UnboundApp
//
//  Created by Scott Sykora on 3/25/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXSlideshowOptonsViewController.h"

@interface PIXSlideshowOptonsViewController ()

@end

@implementation PIXSlideshowOptonsViewController


// NOTE: Most options for this class are bound to the NSUserDefaults controller in the nib, so no need for code here

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(IBAction)startSlideShow:(id)sender
{
    [self.delegate startSlideShow:sender];
}


@end


