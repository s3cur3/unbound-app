
/*
     File: TransitionSetup.m
 Abstract: Initial setup of the transition filters.
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "PIXPageView.h"


@implementation PIXPageView (PIXTransitionSetup)


-(NSMutableArray *)availableFilterNames
{
    NSMutableArray *popupChoices = [NSMutableArray arrayWithObjects:
                                    // Core Animation's four built-in transition types
                                    kCATransitionFade,
                                    kCATransitionMoveIn,
                                    kCATransitionPush,
                                    kCATransitionReveal,
                                    nil];

    NSArray *allTransitions = [CIFilter filterNamesInCategories:[NSArray arrayWithObject:kCICategoryTransition]];
    if (allTransitions.count > 0)
    {
        NSString *transition;
        for (transition in allTransitions) {
            [popupChoices addObject:transition];
            DLog(@"Found Filter: %@", transition);
        }
    }
    DLog(@"All Available Transitions : %@", popupChoices);
    return popupChoices;

}

-(void)setupTransitions
{
    NSMutableArray *transitions = [[NSMutableArray alloc] init];
    NSArray *filterNames = [self availableFilterNames];
    for (NSString *aFilterName in filterNames) {
        CIFilter *myFilter = [self filterForTransitionNamed:aFilterName];
        if (myFilter!=nil) {
            [transitions addObject:myFilter];
        }
    }
    DLog(@"transitions = %@", transitions);
    self.transitions = transitions;
}

- (void)setupTransitionsOld
{
    
    [self availableFilterNames];
    
    NSMutableArray *transitions = [[NSMutableArray alloc] init];
    
    //CIVector  *extent = [CIVector vectorWithX:0  Y:0  Z:thumbnailWidth  W:thumbnailHeight];
    CIVector  *extent = [CIVector vectorWithX:0  Y:0  Z:thumbnailWidth  W:thumbnailHeight];

    [transitions addObject:[CIFilter filterWithName: @"CISwipeTransition"
            keysAndValues: @"inputExtent", extent,
                @"inputColor", [CIColor colorWithRed:0  green:0 blue:0  alpha:0],
                @"inputAngle", @(0.3*M_PI),
                @"inputWidth", @80.0,
                @"inputOpacity", @0.0, nil]];

    [transitions addObject:[CIFilter filterWithName: @"CIDissolveTransition"]];
    
    [transitions addObject:[CIFilter filterWithName: @"CISwipeTransition"			// Repeated filter type.
            keysAndValues: @"inputExtent", extent,
                @"inputColor", [CIColor colorWithRed:0  green:0 blue:0  alpha:0],
                @"inputAngle", @(M_PI_2),
                @"inputWidth", @(2.0),
                @"inputOpacity", @(0.2), nil]];

    [transitions addObject:[CIFilter filterWithName: @"CIModTransition"
            keysAndValues:
                @"inputCenter",[CIVector vectorWithX:0.5*thumbnailWidth Y:0.5*thumbnailHeight],
                @"inputAngle", @(M_PI*0.1),
                @"inputRadius", @30.0,
                @"inputCompression", @10.0, nil]];

    [transitions addObject:[CIFilter filterWithName: @"CIFlashTransition"
            keysAndValues: @"inputExtent", extent,
                @"inputCenter",[CIVector vectorWithX:0.3*thumbnailWidth Y:0.7*thumbnailHeight],
                @"inputColor", [CIColor colorWithRed:1.0 green:0.8 blue:0.6 alpha:1],
                @"inputMaxStriationRadius", @2.5,
                @"inputStriationStrength", @0.5,
                @"inputStriationContrast", @1.37,
                @"inputFadeThreshold", @0.85, nil]];

    [transitions addObject:[CIFilter filterWithName: @"CIDisintegrateWithMaskTransition"
            keysAndValues:
                @"inputMaskImage", [self maskImage],
				@"inputShadowRadius", @10.0,
                @"inputShadowDensity", @0.7,
                @"inputShadowOffset", [CIVector vectorWithX:0.0  Y:-0.05*thumbnailHeight], nil]];


    
    [transitions addObject:[CIFilter filterWithName: @"CIPageCurlTransition"
                                      keysAndValues: @"inputExtent", extent,
                            @"inputShadingImage", [self shadingImage],
                            @"inputBacksideImage", [self blankImage],
                            @"inputAngle", @(-0.2*M_PI),
                            @"inputRadius", @70.0, nil]];

    [transitions addObject:[CIFilter filterWithName: @"CICopyMachineTransition"
            keysAndValues: @"inputExtent", extent,
                @"inputColor", [CIColor colorWithRed:.6 green:1 blue:.8 alpha:1],
                @"inputAngle", @0.0,
                @"inputWidth", @40.0,
                @"inputOpacity", @1.0, nil]];
    
    [transitions addObject:[CIFilter filterWithName: @"CIRippleTransition"
                                      keysAndValues: @"inputExtent", extent,
                            @"inputShadingImage", [self shadingImage],
                            @"inputCenter",[CIVector vectorWithX:0.5*thumbnailWidth Y:0.5*thumbnailHeight],
                            @"inputWidth", @80.0,
                            @"inputScale", @30.0, nil]];
    


    
    self.transitions = transitions;
}

// -------------------------------------------------------------------------------
//	filterForTransitionNamed:(NSString *)transitionName
// -------------------------------------------------------------------------------
- (CIFilter *)filterForTransitionNamed:(NSString *)transition
{
    NSRect		rect = [self bounds];
    CIFilter	*transitionFilter = nil;
    
    // Use Core Animation's four built-in CATransition types,
	// or an appropriately instantiated and configured Core Image CIFilter.
    //
    transitionFilter = [CIFilter filterWithName:transition];
    [transitionFilter setDefaults];
    
    if ([transition isEqualToString:@"CICopyMachineTransition"])
    {
        [transitionFilter setValue:
         [CIVector vectorWithX:rect.origin.x Y:rect.origin.y Z:rect.size.width W:rect.size.height]
                            forKey:@"inputExtent"];
    }
    else if ([transition isEqualToString:@"CIDisintegrateWithMaskTransition"])
    {
        // scale our mask image to match the transition area size, and set the scaled result as the
        // "inputMaskImage" to the transitionFilter.
        //
        CIFilter *maskScalingFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
        [maskScalingFilter setDefaults];
        CGRect maskExtent = [self.maskImage extent];
        float xScale = rect.size.width / maskExtent.size.width;
        float yScale = rect.size.height / maskExtent.size.height;
        [maskScalingFilter setValue:[NSNumber numberWithFloat:yScale] forKey:@"inputScale"];
        [maskScalingFilter setValue:[NSNumber numberWithFloat:xScale / yScale] forKey:@"inputAspectRatio"];
        [maskScalingFilter setValue:self.maskImage forKey:@"inputImage"];
        
        [transitionFilter setValue:[maskScalingFilter valueForKey:@"outputImage"] forKey:@"inputMaskImage"];
    }
    else if ([transition isEqualToString:@"CIFlashTransition"])
    {
        [transitionFilter setValue:[CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)] forKey:@"inputCenter"];
        [transitionFilter setValue:[CIVector vectorWithX:rect.origin.x Y:rect.origin.y Z:rect.size.width W:rect.size.height] forKey:@"inputExtent"];
    }
    else if ([transition isEqualToString:@"CIModTransition"])
    {
        [transitionFilter setValue:[CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)] forKey:@"inputCenter"];
    }
    else if ([transition isEqualToString:@"CIPageCurlTransition"])
    {
        [transitionFilter setValue:[NSNumber numberWithFloat:-M_PI_4] forKey:@"inputAngle"];
        [transitionFilter setValue:self.shadingImage forKey:@"inputShadingImage"];
        [transitionFilter setValue:self.shadingImage forKey:@"inputBacksideImage"];
        [transitionFilter setValue:[CIVector vectorWithX:rect.origin.x Y:rect.origin.y Z:rect.size.width W:rect.size.height] forKey:@"inputExtent"];
    }
    else if ([transition isEqualToString:@"CIRippleTransition"])
    {
        [transitionFilter setValue:[CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)] forKey:@"inputCenter"];
        [transitionFilter setValue:[CIVector vectorWithX:rect.origin.x Y:rect.origin.y Z:rect.size.width W:rect.size.height] forKey:@"inputExtent"];
        [transitionFilter setValue:self.shadingImage forKey:@"inputShadingImage"];
    }
    
    return transitionFilter;
}


@end
