/******************************************************************************\
* Copyright (C) 2012-2013 Leap Motion, Inc. All rights reserved.               *
* Leap Motion proprietary and confidential. Not for distribution.              *
* Use subject to the terms of the Leap Motion SDK Agreement available at       *
* https://developer.leapmotion.com/sdk_agreement, or another agreement         *
* between Leap Motion and you, your company or other organization.             *
\******************************************************************************/

#import "PIXLeapInputManager.h"
#import "LeapObjectiveC.h"


@interface PIXLeapInputManager( )<LeapListener, LeapDelegate>

@property (strong) LeapController *controller;
@property NSMutableArray * leapResponders;
@property NSRect screenRect;

@property BOOL swipeGestureFlag;

@end

@implementation PIXLeapInputManager



+(PIXLeapInputManager *)sharedInstance
{
    __strong static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)run
{
    // hard coded screen position:
    
    self.screenRect = CGRectMake(-120, 130, 240, 200);
    
    self.controller = [[LeapController alloc] init];
    [self.controller addListener:self];

    NSLog(@"running");
    //[[NSRunLoop currentRunLoop] run]; // required for performSelectorOnMainThread:withObject
}

- (void)addResponder:(id<leapResponder>)aResponder
{
    if(self.leapResponders == nil)
    {
        self.leapResponders = [NSMutableArray new];
    }
    
    [self.leapResponders insertObject:aResponder atIndex:0];
}

- (void)removeResponder:(id<leapResponder>)aResponder
{
    NSUInteger index = [self.leapResponders indexOfObject:aResponder];
    while(index != NSNotFound)
    {
        [self.leapResponders removeObjectAtIndex:index];
        index = [self.leapResponders indexOfObject:aResponder];
    }
}

#pragma mark - SampleListener Callbacks

- (void)onInit:(NSNotification *)notification
{
    DLog(@"Leap Initialized");
}

- (void)onConnect:(NSNotification *)notification;
{
    DLog(@"Leap Connected");
    LeapController *aController = (LeapController *)[notification object];
    [aController enableGesture:LEAP_GESTURE_TYPE_CIRCLE enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_KEY_TAP enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_SCREEN_TAP enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_SWIPE enable:YES];
}

- (void)onDisconnect:(NSNotification *)notification;
{
    DLog(@"Leap Disconnected");
}

- (void)onExit:(NSNotification *)notification;
{
    DLog(@"Leap Exited");
}

- (void)onFrame:(NSNotification *)notification;
{
    LeapController *aController = (LeapController *)[notification object];

    // Get the most recent frame and report some basic information
    LeapFrame *frame = [aController frame:0];
    
    NSPoint normalizedPoint = CGPointZero;
    
    if ([[frame hands] count] != 0) {
        // Get the first hand
        LeapHand *hand = [[frame hands] objectAtIndex:0];
        
        // Check if the hand has any fingers
        NSArray *fingers = [hand fingers];
        if ([fingers count] != 0) {
            
            // Calculate the hand's average finger tip position
            LeapVector *avgPos = [[LeapVector alloc] init];
            for (int i = 0; i < [fingers count]; i++) {
                LeapFinger *finger = [fingers objectAtIndex:i];
                avgPos = [avgPos plus:[finger tipPosition]];
            }
            
            avgPos = [avgPos divide:[fingers count]];
            
            /*
            // if this is the first frame we've seen a finger in, center it
            if(self.screenRect.size.width == 0)
            {
                self.screenRect = CGRectMake(avgPos.x - 50, avgPos.y - 40, 100, 80);
            }
            
            NSPoint screenOrigin = self.screenRect.origin;
            NSSize screenSize = self.screenRect.size;
            
            // make the screenRect wider if we're outside of it
            if(avgPos.x < self.screenRect.origin.x)
            {
                float difference = self.screenRect.origin.x - avgPos.x;
                screenOrigin.x = avgPos.x;
                screenSize.width += difference;
            }
            
            else if(avgPos.x > self.screenRect.origin.x + self.screenRect.size.width)
            {
                screenSize.width =  avgPos.x - self.screenRect.origin.x;
            }
            
            // make the screenRect taller if we're outside of it
            if(avgPos.y < self.screenRect.origin.y)
            {
                float difference = self.screenRect.origin.y - avgPos.y;
                screenOrigin.y = avgPos.y;
                screenSize.height += difference;
            }
            
            else if(avgPos.y > self.screenRect.origin.y + self.screenRect.size.height)
            {
                screenSize.height = avgPos.y - self.screenRect.origin.y;
            }
            
            
            self.screenRect = CGRectMake(screenOrigin.x, screenOrigin.y, screenSize.width, screenSize.height);
            
            DLog(@"SCREEN SIZE: %f, %f", screenSize.width, screenSize.height);
            
            */
             
            // normalize the point so it's between 0 and 1 in both directions
            
            normalizedPoint.x = (avgPos.x - self.screenRect.origin.x)/self.screenRect.size.width;
            normalizedPoint.y = (avgPos.y - self.screenRect.origin.y)/self.screenRect.size.height;
            
            if(normalizedPoint.x < 0.0) normalizedPoint.x = 0.0;
            if(normalizedPoint.y < 0.0) normalizedPoint.y = 0.0;
            if(normalizedPoint.x > 1.0) normalizedPoint.x = 1.0;
            if(normalizedPoint.y > 1.0) normalizedPoint.y = 1.0;
            
            
            
            // loop through the responders
            for(id<leapResponder> responder in self.leapResponders)
            {
                if([responder respondsToSelector:@selector(singleFingerPoint:)])
                {
                    [responder singleFingerPoint:normalizedPoint];
                    break; // no need to keep going down the responder chain
                }
            }
            
            //DLog(@"NormalizedPoint: %f, %f", normalizedPoint.x, normalizedPoint.y);
            
            
            //NSLog(@"Hand has %ld fingers, average finger tip position %@", [fingers count], avgPos);
            
            // now convert the vector into a normalized point
            
        }
    }
    
    
    NSArray *gestures = [frame gestures:nil];
    for (int g = 0; g < [gestures count]; g++) {
        LeapGesture *gesture = [gestures objectAtIndex:g];
        switch (gesture.type) {
            case LEAP_GESTURE_TYPE_CIRCLE: {
                LeapCircleGesture *circleGesture = (LeapCircleGesture *)gesture;
                // Calculate the angle swept since the last frame
                float sweptAngle = 0;
                if(circleGesture.state != LEAP_GESTURE_STATE_START) {
                    //LeapCircleGesture *previousUpdate = (LeapCircleGesture *)[[aController frame:1] gesture:gesture.id];
                    //sweptAngle = (circleGesture.progress - previousUpdate.progress) * 2 * LEAP_PI;
                }
                
//                NSLog(@"Circle id: %d, %@, progress: %f, radius %f, angle: %f degrees",
//                      circleGesture.id, [PIXLeapInputManager stringForState:gesture.state],
//                      circleGesture.progress, circleGesture.radius, sweptAngle * LEAP_RAD_TO_DEG);
                
                if(circleGesture.progress > 0.7 && circleGesture.radius < 10.0 && circleGesture.state == LEAP_GESTURE_STATE_STOP)
                {
                    // loop through the responders
                    for(id<leapResponder> responder in self.leapResponders)
                    {
                        if([responder respondsToSelector:@selector(singleFingerSelect:)])
                        {
                            [responder singleFingerSelect:normalizedPoint];
                            break; // no need to keep going down the responder chain
                        }
                    }
                }
                
                return;
                break;
            }
            case LEAP_GESTURE_TYPE_SWIPE: {
                LeapSwipeGesture *swipeGesture = (LeapSwipeGesture *)gesture;
//                NSLog(@"Swipe id: %d, %@, position: %@, direction: %@, speed: %f",
//                      swipeGesture.id, [PIXLeapInputManager stringForState:swipeGesture.state],
//                      swipeGesture.position, swipeGesture.direction, swipeGesture.speed);
                
                
                
                if ([[frame hands] count] != 0 && swipeGesture.state == LEAP_GESTURE_STATE_START) {
                    // Get the first hand
                    LeapHand *hand = [[frame hands] objectAtIndex:0];
                    
                    // Check if the hand has any fingers
                    NSArray *fingers = [hand fingers];
                    if ([fingers count] > 2) {
                        
                        /*
                        if(swipeGesture.state == LEAP_GESTURE_STATE_START)
                        {
                            self.swipeGestureFlag = YES;
                            break;
                        }*/
                        
                        if(!self.swipeGestureFlag)
                        {
                            self.swipeGestureFlag = YES;
                            
                            double delayInSeconds = 0.7;
                            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                self.swipeGestureFlag = NO;
                            });
                            
                            // now figure out the gesture direction
                            if(swipeGesture.direction.y > 0.8) // this is the up direction
                            {
                                // loop through the responders
                                for(id<leapResponder> responder in self.leapResponders)
                                {
                                    if([responder respondsToSelector:@selector(multiFingerSwipeUp)])
                                    {
                                        [responder multiFingerSwipeUp];
                                        break; // no need to keep going down the responder chain
                                    }
                                }
                            }
                            
                            // now figure out the gesture direction
                            if(swipeGesture.direction.y < -0.8) // this is the down direction
                            {
                                // loop through the responders
                                for(id<leapResponder> responder in self.leapResponders)
                                {
                                    if([responder respondsToSelector:@selector(multiFingerSwipeDown)])
                                    {
                                        [responder multiFingerSwipeDown];
                                        break; // no need to keep going down the responder chain
                                    }
                                }
                            }
                            
                            // now figure out the gesture direction
                            if(swipeGesture.direction.x > 0.8) // this is the right direction
                            {
                                // loop through the responders
                                for(id<leapResponder> responder in self.leapResponders)
                                {
                                    if([responder respondsToSelector:@selector(multiFingerSwipeRight)])
                                    {
                                        [responder multiFingerSwipeRight];
                                        break; // no need to keep going down the responder chain
                                    }
                                }
                            }
                            
                            // now figure out the gesture direction
                            if(swipeGesture.direction.x < -0.8) // this is the left direction
                            {
                                // loop through the responders
                                for(id<leapResponder> responder in self.leapResponders)
                                {
                                    if([responder respondsToSelector:@selector(multiFingerSwipeLeft)])
                                    {
                                        [responder multiFingerSwipeLeft];
                                        break; // no need to keep going down the responder chain
                                    }
                                }
                            }
                            
                        }
                        
                        
                        
                        
                    }
                }
                
                
                break;
            }
            case LEAP_GESTURE_TYPE_KEY_TAP: {
                LeapKeyTapGesture *keyTapGesture = (LeapKeyTapGesture *)gesture;
//                NSLog(@"Key Tap id: %d, %@, position: %@, direction: %@",
//                      keyTapGesture.id, [PIXLeapInputManager stringForState:keyTapGesture.state],
//                      keyTapGesture.position, keyTapGesture.direction);
                
                break;
            }
            case LEAP_GESTURE_TYPE_SCREEN_TAP: {
                LeapScreenTapGesture *screenTapGesture = (LeapScreenTapGesture *)gesture;
                //NSLog(@"Screen Tap id: %d, %@, position: %@, direction: %@",
//                      screenTapGesture.id, [PIXLeapInputManager stringForState:screenTapGesture.state],
//                      screenTapGesture.position, screenTapGesture.direction);
                break;
            }
            default:
                //NSLog(@"Unknown gesture type");
                break;
        }
    }
    
    
    
    
    /*
    NSLog(@"Frame id: %lld, timestamp: %lld, hands: %ld, fingers: %ld, tools: %ld, gestures: %ld",
          [frame id], [frame timestamp], [[frame hands] count],
          [[frame fingers] count], [[frame tools] count], [[frame gestures:nil] count]);

    if ([[frame hands] count] != 0) {
        // Get the first hand
        LeapHand *hand = [[frame hands] objectAtIndex:0];

        // Check if the hand has any fingers
        NSArray *fingers = [hand fingers];
        if ([fingers count] != 0) {
            // Calculate the hand's average finger tip position
            LeapVector *avgPos = [[LeapVector alloc] init];
            for (int i = 0; i < [fingers count]; i++) {
                LeapFinger *finger = [fingers objectAtIndex:i];
                avgPos = [avgPos plus:[finger tipPosition]];
            }
            avgPos = [avgPos divide:[fingers count]];
            NSLog(@"Hand has %ld fingers, average finger tip position %@",
                  [fingers count], avgPos);
        }

        // Get the hand's sphere radius and palm position
        NSLog(@"Hand sphere radius: %f mm, palm position: %@",
              [hand sphereRadius], [hand palmPosition]);

        // Get the hand's normal vector and direction
        const LeapVector *normal = [hand palmNormal];
        const LeapVector *direction = [hand direction];

        // Calculate the hand's pitch, roll, and yaw angles
        NSLog(@"Hand pitch: %f degrees, roll: %f degrees, yaw: %f degrees\n",
              [direction pitch] * LEAP_RAD_TO_DEG,
              [normal roll] * LEAP_RAD_TO_DEG,
              [direction yaw] * LEAP_RAD_TO_DEG);

        

        if (([[frame hands] count] > 0) || [[frame gestures:nil] count] > 0) {
            NSLog(@" ");
        }
    }
     
     */
}

+ (NSString *)stringForState:(LeapGestureState)state
{
    switch (state) {
        case LEAP_GESTURE_STATE_INVALID:
            return @"STATE_INVALID";
        case LEAP_GESTURE_STATE_START:
            return @"STATE_START";
        case LEAP_GESTURE_STATE_UPDATE:
            return @"STATE_UPDATED";
        case LEAP_GESTURE_STATE_STOP:
            return @"STATE_STOP";
        default:
            return @"STATE_INVALID";
    }
}


@end
