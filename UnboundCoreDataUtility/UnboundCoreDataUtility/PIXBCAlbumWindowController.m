//
//  PIXBCAlbumWindowController.m
//  UnboundCoreDataUtility
//
//  Created by Bob on 1/10/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXBCAlbumWindowController.h"
#import "PIXBCCollectionViewController.h"

@interface PIXBCAlbumWindowController ()

@end

@implementation PIXBCAlbumWindowController



-(id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    if (self!=nil)
    {
        self.albumViewController = [[PIXBCCollectionViewController alloc] initWithNibName:@"PIXBCCollectionViewController" bundle:nil];
    }
    return self;
}
- (void)windowDidLoad
{
    [super windowDidLoad];
    if (self.window) {
        [self.window setContentView:self.albumViewController.view];
        //[self.window.contentView addSubview:self.albumViewController.view];
        //[self.albumViewController.view setFrame:self.window.contentView bounds];
        //[self.albumViewController.view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    }
    
}

@end
