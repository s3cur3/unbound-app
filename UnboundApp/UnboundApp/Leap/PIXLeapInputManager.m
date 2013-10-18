/******************************************************************************\
* Copyright (C) 2012-2013 Leap Motion, Inc. All rights reserved.               *
* Leap Motion proprietary and confidential. Not for distribution.              *
* Use subject to the terms of the Leap Motion SDK Agreement available at       *
* https://developer.leapmotion.com/sdk_agreement, or another agreement         *
* between Leap Motion and you, your company or other organization.             *
\******************************************************************************/

#import "PIXLeapInputManager.h"
#import "PIXHUDMessageController.h"
#import "PIXAppDelegate.h"
#import "PIXMainWindowController.h"
#import "LeapObjectiveC.h"
#import "PIXLeapTutorialWindowController.h"

@interface PIXLeapInputManager( )<LeapListener, LeapDelegate>

@property (strong) LeapController *controller;
@property NSMutableArray * leapResponders;
@property NSRect screenRect;

@property BOOL swipeGestureFlag;
@property BOOL selectGestureFlag;

@property CGFloat pinchStartWidth;
@property CGFloat pinchStartDepth;
@property CGFloat pinchLastDepth;
@property NSPoint pinchStartPosition;

@property NSPoint smoothedNormalizedPoint;
@property NSPoint smoothedNormalizedPalmPoint;
@property CGFloat smoothedPalmDepth;

@property (strong) NSTimer * connectionTimer;

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
    
    self.screenRect = CGRectMake(-150, 130, 300, 200);
    
    self.controller = [[LeapController alloc] init];
    [self.controller addListener:self];

    NSLog(@"running");
    //[[NSRunLoop currentRunLoop] run]; // required for performSelectorOnMainThread:withObject
    
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self showConnectedAlert];
    });
}

- (void)showConnectedAlert
{
    // if we're not connected on launch and we've connected before, alert the user
    if(!self.isConnected && [[NSUserDefaults standardUserDefaults] boolForKey:@"LeapTutorialHasShown"])
    {
        // present the hud message that the leap is not connected
        NSWindow * mainwindow = [[[PIXAppDelegate sharedAppDelegate] mainWindowController] window];
        
        PIXHUDMessageController * messageHUD = [PIXHUDMessageController windowWithTitle:@"Leap Motion Controller Not Connected" andIcon:[NSImage imageNamed:@"leapnotconnected"]];
        [messageHUD presentInParentWindow:mainwindow forTimeInterval:3.0];
    }
}


- (void)addResponder:(id<PIXLeapResponder>)aResponder
{
    if(aResponder == nil)return;
    
    if(self.leapResponders == nil)
    {
        self.leapResponders = [NSMutableArray new];
    }
    
    [self.leapResponders insertObject:aResponder atIndex:0];
    
    
    // clear out any pinch gesture values
    self.pinchStartWidth = -1;
    self.pinchStartDepth = -1;
    self.pinchStartPosition = NSZeroPoint;
}

- (void)removeResponder:(id<PIXLeapResponder>)aResponder
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
    //DLog(@"Leap Initialized");
}

- (void)onConnect:(NSNotification *)notification;
{
    DLog(@"Leap Connected");
    
    LeapController *aController = (LeapController *)[notification object];
    [aController enableGesture:LEAP_GESTURE_TYPE_CIRCLE enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_KEY_TAP enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_SCREEN_TAP enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_SWIPE enable:YES];
    
    //[[aController config] setFloat:@"Gesture.Swipe.MinLength" value:150];
    [[aController config] setFloat:@"Gesture.Swipe.MinVelocity" value:2000];
    [[aController config] save];
    
    NSWindow * mainwindow = [[[PIXAppDelegate sharedAppDelegate] mainWindowController] window];
    
    // present the hud message that the leap connected
    PIXHUDMessageController * messageHUD = [PIXHUDMessageController windowWithTitle:@"Leap Motion Controller Connected" andIcon:[NSImage imageNamed:@"leapconnected"]];
    [messageHUD presentInParentWindow:mainwindow forTimeInterval:3.0];
    
    self.isConnected = YES;
    
    /*
    // stop the old timer
    [self.connectionTimer invalidate];
    
    // start a new timer
    self.connectionTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkConnection:) userInfo:nil repeats:YES];
    */
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"LeapTutorialHasShown"])
    {
        // if we're not currently showing the intro window then pop the leap tutorial (the intro window will check and present this when closed)
        if(![[[PIXAppDelegate sharedAppDelegate] introWindow].window isVisible])
        {
        
            PIXLeapTutorialWindowController * tutorial = [[PIXLeapTutorialWindowController alloc] initWithWindowNibName:@"PIXLeapTutorialWindowController"];
            [tutorial showWindow:self];
            
            // only show this tutorial once. It's also accessible from the preferences window
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"LeapTutorialHasShown"];
        }
    }
    
    
    
}

-(void)checkConnection:(NSTimer *)timer
{
    if(![self.controller isConnected])
    {
        [self onDisconnect:nil];
        
        [timer invalidate];
        self.connectionTimer = nil;
    }
}

- (void)onDisconnect:(NSNotification *)notification;
{
    DLog(@"Leap Disconnected");
    
    NSWindow * mainwindow = [[[PIXAppDelegate sharedAppDelegate] mainWindowController] window];
    
    // present the hud message that the leap connected
    PIXHUDMessageController * messageHUD = [PIXHUDMessageController windowWithTitle:@"Leap Motion Controller Disconnected" andIcon:[NSImage imageNamed:@"leapnotconnected"]];
    [messageHUD presentInParentWindow:mainwindow forTimeInterval:3.0];
    
    self.isConnected = NO;
}

- (void)onExit:(NSNotification *)notification;
{
    DLog(@"Leap Exited");
    
    NSWindow * mainwindow = [[[PIXAppDelegate sharedAppDelegate] mainWindowController] window];
    
    // present the hud message that the leap connected
    PIXHUDMessageController * messageHUD = [PIXHUDMessageController windowWithTitle:@"Leap Motion Controller Exited" andIcon:[NSImage imageNamed:@"leapnotconnected"]];
    [messageHUD presentInParentWindow:mainwindow forTimeInterval:3.0];
    
    self.isConnected = NO;
}

- (void)onFrame:(NSNotification *)notification;
{
    BOOL useFist = YES;
    BOOL suppressSwipe = NO;
    //BOOL suppressSelect = NO;
    
    LeapController *aController = (LeapController *)[notification object];

    // Get the most recent frame and report some basic information
    LeapFrame *frame = [aController frame:0];
    
    NSPoint normalizedPoint = CGPointZero;
    
    NSArray * hands = [frame hands];
    NSMutableArray *fingers = [NSMutableArray new];
    
    // Calculate the hand's average finger tip position
    LeapVector *avgPalmPos = [[LeapVector alloc] init];
    
    
    
    for(LeapHand * hand in hands)
    {
        [fingers addObjectsFromArray:[hand fingers]];
        
        // also get the average palm position
        avgPalmPos = [avgPalmPos plus:[hand palmPosition]];
        
    }
    
    avgPalmPos = [avgPalmPos divide:[hands count]];
    
    if ([fingers count] != 0) {
        
        // Calculate the hand's average finger tip position
        LeapVector *avgPos = [[LeapVector alloc] init];
        for (int i = 0; i < [fingers count]; i++) {
            LeapFinger *finger = [fingers objectAtIndex:i];
            avgPos = [avgPos plus:[finger tipPosition]];
        }
        
        avgPos = [avgPos divide:[fingers count]];
        
        
        
                     
        // normalize the point so it's between 0 and 1 in both directions
        
        normalizedPoint.x = (avgPos.x - self.screenRect.origin.x)/self.screenRect.size.width;
        normalizedPoint.y = (avgPos.y - self.screenRect.origin.y)/self.screenRect.size.height;
        
        if(normalizedPoint.x < 0.0) normalizedPoint.x = 0.0;
        if(normalizedPoint.y < 0.0) normalizedPoint.y = 0.0;
        if(normalizedPoint.x > 1.0) normalizedPoint.x = 1.0;
        if(normalizedPoint.y > 1.0) normalizedPoint.y = 1.0;
        
        if(self.smoothedNormalizedPoint.y < 0)
        {
            self.smoothedNormalizedPoint = normalizedPoint;
        }
        
        self.smoothedNormalizedPoint = CGPointMake((self.smoothedNormalizedPoint.x * 0.8) + (normalizedPoint.x * 0.2),
                                                   (self.smoothedNormalizedPoint.y * 0.94) + (normalizedPoint.y * 0.06));
        
        if(!useFist)
        {
            // handle two finger pinch
            if([fingers count] == 2 && avgPos.z < 50.0)
            {
                LeapFinger *finger1 = [fingers objectAtIndex:0];
                LeapFinger *finger2 = [fingers objectAtIndex:1];
                
                CGFloat deltax= finger2.tipPosition.x - finger1.tipPosition.x;
                CGFloat deltay= finger2.tipPosition.y - finger1.tipPosition.y;
                CGFloat deltaz= finger2.tipPosition.z - finger1.tipPosition.z;
                
                CGFloat pinchDistance = sqrt((deltax*deltax)+(deltay*deltay)+(deltaz*deltaz));
                CGFloat pinchDepth = avgPos.z;
               
                // if this is mid pinch, call the responder with the deltas
                if(self.pinchStartWidth > 0)
                {
                    // scale change in depth:
                    CGFloat distanceChange = pinchDistance / self.pinchStartWidth;
                    
                    // make this a bit less sensitive
                    //distanceChange = ((distanceChange - 1.0) / 10.0)+1.0;
                    
                    CGFloat depthChange = pinchDepth - self.pinchStartDepth;
                    
                    depthChange = (-depthChange / 80.0) + 1;
                    
                    
                    // 
                    
                    
                    CGFloat scaleDelta =  distanceChange * depthChange;
                    
                    NSPoint positionDelta = NSMakePoint(normalizedPoint.x - self.pinchStartPosition.x,
                                                        normalizedPoint.y - self.pinchStartPosition.y);
                    
                    // loop through the responders
                    for(id<PIXLeapResponder> responder in self.leapResponders)
                    {
                        if([responder respondsToSelector:@selector(leapPanZoomPosition:andScale:)])
                        {
                            [responder leapPanZoomPosition:positionDelta andScale:scaleDelta];
                            break; // do nothing else after we hit the first responder
                        }
                    }
                    
                }
                
                // this will always be called at the start
                else
                {
                    self.pinchStartWidth = pinchDistance;
                    self.pinchStartDepth = pinchDepth;
                    self.pinchStartPosition = normalizedPoint;
                    
                    // loop through the responders
                    for(id<PIXLeapResponder> responder in self.leapResponders)
                    {
                        if([responder respondsToSelector:@selector(leapPanZoomStart)])
                        {
                            [responder leapPanZoomStart];
                            break; // do nothing else after we hit the first responder
                        }
                    }
                }
                
            }
            
            else
            {
                // clear out any pinch gesture values
                self.pinchStartWidth = -1;
                self.pinchStartDepth = -1;
                self.pinchStartPosition = NSZeroPoint;
            }
            
        }
        
        // handle the single or two finger point
        if([fingers count] < 3)
        {
            // loop through the responders
            for(id<PIXLeapResponder> responder in self.leapResponders)
            {
                if([responder respondsToSelector:@selector(leapPointerPosition:)])
                {
                    [responder leapPointerPosition:self.smoothedNormalizedPoint];
                    
                    if([fingers count] < 2)
                    {
                        suppressSwipe = YES;
                    }
                    
                    break; // do nothing else after we hit the first responder
                }
            }
        }
        
        
    }
    
    else
    {
        self.smoothedNormalizedPoint = NSMakePoint(-1, -1);
    }
    
    
        
    NSArray *gestures = [frame gestures:nil];
    for (int g = 0; g < [gestures count]; g++) {
        LeapGesture *gesture = [gestures objectAtIndex:g];
        switch (gesture.type) {
                
                /*
            case LEAP_GESTURE_TYPE_CIRCLE: {
                
                
                LeapCircleGesture *circleGesture = (LeapCircleGesture *)gesture;

                
                if(circleGesture.progress > 0.7 && circleGesture.radius < 10.0 && !suppressSelect && !self.selectGestureFlag)
                {
                    // loop through the responders
                    for(id<PIXLeapResponder> responder in self.leapResponders)
                    {
                        if([responder respondsToSelector:@selector(leapPointerSelect:)])
                        {
                            [responder leapPointerSelect:normalizedPoint];
                            break; // no need to keep going down the responder chain
                        }
                    }
                    
                    // add a delay so this only fires once every half second
                    self.selectGestureFlag = YES;
                    
                    double delayInSeconds = 1.0;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        self.selectGestureFlag = NO;
                    });
                }
                
                return;
                
                
                break;
            }
                 
                 */
            case LEAP_GESTURE_TYPE_SWIPE: {
                LeapSwipeGesture *swipeGesture = (LeapSwipeGesture *)gesture;
//                NSLog(@"Swipe id: %d, %@, position: %@, direction: %@, speed: %f",
//                      swipeGesture.id, [PIXLeapInputManager stringForState:swipeGesture.state],
//                      swipeGesture.position, swipeGesture.direction, swipeGesture.speed);
                
                
                
                //if (swipeGesture.state == LEAP_GESTURE_STATE_START) {

                    
                    if(!suppressSwipe)
                    {
                        [self handleSwipe:(LeapSwipeGesture *)swipeGesture onFrame:frame];
                    }
                    
                    
                //}
                
                if(swipeGesture.state == LEAP_GESTURE_STATE_STOP || swipeGesture.state == LEAP_GESTURE_STATE_INVALID)
                {
                    //self.swipeGestureFlag = NO;
                }
                
                
                break;
            }
            case LEAP_GESTURE_TYPE_KEY_TAP: {
               
                //LeapKeyTapGesture *keytapGesture = (LeapKeyTapGesture *)gesture;
                if([fingers count] < 3)
                {
                    // loop through the responders & fire
                    for(id<PIXLeapResponder> responder in self.leapResponders)
                    {
                        if([responder respondsToSelector:@selector(leapPointerSelect:)])
                        {
                            [responder leapPointerSelect:normalizedPoint];
                            break; // no need to keep going down the responder chain
                        }
                    }
                }
                
                break;
            }
                
                /*
            case LEAP_GESTURE_TYPE_SCREEN_TAP: {
                LeapScreenTapGesture *screenTapGesture = (LeapScreenTapGesture *)gesture;
                //NSLog(@"Screen Tap id: %d, %@, position: %@, direction: %@",
//                      screenTapGesture.id, [PIXLeapInputManager stringForState:screenTapGesture.state],
//                      screenTapGesture.position, screenTapGesture.direction);
                
                if(screenTapGesture.state == LEAP_GESTURE_STATE_STOP && !suppressSelect && !self.selectGestureFlag)
                {
                    // loop through the responders
                    for(id<PIXLeapResponder> responder in self.leapResponders)
                    {
                        if([responder respondsToSelector:@selector(leapPointerSelect:)])
                        {
                            [responder leapPointerSelect:normalizedPoint];
                            break; // no need to keep going down the responder chain
                        }
                    }
                    
                    // add a delay so this only fires once every half second
                    self.selectGestureFlag = YES;
                    
                    double delayInSeconds = 1.0;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        self.selectGestureFlag = NO;
                    });
                }
                
                break;
            } */
            default:
                //NSLog(@"Unknown gesture type");
                break;
        }
    }
    
    
    
    if(useFist)
    {
        
        // handle palm grab zoom
        if([fingers count] == 0 && [hands count] == 1 &&
           //[[hands lastObject] sphereRadius] <= 110.0 &&
           !self.swipeGestureFlag)
        {
            //LeapHand * hand = [hands lastObject];
            //if([[[hands lastObject] palmVelocity] magnitude] > 50.0)
            //{
            //    DLog(@"Palm Velocity: %f", [[[hands lastObject] palmVelocity] magnitude]);
            //}
            
            normalizedPoint.x = (avgPalmPos.x - self.screenRect.origin.x)/self.screenRect.size.width;
            normalizedPoint.y = (avgPalmPos.y - self.screenRect.origin.y)/self.screenRect.size.height;
            
            self.smoothedNormalizedPalmPoint = NSMakePoint((self.smoothedNormalizedPalmPoint.x * 0.8) + ((normalizedPoint.x) * 0.2),
                                                           (self.smoothedNormalizedPalmPoint.y * 0.8) + ((normalizedPoint.y) * 0.2));
            
            /*
             if(normalizedPoint.x < 0.0) normalizedPoint.x = 0.0;
             if(normalizedPoint.y < 0.0) normalizedPoint.y = 0.0;
             if(normalizedPoint.x > 1.0) normalizedPoint.x = 1.0;
             if(normalizedPoint.y > 1.0) normalizedPoint.y = 1.0;
             */
            
            
            CGFloat pinchDepth = (self.smoothedPalmDepth * 0.8) + ((-avgPalmPos.z) * 0.2);
            self.smoothedPalmDepth = pinchDepth;
            
            // if this is mid pinch, call the responder with the deltas
            if(self.pinchStartWidth > 0)
            {
                
                CGFloat depthChange = pinchDepth - self.pinchStartDepth;
                
                /*
                 // if we're panning instead of zooming lock the zoom by moving the start depth
                 LeapVector * palmVelocity = hand.palmVelocity;
                 if(fabs(palmVelocity.normalized.z) < 0.3å)
                 {
                 depthChange = self.pinchLastDepth;
                 self.pinchStartDepth += (pinchDepth - self.pinchStartDepth) - self.pinchLastDepth;
                 
                 }
                 
                 else
                 {
                 self.pinchLastDepth = depthChange;
                 }
                 */
                
                
                
                // adjust sensitivity
                depthChange = (-depthChange / 50.0) + 1;
                
                
                // never allow 0
                if(depthChange == 0)
                {
                    depthChange = 0.01;
                }
                
                
                CGFloat scaleDelta =   depthChange;
                
                
                
                NSPoint positionDelta = NSMakePoint(normalizedPoint.x - self.pinchStartPosition.x,
                                                    normalizedPoint.y - self.pinchStartPosition.y);
                
                // loop through the responders
                for(id<PIXLeapResponder> responder in self.leapResponders)
                {
                    if([responder respondsToSelector:@selector(leapPanZoomPosition:andScale:)])
                    {
                        [responder leapPanZoomPosition:positionDelta andScale:scaleDelta];
                        //suppressSwipe = YES;
                        //suppressSelect = YES;
                        break; // do nothing else after we hit the first responder
                    }
                }
                
            }
            
            // this will initiate a grab
            else if(avgPalmPos.z < 150 // only start grab if it's well into the view area
                    //&& [[hands lastObject] sphereRadius] <= 100.0
                    && [[[hands lastObject] palmVelocity] magnitude] < 250.0)
            {
                self.smoothedPalmDepth = -avgPalmPos.z;
                self.smoothedNormalizedPalmPoint = normalizedPoint;
                self.pinchStartWidth = 1.0;
                self.pinchStartDepth = -avgPalmPos.z;
                self.pinchStartPosition = normalizedPoint;
                
                // loop through the responders
                for(id<PIXLeapResponder> responder in self.leapResponders)
                {
                    if([responder respondsToSelector:@selector(leapPanZoomStart)])
                    {
                        [responder leapPanZoomStart];
                        //suppressSwipe = YES;
                        break; // do nothing else after we hit the first responder
                    }
                }
            }
            
            else
            {
                DLog(@"Ignored grab with postion: %f and velocity %f", avgPalmPos.z, [[[hands lastObject] palmVelocity] magnitude] );
            }
            
        }
        
        else
        {
            // clear out any pinch gesture values
            self.pinchStartWidth = -1;
            self.pinchStartDepth = -1;
            self.pinchStartPosition = NSZeroPoint;
        }
        
    }


}

-(void)handleSwipe:(LeapSwipeGesture *)swipeGesture onFrame:(LeapFrame *)frame
{
    
    LeapVector *avgFingerDirection = [[LeapVector alloc] init];
    int vectorCount = 0;
    
    
    for(LeapHand * hand in [frame hands])
    {
        for(LeapFinger * finger in [hand fingers])
        {
            avgFingerDirection = [avgFingerDirection plus:finger.direction.normalized];
            vectorCount ++;
        }
    }
    
    [avgFingerDirection divide:vectorCount];
    
    //float angle = [avgFingerDirection angleTo:swipeGesture.direction.normalized];
    
    // this is the key to easy swiping. Make sure the fingers are generally pointed at a right angle to the direction of the swipe.
    //if(angle < 1.4 || angle > 1.74) return;
    
    if(self.swipeGestureFlag == YES) return; // delay between swipes
    
    //DLog(@"Angle To: %f", angle);
    
    LeapVector * direction = swipeGesture.direction;
    direction = direction.normalized;
    
    //DLog(@"Swipe Velocity: %f", swipeGesture.speed)
    
    BOOL didswipe = NO;
    
    //if(swipeGesture.speed < 2000.0) return;
    
    //if(direction.z > 0) return;
    
    // figure out the gesture direction
    if(direction.y > 0.65) // this is the up direction
    {
        // loop through the responders
        for(id<PIXLeapResponder> responder in self.leapResponders)
        {
            if([responder respondsToSelector:@selector(leapSwipeUp)])
            {
                [responder leapSwipeUp];
                didswipe = YES;
                break; // no need to keep going down the responder chain
            }
        }
        
        
    }
    
    else if(direction.y < -0.65) // this is the down direction
    {
        // loop through the responders
        for(id<PIXLeapResponder> responder in self.leapResponders)
        {
            if([responder respondsToSelector:@selector(leapSwipeDown)])
            {
                [responder leapSwipeDown];
                didswipe = YES;
                break; // no need to keep going down the responder chain
            }
        }
        
    }
    
    else if(direction.x > 0.65) // this is the right direction
    {
        // loop through the responders
        for(id<PIXLeapResponder> responder in self.leapResponders)
        {
            if([responder respondsToSelector:@selector(leapSwipeRight)])
            {
                [responder leapSwipeRight];
                didswipe = YES;

                break; // no need to keep going down the responder chain
            }
        }
        
    }
    
    else if(direction.x < -0.65) // this is the left direction
    {
        // loop through the responders
        for(id<PIXLeapResponder> responder in self.leapResponders)
        {
            if([responder respondsToSelector:@selector(leapSwipeLeft)])
            {
                [responder leapSwipeLeft];
                didswipe = YES;

                break; // no need to keep going down the responder chain
            }
        }
        
    }
    
    
    if(didswipe)
    {
        self.swipeGestureFlag = YES;
        
        double delayInSeconds = 0.4;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.swipeGestureFlag = NO;
        });
    }
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
