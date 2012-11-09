//
//  ImageBrowserViewController.h
//  Unbound
//
//  Created by Bob on 11/7/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Album.h"
#import "ImageBrowserView.h"
#import "PIViewController.h"


@interface ImageBrowserViewController : PIViewController
{
    
}

@property (nonatomic, strong) IBOutlet IKImageBrowserView * browserView;
@property (nonatomic, strong) Album *album;
@property (readwrite, strong) NSMutableArray * browserData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil album:(Album *)anAlbum;

@end

