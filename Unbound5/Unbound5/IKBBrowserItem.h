//
//  IKBBrowserItem.h
//  IKBrowserViewDND
//
//  Created by David Gohara on 2/26/08.
//  Copyright 2008 SmackFu-Master. All rights reserved.
//  http://smackfumaster.com
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface IKBBrowserItem : NSObject 
{
	BOOL _isImage;
}

//- (id)initWithImage:(NSImage *)image imageID:(NSString *)imageID;

@property (readwrite,copy) id image;
@property (readwrite,copy) NSURL *url;
//@property (readwrite,copy) NSString *title;

#pragma mark -
#pragma mark Required Methods IKImageBrowserItem Informal Protocol
- (NSString *) imageUID;
- (NSString *) imageRepresentationType;
- (id) imageRepresentation;

#pragma mark -
#pragma mark Optional Methods IKImageBrowserItem Informal Protocol
- (NSString*) imageTitle;

@end
