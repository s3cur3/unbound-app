//
//  Item.h
//  LionTableViewTesting
//
//  Created by Tomaž Kragelj on 8/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

@interface Item : NSObject

@property (nonatomic, copy) NSString *itemPath;
@property (nonatomic, readonly) NSString *itemDisplayName;
@property (nonatomic, readonly) NSString *itemKind;
@property (nonatomic, readonly) NSImage *itemIcon;

@end
