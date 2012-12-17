//
//  PIXImageBrowserCell.m
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXImageBrowserCell.h"

@implementation PIXImageBrowserCell

//---------------------------------------------------------------------------------
// layerForType:
//
// provides the layers for the given types
//---------------------------------------------------------------------------------
- (CALayer *) layerForType:(NSString*) type
{
	CGColorRef color;
	
	//retrieve some usefull rects
	NSRect frame = [self frame];
	NSRect imageFrame = [self imageFrame];
	NSRect relativeImageFrame = NSMakeRect(imageFrame.origin.x - frame.origin.x, imageFrame.origin.y - frame.origin.y, imageFrame.size.width, imageFrame.size.height);
    
	/* place holder layer */
	if(type == IKImageBrowserCellPlaceHolderLayer){
		//create a place holder layer
		CALayer *layer = [CALayer layer];
		layer.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        
		CALayer *placeHolderLayer = [CALayer layer];
		placeHolderLayer.frame = *(CGRect*) &relativeImageFrame;
        
		CGFloat fillComponents[4] = {0.5, 0.5, 0.5, 0.3};
		CGFloat strokeComponents[4] = {0.5, 0.5, 0.5, 0.9};
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
		//set a background color
		color = CGColorCreate(colorSpace, fillComponents);
		[placeHolderLayer setBackgroundColor:color];
		CFRelease(color);
		
		//set a stroke color
		color = CGColorCreate(colorSpace, strokeComponents);
		[placeHolderLayer setBorderColor:color];
		CFRelease(color);
        
		[placeHolderLayer setBorderWidth:2.0];
		[placeHolderLayer setCornerRadius:10];
		CFRelease(colorSpace);
		
		[layer addSublayer:placeHolderLayer];
		
		return layer;
	}
	
	/* foreground layer */
	if(type == IKImageBrowserCellForegroundLayer){
		//no foreground layer on place holders
		if([self cellState] != IKImageStateReady)
			return nil;
		
		//create a foreground layer that will contain several childs layer
		CALayer *layer = [CALayer layer];
		layer.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        
		//NSRect imageContainerFrame = [self imageContainerFrame];
		//NSRect relativeImageContainerFrame = NSMakeRect(imageContainerFrame.origin.x - frame.origin.x, imageContainerFrame.origin.y - frame.origin.y, imageContainerFrame.size.width, imageContainerFrame.size.height);
        
        //layer.frame = relativeImageFrame;
        
        NSRect borderFrame = NSInsetRect(relativeImageFrame, -1, -1);
		
		//add a white border overlay
		CALayer *borderLayer = [CALayer layer];
		borderLayer.frame = borderFrame;
		
        
        
        //set a border color
		
        
        if(!self.isSelected)
        {
            color = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
            [borderLayer setBorderWidth:5.0];
            [layer setShadowOpacity:1.0];
        }
        
        else
        {
            color = CGColorCreateGenericRGB(0.189, 0.657, 0.859, 1.000); // bluish color
            [borderLayer setBorderWidth:4.0];
            [layer setShadowOpacity:0.0];
        }
        
		[borderLayer setBorderColor:color];
        
		CFRelease(color);
        
        color = CGColorCreateGenericGray(0.0, 0.0);
        [layer setShadowColor:color];
        
        [layer setShadowRadius:5.0];
        CFRelease(color);
        
        [layer addSublayer:borderLayer];
		
        [layer setShouldRasterize:YES];
        
		return layer;
	}
    
	/* selection layer */
	if(type == IKImageBrowserCellSelectionLayer){
        
		//no background layer on place holders
		if([self cellState] != IKImageStateReady)
			return nil;
        
		CALayer *layer = [CALayer layer];
		layer.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
		
		NSRect selectionRect = relativeImageFrame;
        selectionRect.origin.x += 5;
        selectionRect.origin.y += 5;
        
        selectionRect = CGRectInset(selectionRect, -2, -2);
		
		CALayer *photoSelectionLayer = [CALayer layer];
		photoSelectionLayer.frame = selectionRect;
        
        //set a border color
        color = CGColorCreateGenericRGB(0.325, 0.763, 0.999, 1.000);// lighter bluish color
		[photoSelectionLayer setBorderColor:color];
        [photoSelectionLayer setBorderWidth:6.0];
        [photoSelectionLayer setCornerRadius:4.0];
        CFRelease(color);
        
        color = CGColorCreateGenericGray(0.4, 1.0);
        [photoSelectionLayer setBackgroundColor:color];
		[photoSelectionLayer setShadowOpacity:0.8];
        [photoSelectionLayer setShadowOffset:CGSizeMake(0, -1)];
        CFRelease(color);
        
		[layer addSublayer:photoSelectionLayer];
        
		return layer;
	}
	
	/* background layer */
	if(type == IKImageBrowserCellBackgroundLayer){
		//no background layer on place holders
		if([self cellState] != IKImageStateReady)
			return nil;
        
		CALayer *layer = [CALayer layer];
		layer.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
		
		NSRect backgroundRect = relativeImageFrame;
		
		CALayer *photoBackgroundLayer = [CALayer layer];
		photoBackgroundLayer.frame = backgroundRect;
        
        color = CGColorCreateGenericGray(1.0, 1.0);
        [photoBackgroundLayer setBackgroundColor:color];
		[photoBackgroundLayer setShadowOpacity:0.5];
        CFRelease(color);
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, photoBackgroundLayer.bounds);
        
        [photoBackgroundLayer setShadowPath:path];
        CGPathRelease(path);
        
        
		[layer addSublayer:photoBackgroundLayer];
        
        [layer setShouldRasterize:YES];
		
		return layer;
	}
	
	return nil;
}

//---------------------------------------------------------------------------------
// imageFrame
//
// define where the image should be drawn
//---------------------------------------------------------------------------------
- (NSRect) imageFrame
{
	//get default imageFrame and aspect ratio
	NSRect imageFrame = [super imageFrame];
	
	if(imageFrame.size.height == 0 || imageFrame.size.width == 0) return NSZeroRect;
	
	float aspectRatio =  imageFrame.size.width / imageFrame.size.height;
	
	// compute the rectangle included in container with a margin of at least 10 pixel at the bottom, 5 pixel at the top and keep a correct  aspect ratio
	NSRect container = [self imageContainerFrame];
	
	if(container.size.height <= 0) return NSZeroRect;
	
	float containerAspectRatio = container.size.width / container.size.height;
	
	if(containerAspectRatio > aspectRatio){
		imageFrame.size.height = container.size.height;
		imageFrame.origin.y = container.origin.y;
		imageFrame.size.width = imageFrame.size.height * aspectRatio;
		imageFrame.origin.x = container.origin.x + (container.size.width - imageFrame.size.width)*0.5;
	}
	else{
		imageFrame.size.width = container.size.width;
		imageFrame.origin.x = container.origin.x;
		imageFrame.size.height = imageFrame.size.width / aspectRatio;
		imageFrame.origin.y = container.origin.y + (container.size.height - imageFrame.size.height)*0.5;
	}
	
	//round it
	imageFrame.origin.x = floorf(imageFrame.origin.x);
	imageFrame.origin.y = floorf(imageFrame.origin.y);
	imageFrame.size.width = ceilf(imageFrame.size.width);
	imageFrame.size.height = ceilf(imageFrame.size.height);
	
	return imageFrame;
}

/*
 //---------------------------------------------------------------------------------
 // imageContainerFrame
 //
 // override the default image container frame
 //---------------------------------------------------------------------------------
 - (NSRect) imageContainerFrame
 {
 NSRect container = [super frame];
 
 //make the image container 15 pixels up
 container.origin.y += 15;
 container.size.height -= 15;
 
 return container;
 }*/

//---------------------------------------------------------------------------------
// titleFrame
//
// override the default frame for the title
//---------------------------------------------------------------------------------
- (NSRect) titleFrame
{
	//get the default frame for the title
	NSRect titleFrame = [super titleFrame];
	
	//move the title inside the 'photo' background image
	NSRect container = [self frame];
	titleFrame.origin.y = container.origin.y + 3;
	
	//make sure the title has a 7px margin with the left/right borders
	float margin = titleFrame.origin.x - (container.origin.x + 7);
	if(margin < 0)
		titleFrame = NSInsetRect(titleFrame, -margin, 0);
	
	return titleFrame;
}

//---------------------------------------------------------------------------------
// selectionFrame
//
// make the selection frame a little bit larger than the default one
//---------------------------------------------------------------------------------
- (NSRect) selectionFrame
{
	return NSInsetRect([self frame], -5, -5);
}

@end
