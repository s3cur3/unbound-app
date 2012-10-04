//
//  IKBBrowserItem.m
//  IKBrowserViewDND
//
//  Created by David Gohara on 2/26/08.
//  Copyright 2008 SmackFu-Master. All rights reserved.
//  http://smackfumaster.com
//

#import "IKBBrowserItem.h"


@implementation IKBBrowserItem

/*- (id)initWithImage:(NSImage*)anImage imageID:(NSString*)anImageID
{
	if (self = [super init]) {
		self.image = [anImage copy];
		imageID = [[anImageID lastPathComponent] copy];
	}
	return self;
}*/

/* required methods of the IKImageBrowserItem protocol */
#pragma mark -
#pragma mark item data source protocol

/* let the image browser knows we use a path representation */
- (NSString *)imageRepresentationType
{
    //return IKImageBrowserNSURLRepresentationType;
	//return IKImageBrowserPathRepresentationType;
    return IKImageBrowserNSImageRepresentationType;
}

/* give our representation to the image browser */
- (id)imageRepresentation
{
	return self.image;
    /*NSString* imagePathStr = [[NSBundle mainBundle] pathForResource:@"Abstract 1" ofType:@"jpg"];
    NSImage* image = [[NSImage alloc] initWithContentsOfFile:imagePathStr];
    return image;*/
	//[imageView setImage:image];
    //return self.url;
}

/* use the absolute filepath as identifier */
- (NSString *)imageUID
{
    return [self.url path];
}

#pragma mark Optional Methods IKImageBrowserItem Informal Protocol
- (NSString*) imageTitle
{
	return [self.url lastPathComponent];
}

- (NSString*) imageSubtitle
{
    return @"subtitle";
}

@end
