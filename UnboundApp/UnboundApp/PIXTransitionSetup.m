
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


-(void)logAllFilters
{
    NSArray* filters = [CIFilter filterNamesInCategories:nil];
    for (NSString* filterName in filters)
    {
        NSLog(@"Filter: %@", filterName);
        NSLog(@"Parameters: %@", [[CIFilter filterWithName:filterName] attributes]);
    }
}


-(NSArray *)coreImageTransitionNames
{
    if (_coreImageTransitionNames == nil) {
        NSArray *filterNames = @[@"CIPageCurlTransition", @"CIModTransition", @"CIDisintegrateWithMaskTransition", @"CIRippleTransition"];
        _coreImageTransitionNames = filterNames;
    }
    return _coreImageTransitionNames;
}


-(void)setupTransitions
{
#ifdef DEBUG
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self logAllFilters];
    });
#endif
    
    NSMutableArray *transitions = [[NSMutableArray alloc] initWithCapacity:self.coreImageTransitionNames.count];
    //NSArray *filterNames = [self availableFilterNames];
    for (NSString *aFilterName in self.coreImageTransitionNames) {
        CIFilter *myFilter = [self filterForTransitionNamed:aFilterName];
        if (myFilter!=nil) {
            [transitions addObject:myFilter];
        } else {
            DLog(@"No CIFilter found for : '%@'", aFilterName);
        }
    }
    DLog(@"transitions = %@", transitions);
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
    

    if ([transition isEqualToString:@"CIDisintegrateWithMaskTransition"])
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
    //    else if ([transition isEqualToString:@"CICopyMachineTransition"])
    //    {
    //        [transitionFilter setValue:
    //         [CIVector vectorWithX:rect.origin.x Y:rect.origin.y Z:rect.size.width W:rect.size.height]
    //                            forKey:@"inputExtent"];
    //    }
    //    else if ([transition isEqualToString:@"CIFlashTransition"])
    //    {
    //        [transitionFilter setValue:[CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)] forKey:@"inputCenter"];
    //        [transitionFilter setValue:[CIVector vectorWithX:rect.origin.x Y:rect.origin.y Z:rect.size.width W:rect.size.height] forKey:@"inputExtent"];
    //    }
    else {
        transitionFilter = nil;
    }
    
    return transitionFilter;
}

//-(NSMutableArray *)availableFilterNames
//{
////    NSMutableArray *popupChoices = [NSMutableArray arrayWithObjects:
////                                    // Core Animation's four built-in transition types
////                                    kCATransitionFade,
////                                    kCATransitionMoveIn,
////                                    kCATransitionPush,
////                                    kCATransitionReveal,
////                                    nil];
//
//    NSMutableArray *popupChoices = [NSMutableArray new];
//
//    NSArray *allTransitions = [CIFilter filterNamesInCategories:[NSArray arrayWithObject:kCICategoryTransition]];
//    if (allTransitions.count > 0)
//    {
//        NSString *transition;
//        for (transition in allTransitions) {
//            [popupChoices addObject:transition];
//            DLog(@"Found Filter: %@", transition);
//        }
//    }
//    DLog(@"All Available Transitions : %@", popupChoices);
//    return popupChoices;
//
//}

//- (void)setupTransitions_ALL
//{
//    CIVector  *extent;
//    int        i;
//    NSRect		rect = [self bounds];
//    thumbnailWidth = rect.size.width;
//    thumbnailHeight = rect.size.height;
//
//    NSMutableArray *transitions = self.transitions;
//
//    if(!transitions)
//    {
//		// get all the transition filters
//		NSArray	*foundTransitions = [CIFilter filterNamesInCategories:[NSArray arrayWithObject:kCICategoryTransition]];
//
//		if(!foundTransitions)
//			return;
//		i = (int)[foundTransitions count];
//
//		extent = [CIVector vectorWithX: 0  Y: 0  Z: thumbnailWidth  W: thumbnailHeight];
//
//        extent = [CIVector vectorWithX: 0  Y: 0  Z: thumbnailWidth  W: thumbnailHeight];
//
//		transitions = [[NSMutableArray alloc] initWithCapacity:i];
//		while(--i >= 0)
//		{
//			CIFilter	*theTransition = [CIFilter filterWithName:[foundTransitions objectAtIndex:i]];	    // create the filter
//
//			[theTransition setDefaults];    // initialize the filter with its defaults, as we might not set every value ourself
//
//			// setup environment maps and other static parameters of the filters
//			NSArray		*filterKeys = [theTransition inputKeys];
//			NSDictionary	*filterAttributes = [theTransition attributes];
//			if(filterKeys)
//			{
//				NSEnumerator	*enumerator = [filterKeys objectEnumerator];
//				NSString		*currentKey;
//				NSDictionary	*currentInputAttributes;
//
//				while(currentKey = [enumerator nextObject])
//				{
//					if([currentKey compare:@"inputExtent"] == NSOrderedSame)		    // set the rendering extent to the size of the thumbnail
//						[theTransition setValue:extent forKey:currentKey];
//					else {
//						currentInputAttributes = [filterAttributes objectForKey:currentKey];
//
//						NSString		    *classType = [currentInputAttributes objectForKey:kCIAttributeClass];
//
//						if([classType compare:@"CIImage"] == NSOrderedSame)
//						{
//							if([currentKey compare:@"inputShadingImage"] == NSOrderedSame)	// if there is a shading image, use our shading image
//								[theTransition setValue:[self shadingImage] forKey:currentKey];
//							else if ([currentKey compare:@"inputBacksideImage"] == NSOrderedSame)	// this is for the page curl transition
//								[theTransition setValue:[self sourceImage] forKey:currentKey];
//							else
//								[theTransition setValue:[self maskImage] forKey:currentKey];
//						}
//					}
//				}
//			}
//			[transitions addObject:theTransition];
//		}
//
//        self.transitions = transitions;
//    }
//}



@end
