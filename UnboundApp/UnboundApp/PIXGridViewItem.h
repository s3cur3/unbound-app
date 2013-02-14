//
//  PIXGridViewItem.h
//  UnboundApp
//
//  Created by Bob on 1/18/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "CNGridViewItem.h"

@interface PIXGridViewItem : CNGridViewItem

@property (nonatomic, weak) id representedObject;

+ (CGRect)drawBorderedPhoto:(NSImage *)photo inRect:(NSRect)rect;

+(NSImage *)dragStackForImages:(NSArray *)threeImages size:(NSSize)size title:(NSString *)title;

@end
