//
//  PIXCollectionViewItemView.h
//  UnboundApp
//
//  Created by Ditriol Wei on 4/8/16.
//  Copyright © 2016 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PIXCollectionViewItem : NSCollectionViewItem

- (void)refresh;

@end

@interface PIXCollectionViewItemView : NSView

@property (nonatomic, weak) id representedObject;

@property CGRect contentFrame;
@property (strong) IBOutlet NSImage *itemImage;
@property (strong) IBOutlet NSString *itemTitle;
@property BOOL selected;

- (void)prepareForReuse;

+ (CGRect)drawBorderedPhoto:(NSImage *)photo inRect:(NSRect)rect;
+ (NSImage *)dragStackForImages:(NSArray *)threeImages size:(NSSize)size title:(NSString *)title andBadgeCount:(NSUInteger)count;

@end
