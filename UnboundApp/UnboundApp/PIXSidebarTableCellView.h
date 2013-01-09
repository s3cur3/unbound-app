//
//  PIXSidebarTableCellView.h
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Album;
@class PIXAlbum;

@interface PIXSidebarTableCellView : NSTableCellView

@property(strong) IBOutlet NSTextField *detailTextLabel;
@property(nonatomic, strong) IBOutlet PIXAlbum *album;

@end
