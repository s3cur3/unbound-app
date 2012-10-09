//
//  IKImageViewController.h
//  Unbound5
//
//  Created by Bob on 10/5/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IKImageView;
@class IKSaveOptions;

@interface IKImageViewController : NSViewController
{
    IBOutlet IKImageView *  _imageView;
    IBOutlet NSWindow *     _window;
	NSDictionary *			_toolbarDict;
    
    NSDictionary*           _imageProperties;
    NSString*               _imageUTType;
    IKSaveOptions *         _saveOptions;
}

@property (nonatomic, strong) IBOutlet IKImageView *imageView;
@property (nonatomic, copy) NSURL* url;
@property (nonatomic, strong) NSImage* image;
@end
