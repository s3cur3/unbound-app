//
//  PIXShareManager.h
//  UnboundApp
//
//  Created by Scott Sykora on 3/20/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PIXShareManager : NSObject <NSSharingServicePickerDelegate, NSSharingServiceDelegate>

+ (PIXShareManager *)defaultShareManager;

-(void)showShareSheetForItems:(NSArray *)items relativeToRect:(NSRect)rect ofView:(NSView *)view preferredEdge:(NSRectEdge)preferredEdge;

@end
