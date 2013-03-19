/******************************************************************************\
* Copyright (C) 2012-2013 Leap Motion, Inc. All rights reserved.               *
* Leap Motion proprietary and confidential. Not for distribution.              *
* Use subject to the terms of the Leap Motion SDK Agreement available at       *
* https://developer.leapmotion.com/sdk_agreement, or another agreement         *
* between Leap Motion and you, your company or other organization.             *
\******************************************************************************/

#import <Foundation/Foundation.h>

@protocol leapResponder;

@interface PIXLeapInputManager : NSObject

-(void)run;

+(PIXLeapInputManager *)sharedInstance;

-(void)addResponder:(id<leapResponder>)aResponder;
- (void)removeResponder:(id<leapResponder>)aResponder;

@end

@protocol leapResponder <NSObject>

@optional

-(void)singleFingerPoint:(NSPoint)normalizedPosition;
-(void)singleFingerSelect:(NSPoint)normalizedPosition;

-(void)twoFingerPinchStart;
-(void)twoFingerPinchPosition:(NSPoint)position andScale:(CGFloat)scale;

-(void)multiFingerSwipeUp;
-(void)multiFingerSwipeDown;
-(void)multiFingerSwipeRight;
-(void)multiFingerSwipeLeft;


@end
