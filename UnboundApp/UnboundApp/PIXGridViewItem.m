//
//  PIXGridViewItem.m
//  UnboundApp
//
//  Created by Bob on 1/18/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXGridViewItem.h"
//#import "PIXAlbum.h"
//#import "PIXPhoto.h"
//#import "PIXThumbnail.h"
#import "CNGridViewItemLayout.h"
#import "PIXThumbnailLoadingDelegate.h"


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
    kCNDefaultItemIdentifier = @"CNGridViewItem";
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
    if (self.representedObject )  {
        [self.representedObject cancelThumbnailLoading];
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

- (void)drawBorderedPhoto:(NSImage *)photo inRect:(NSRect)rect
{
    // calculate the proportional image frame
    CGSize imageSize = [photo size];
    
    CGRect imageFrame = CGRectMake(0, 0, imageSize.width, imageSize.height);
    
    if(imageSize.width > 0 && imageSize.height > 0)
    {
        if(imageSize.width / imageSize.height > rect.size.width / rect.size.height)
        {
            float mulitplier = rect.size.width / imageSize.width;
            
            imageFrame.size.width = mulitplier * imageFrame.size.width;
            imageFrame.size.height = mulitplier * imageFrame.size.height;
            
            imageFrame.origin.x = rect.origin.x;
            imageFrame.origin.y = (rect.size.height - imageFrame.size.height)/2 + rect.origin.y;
        }
        
        else
        {
            float mulitplier = rect.size.height / imageSize.height;
            
            imageFrame.size.width = mulitplier * imageFrame.size.width;
            imageFrame.size.height = mulitplier * imageFrame.size.height;
            
            imageFrame.origin.y = rect.origin.y;
            imageFrame.origin.x = (rect.size.width - imageFrame.size.width)/2 + rect.origin.x;
        }
    }
    
    
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetShadowWithColor(context, CGSizeMake(0, -1), 6.0, [[NSColor colorWithGenericGamma22White:0.0 alpha:.5] CGColor]);
    
    
    
    
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:imageFrame]; // will give a 6 pixel wide border
    CGContextSetShadowWithColor(context, CGSizeZero, 0, NULL);
    
    CGRect imageRect = CGRectInset(imageFrame, 6, 6);
    //[photo drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    [photo drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
}


@end
