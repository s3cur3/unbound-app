//
//  BorderedImageView.h
//  Unbound
//
//  Created by Scott Sykora on 11/18/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PIXBorderedImageView : NSView

@property (strong, nonatomic) NSImage * image;
@property (nonatomic) BOOL selected;

@end
