//
//  PIXGradientBarButtonCell.h
//  UnboundApp
//
//  Created by Scott Sykora on 2/12/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PIXGradientBarButtonCell : NSButtonCell

@property (strong) NSImage * upStateBGImage;
@property (strong) NSImage * downStateBGImage;
@property (nonatomic) CGFloat capSize;

@end
