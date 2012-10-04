//
//  Item.m
//  LionTableViewTesting
//
//  Created by Tomaž Kragelj on 8/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Item.h"

@implementation Item

@synthesize itemDisplayName = _itemDisplayName;
@synthesize itemPath = _itemPath;
@synthesize itemKind = _itemKind;
@synthesize itemIcon = _itemIcon;

/*- (void)dealloc {
    [_itemDisplayName release], _itemDisplayName = nil;
	[_itemPath release], _itemPath = nil;
	[_itemKind release], _itemKind = nil;
	[_itemIcon release], _itemIcon = nil;
    [super dealloc];
}*/

- (NSString *)itemDisplayName {
	if (_itemDisplayName) return _itemDisplayName;
	_itemDisplayName = [[NSFileManager defaultManager] displayNameAtPath:self.itemPath];
	return _itemDisplayName;
}

- (NSString *)itemKind {
	if (_itemKind) return _itemKind;
	if ([self.itemPath hasSuffix:@"app"])
		_itemKind = @"Application";
	else
		_itemKind = @"Folder";
	return _itemKind;
}

- (NSImage *)itemIcon {
	if (_itemIcon) return _itemIcon;
	_itemIcon = [[NSWorkspace sharedWorkspace] iconForFile:self.itemPath];
	return _itemIcon;
}

@end
