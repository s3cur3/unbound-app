//
//  PIXGridViewItemLayout.m
//  UnboundApp
//
//  Created by Bob on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXGridViewItemLayout.h"


@implementation PIXGridViewItemLayout


//+ (void)initialize
//{
//    kDefaultSelectionRingLineWidth = 3.0f;
//    kDefaultContentInset = 3.0f;
//    kDefaultItemBorderRadius = 5.0f;
//}
//
//- (id)init
//{
//    self = [super init];
//    if (self) {
//        self.backgroundColor        = [NSColor itemBackgroundColor];
//        self.selectionRingColor     = [NSColor itemSelectionRingColor];
//        self.selectionRingLineWidth = kDefaultSelectionRingLineWidth;
//        self.contentInset           = kDefaultContentInset;
//        self.itemBorderRadius       = kDefaultItemBorderRadius;
//        self.visibleContentMask     = (CNGridViewItemVisibleContentImage | CNGridViewItemVisibleContentTitle);
//        
//        /// title text font attributes
//        NSColor *textColor      = [NSColor itemTitleColor];
//        NSShadow *textShadow    = [[NSShadow alloc] init];
//        [textShadow setShadowColor: [NSColor itemTitleShadowColor]];
//        [textShadow setShadowOffset: NSMakeSize(0, -1)];
//        
//        NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
//        [textStyle setAlignment: NSCenterTextAlignment];
//        
//        _itemTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    [NSFont fontWithName:@"Helvetica" size:12], NSFontAttributeName,
//                                    textShadow,                                 NSShadowAttributeName,
//                                    textColor,                                  NSForegroundColorAttributeName,
//                                    textStyle,                                  NSParagraphStyleAttributeName,
//                                    nil];
//    }
//    return self;
//}

+ (PIXGridViewItemLayout *)defaultLayout
{
    PIXGridViewItemLayout *defaultLayout = [[[self class] alloc] init];
    return defaultLayout;
}

@end
