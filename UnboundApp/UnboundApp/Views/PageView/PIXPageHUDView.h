//
//  PIXPageControlView.h
//  UnboundApp
//
//  Created by Scott Sykora on 3/17/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PIXPhoto;

@interface PIXPageHUDView : NSView

@property (weak, nonatomic) PIXPhoto * photo;
@property (nonatomic) BOOL captionIsBelow;

@property BOOL isTextEditing;

@property float heightChange;

-(void)textDidEndEditing:(NSNotification *)notification;

-(IBAction)toggleCaptionEdit:(id)sender;

@end
