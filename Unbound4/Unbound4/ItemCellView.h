//
//  ItemCellView.h
//  LionTableViewTesting
//
//  Created by Tomaž Kragelj on 8/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

@interface ItemCellView : NSTableCellView

- (void)layoutViewsForLargeSize:(BOOL)largeSize animated:(BOOL)animated;

@property (nonatomic, retain) IBOutlet NSTextField *detailTextField;

@end
