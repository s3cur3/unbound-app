//
//  PIXTextField.m
//  UnboundApp
//
//  Created by Scott Sykora on 3/28/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXFileTextField.h"

@implementation PIXFileTextField

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

/*
- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}*/


- (BOOL)becomeFirstResponder
{
    BOOL result = [super becomeFirstResponder];

    double delayInSeconds = 0.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self selectAllButExtention:nil];
    });
    //[self performSelector:@selector(selectAllButExtention:) withObject:self afterDelay:0];

    return result;
}

-(void)selectAllButExtention:(id)sender
{
    [self selectText:nil];
    
    NSString * string = [[self stringValue] stringByDeletingPathExtension];
    
    [[self currentEditor] setSelectedRange:NSMakeRange(0, [string length])];
    //[[self currentEditor] setNeedsDisplay:YES];

}

/*
-(BOOL)resignFirstResponder
{
    BOOL result = [super resignFirstResponder];
    if(result)
    {
        self.bezelStyle = NSNoBorder;
        self.drawsBackground = NO;
        [self setNeedsDisplay:YES];
        //[self performSelector:@selector(selectText:) withObject:self afterDelay:0];
    }
    return result;
}*/



-(void)mouseDown:(NSEvent *)theEvent
{
    [self.window makeFirstResponder:self];

}

@end
