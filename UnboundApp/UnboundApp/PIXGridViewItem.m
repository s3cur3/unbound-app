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
        if([self.representedObject respondsToSelector:@selector(cancelThumbnailLoading)])
        {
            [self.representedObject cancelThumbnailLoading];
        }
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

// draws an image with a border in the rect. Returns the rect where the photo was drawn (using aspect ratio)
+ (CGRect)drawBorderedPhoto:(NSImage *)photo inRect:(NSRect)rect
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
    CGContextSetShadowWithColor(context, CGSizeMake(0, -1), 6.0, [[NSColor colorWithGenericGamma22White:0.0 alpha:.4] CGColor]);
    
    CGContextSetFillColorWithColor(context, [[NSColor whiteColor] CGColor]);
    CGContextFillRect (context,imageFrame);
    
    //[[NSColor whiteColor] set];
    
    
    CGContextSetShadowWithColor(context, CGSizeZero, 0, NULL);
    
    
    CGRect imageRect = CGRectInset(imageFrame, 6, 6);
    
    // make a smaller border when the photos are smaller
    if(rect.size.width < 120)
    {
        imageRect = CGRectInset(imageFrame, 3, 3);
    }
    //[photo drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    [photo drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    
    return imageFrame;
}



+(NSImage *)dragStackForImages:(NSArray *)threeImages size:(NSSize)size title:(NSString *)title andBadgeCount:(NSUInteger)count
{
    // set up the images
    NSImage * image1 = nil;
    NSImage * image2 = nil;
    NSImage * image3 = nil;
    
    if([threeImages count] > 0)
    {
        image1 = [threeImages objectAtIndex:0];
        
        if([threeImages count] > 1)
        {
            image2 = [threeImages objectAtIndex:1];
            
            if([threeImages count] > 2)
            {
                image3 = [threeImages objectAtIndex:2];
            }
        }
    }
    
    
    NSRect imgRect = NSMakeRect(0.0, 0.0, size.width, size.height);
    
    // create a bitmap representation
    NSBitmapImageRep *offscreenRep = [[NSBitmapImageRep alloc]
                                      initWithBitmapDataPlanes:NULL
                                      pixelsWide:size.width
                                      pixelsHigh:size.height
                                      bitsPerSample:8
                                      samplesPerPixel:4
                                      hasAlpha:YES
                                      isPlanar:NO
                                      colorSpaceName:NSDeviceRGBColorSpace
                                      bitmapFormat:NSAlphaFirstBitmapFormat
                                      bytesPerRow:0
                                      bitsPerPixel:0];
    
    // set offscreen context
    NSGraphicsContext *g = [NSGraphicsContext graphicsContextWithBitmapImageRep:offscreenRep];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:g];
    
    
    // draw the albums stack
    
    NSColor * textColor = nil;
    //NSColor * subtitleColor = nil;
    NSColor * bgColor = nil;
    
    
    bgColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"dark_bg"]];
    textColor = [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
    
    
    
    
    
    
    NSRect textRect = NSMakeRect(imgRect.origin.x + 3,
                                 0,
                                 NSWidth(imgRect) - 6,
                                 24);
    
    
    NSShadow *textShadow    = [[NSShadow alloc] init];
    [textShadow setShadowColor: [NSColor colorWithCalibratedWhite:0.0 alpha:1.3]];
    [textShadow setShadowOffset: NSMakeSize(0, -1)];
    [textShadow setShadowBlurRadius:3.0];
    
    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    [textStyle setAlignment: NSCenterTextAlignment];
    
    NSDictionary * attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSFont fontWithName:@"Helvetica Neue Bold" size:14], NSFontAttributeName,
                                 textShadow,                                 NSShadowAttributeName,
                                 //bgColor,                                    NSBackgroundColorAttributeName,
                                 textColor,                                  NSForegroundColorAttributeName,
                                 textStyle,                                  NSParagraphStyleAttributeName,
                                 nil];
    
    
    NSSize stringSize = [title sizeWithAttributes:attributes];
    
    // resize width to be a bit wider than the text
    CGFloat stringWidth = stringSize.width + 15;
    
    // make sure it's not wider than the view
    if(stringWidth > size.width)
    {
        stringWidth = size.width;
    }
    
    // make rect for text bubble
    NSRect textBubbleRect = NSInsetRect(textRect, (textRect.size.width- stringWidth)/2, 0);
    
    
       
    NSBezierPath *textBubbleRectPath = [NSBezierPath bezierPathWithRoundedRect:textBubbleRect xRadius:12 yRadius:12];
    
    [[NSColor colorWithCalibratedWhite:0 alpha:.7] setFill];
    [textBubbleRectPath fill];
    
    [title drawInRect:textRect withAttributes:attributes];
    
    
    
    CGRect albumFrame = CGRectInset(imgRect, 18, 20);
    albumFrame.origin.y += 10;
    
    // draw the stack of imagess
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    // randomly rotate the first between -.05 and .05
    float rotate1 = (CGFloat)(arc4random() % 2000)/10000 - .1;
    
    // the second needs to be the difference so that we rotate the object back
    float rotate2= (CGFloat)(arc4random() % 2000)/10000 - .1 - rotate1;
    
    CGContextSaveGState(context);
    
    CGContextTranslateCTM(context, imgRect.size.width/2, imgRect.size.height/2);
    CGContextRotateCTM(context, rotate1);
    CGContextTranslateCTM(context, -imgRect.size.width/2, -imgRect.size.height/2);
    
    [[self class] drawBorderedPhoto:image3 inRect:albumFrame];
    
    CGContextTranslateCTM(context, imgRect.size.width/2, imgRect.size.height/2);
    CGContextRotateCTM(context, rotate2);
    CGContextTranslateCTM(context, -imgRect.size.width/2, -imgRect.size.height/2);
    
    [[self class] drawBorderedPhoto:image2 inRect:albumFrame];
    
    CGContextRestoreGState(context);
    
    
    // draw the top image
    CGRect topImageRect = [[self class] drawBorderedPhoto:image1 inRect:albumFrame];
    
    // now draw the number bubble if needed
    if(count > 1)
    {
        attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSFont fontWithName:@"Helvetica Bold" size:16], NSFontAttributeName,
                      //textShadow,                                 NSShadowAttributeName,
                      //bgColor,                                    NSBackgroundColorAttributeName,
                      [NSColor whiteColor],                                  NSForegroundColorAttributeName,
                      textStyle,                                  NSParagraphStyleAttributeName,
                      nil];
        
        NSString * countString = [NSString stringWithFormat:@"%ld", count];
        
        
        NSSize stringSize = [countString sizeWithAttributes:attributes];
        
        CGFloat stringWidth = stringSize.width + 15;
        
        CGRect countBubbleRect;
        CGRect remainder;
        
        float bubbleWidth = 25;
        
        if(bubbleWidth < stringWidth)
        {
            bubbleWidth = stringWidth;
        }
        
        CGRectDivide(topImageRect, &countBubbleRect, &remainder, bubbleWidth, CGRectMaxXEdge);
        CGRectDivide(countBubbleRect, &countBubbleRect, &remainder, 25, CGRectMaxYEdge);
        
        countBubbleRect.origin.x += 8;
        countBubbleRect.origin.y += 8;
        
        NSBezierPath *countRectPath = [NSBezierPath bezierPathWithRoundedRect:countBubbleRect xRadius:12 yRadius:12];
        
        [[NSColor redColor] setFill];
        
        NSGradient * aGradient = [[NSGradient alloc] initWithStartingColor:[NSColor redColor]
                                                  endingColor:[NSColor colorWithCalibratedRed:0.580 green:0.039 blue:0.064 alpha:1.000]];
        
        CGContextSetShadowWithColor(context, CGSizeMake(0, -1), 5.0, [[NSColor colorWithGenericGamma22White:0.0 alpha:.4] CGColor]);
        [countRectPath fill];
        CGContextSetShadowWithColor(context, CGSizeZero, 0, NULL);
        
        [aGradient  drawInBezierPath:countRectPath angle:270.0];
        
        
        [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] setStroke];
        [countRectPath setLineWidth:2];
        [countRectPath stroke];
        
        
        
        countBubbleRect.origin.y -= 2;
        
        [countString drawInRect:countBubbleRect withAttributes:attributes];
    }
    
    
    // done drawing, so set the current context back to what it was
    [NSGraphicsContext restoreGraphicsState];
    
    // create an NSImage and add the rep to it
    NSImage *img = [[NSImage alloc] initWithSize:size];
    [img addRepresentation:offscreenRep];
    
    return img;
    
}



@end
