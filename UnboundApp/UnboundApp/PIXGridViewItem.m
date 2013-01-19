//
//  PIXGridViewItem.m
//  UnboundApp
//
//  Created by Bob on 1/18/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXGridViewItem.h"
#import "PIXAlbum.h"
#import "PIXPhoto.h"
#import "PIXThumbnail.h"
#import "CNGridViewItemLayout.h"


static CGSize kDefaultItemSizeCustomized;

@interface PIXGridViewItem()
//@property (strong) NSImageView *itemImageView;
//@property (strong) CNGridViewItemLayout *currentLayout;
@end

@implementation PIXGridViewItem

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initialzation

+ (void)initialize
{
    kCNDefaultItemIdentifier = @"PIXGridViewItem";
    kDefaultItemSizeCustomized         = NSMakeSize(230.0f, 230.0f);
}

+ (CGSize)defaultItemSize
{
    return kDefaultItemSizeCustomized;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Reusing Grid View Items

- (void)prepareForReuse
{
    if (!self.album.coverPhoto.thumbnail.imageData)  {
        [self.album cancelThumbnailLoading];
    }
    self.itemImage = nil;
    self.itemTitle = @"";
    self.index = CNItemIndexUndefined;
    self.selected = NO;
    self.selectable = YES;
    self.hovered = NO;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - ViewDrawing

//- (void)drawRect:(NSRect)rect
//{
//    NSRect dirtyRect = self.bounds;
//    
//    // decide which layout we have to use
//    /// contentRect is the rect respecting the value of layout.contentInset
//    NSRect contentRect = NSMakeRect(dirtyRect.origin.x + self.currentLayout.contentInset,
//                                    dirtyRect.origin.y + self.currentLayout.contentInset,
//                                    dirtyRect.size.width - self.currentLayout.contentInset * 2,
//                                    dirtyRect.size.height - self.currentLayout.contentInset * 2);
//    
//    NSBezierPath *contentRectPath = [NSBezierPath bezierPathWithRoundedRect:contentRect
//                                                                    xRadius:self.currentLayout.itemBorderRadius
//                                                                    yRadius:self.currentLayout.itemBorderRadius];
//    [self.currentLayout.backgroundColor setFill];
//    [contentRectPath fill];
//    
//    /// draw selection ring
//    if (self.selected) {
//        [self.currentLayout.selectionRingColor setStroke];
//        [contentRectPath setLineWidth:self.currentLayout.selectionRingLineWidth];
//        [contentRectPath stroke];
//    }
//    
//    
//    NSRect srcRect = NSZeroRect;
//    srcRect.size = self.itemImage.size;
//    NSRect imageRect = NSZeroRect;
//    NSRect textRect = NSZeroRect;
//    
//    if (self.currentLayout.visibleContentMask & (CNGridViewItemVisibleContentImage | CNGridViewItemVisibleContentTitle)) {
//        imageRect = NSMakeRect(((NSWidth(contentRect) - self.itemImage.size.width) / 2) + self.currentLayout.contentInset,
//                               self.currentLayout.contentInset + 10,
//                               self.itemImage.size.width,
//                               self.itemImage.size.height);
//        [self.itemImage drawInRect:imageRect fromRect:srcRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
//        
//        textRect = NSMakeRect(contentRect.origin.x + 3,
//                              NSHeight(contentRect) - 20,
//                              NSWidth(contentRect) - 6,
//                              14);
//        [self.itemTitle drawInRect:textRect withAttributes:self.currentLayout.itemTitleTextAttributes];
//    }
//    
//    else if (self.currentLayout.visibleContentMask & CNGridViewItemVisibleContentImage) {
//        imageRect = NSMakeRect(((NSWidth(contentRect) - self.itemImage.size.width) / 2) + self.currentLayout.contentInset,
//                               ((NSHeight(contentRect) - self.itemImage.size.height) / 2) + self.currentLayout.contentInset,
//                               self.itemImage.size.width,
//                               self.itemImage.size.height);
//    }
//    
//    else if (self.currentLayout.visibleContentMask & CNGridViewItemVisibleContentTitle) {
//    }
//    
//}



//- (id)initWithFrame:(NSRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code here.
//    }
//    
//    return self;
//}
//


@end
