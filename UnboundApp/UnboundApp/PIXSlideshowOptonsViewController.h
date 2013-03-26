//
//  PIXSlideshowOptonsViewController.h
//  UnboundApp
//
//  Created by Scott Sykora on 3/25/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol PIXSlideshowOptonsDelegate;

@interface PIXSlideshowOptonsViewController : NSViewController

@property id<PIXSlideshowOptonsDelegate> delegate;

@end

@protocol PIXSlideshowOptonsDelegate <NSObject>

-(IBAction)startSlideShow:(id)sender;

@end
