//
//  PIXCNAlbumViewController.h
//  UnboundApp
//
//  Created by Scott Sykora on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PIXViewController.h"
#import "CNGridView.h"

@interface PIXCNAlbumViewController : PIXViewController <CNGridViewDataSource, CNGridViewDelegate, NSTextFieldDelegate>

@property(nonatomic,strong) IBOutlet CNGridView * gridView;

@end
