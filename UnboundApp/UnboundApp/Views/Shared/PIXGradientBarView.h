//
//  PIXGradientView.h
//  UnboundApp
//
//  Created by Scott Sykora on 2/7/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PIXGradientBarView : NSView

@property (strong) IBOutlet NSStackView * buttonHolder;

-(void)setButtons:(NSArray *)buttonArray;

@end
