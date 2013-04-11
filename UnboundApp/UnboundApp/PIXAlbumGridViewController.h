//
//  PIXCNAlbumViewController.h
//  UnboundApp
//
//  Created by Scott Sykora on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PIXViewController.h"
#import "PIXGridViewController.h"
#import "PIXSplitViewController.h"

@interface PIXAlbumGridViewController : PIXGridViewController <NSTextFieldDelegate, PIXSplitViewControllerDelegate>

//PIXSplitViewControllerDelegate
-(void)albumSelected:(PIXAlbum *)anAlbum atIndex:(NSUInteger)index;

@end
