//
//  PIXPageView.h
//  UnboundApp
//
//  Created by Bob on 12/16/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class PIXPageViewController;

@interface PIXPageView : NSView
{
    //float thumbnailWidth, thumbnailHeight;
    NSArray *_coreImageTransitionNames;
}

@property (nonatomic, strong) CIImage *sourceImage;
@property (nonatomic, strong) CIImage *targetImage;
@property (nonatomic, strong, readwrite) CIImage *blankImage;
@property (nonatomic, strong, readwrite) CIImage *shadingImage;
@property (nonatomic, strong, readwrite) CIImage *maskImage;

@property (nonatomic, strong) NSMutableArray *transitions;


@property (weak) IBOutlet PIXPageViewController * viewController;

@end


@interface PIXPageView (PIXTransitionSetup)
@property (nonatomic, strong, readonly) NSArray* coreImageTransitionNames;
- (void)setupTransitions;
- (CIFilter *)filterForTransitionNamed:(NSString *)transitionName;

@end
