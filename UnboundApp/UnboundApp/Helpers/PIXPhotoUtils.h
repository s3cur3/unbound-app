//
// Created by Ryan Harter on 6/1/16.
// Copyright (c) 2016 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

void alert(NSString * title, NSString * message);

enum modal_response
{
	modal_response_ok,
	modal_response_cancel,
};

enum modal_response cancellableAlert(NSString * title, NSString * message);

@interface PIXPhotoUtils : NSObject

+ (NSString *)flattenHTML:(NSString *)html;

@end
