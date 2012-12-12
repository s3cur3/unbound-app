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
#import "MainWindowController.h"


@interface ImageBrowserViewController : PIViewController
{
    
}

@property (nonatomic, strong) IBOutlet IKImageBrowserView * browserView;
@property (nonatomic, strong) Album *album;
@property (nonatomic, readwrite, strong) NSMutableArray * browserData;
@property (nonatomic, readwrite, strong) NSIndexSet * selectedPhotos;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil album:(Album *)anAlbum;

-(IBAction)getInfo:(id)sender;

@end

