/******************************************************************************\
* Copyright (C) 2012-2013 Leap Motion, Inc. All rights reserved.               *
* Leap Motion proprietary and confidential. Not for distribution.              *
* Use subject to the terms of the Leap Motion SDK Agreement available at       *
* https://developer.leapmotion.com/sdk_agreement, or another agreement         *
* between Leap Motion and you, your company or other organization.             *
\******************************************************************************/

#import <Foundation/Foundation.h>

@protocol PIXLeapResponder;

@interface PIXLeapInputManager : NSObject

-(void)run;

+(PIXLeapInputManager *)sharedInstance;

-(void)addResponder:(id<PIXLeapResponder>)aResponder;
- (void)removeResponder:(id<PIXLeapResponder>)aResponder;

@property BOOL isConnected;

@end

@protocol PIXLeapResponder <NSObject>

@optional

-(void)leapPointerPosition:(NSPoint)normalizedPosition;
-(void)leapPointerSelect:(NSPoint)normalizedPosition;

-(void)leapPanZoomStart;
-(void)leapPanZoomPosition:(NSPoint)position andScale:(CGFloat)scale;

-(void)leapSwipeUp;
-(void)leapSwipeDown;
-(void)leapSwipeRight;
-(void)leapSwipeLeft;


@end
