//
//  PIXSidebarViewController.h
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXViewController.h"

@class PIXSplitViewController;
@class PIXAlbum;

@interface PIXSidebarViewController : PIXViewController <NSOutlineViewDataSource,NSOutlineViewDelegate,NSTextFieldDelegate>

//@property (nonatomic, strong) Album* selectedAlbum;
@property (nonatomic, weak) PIXSplitViewController *splitViewController;
@property (nonatomic, strong) NSArray* albums;
@property (nonatomic, assign) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, strong) IBOutlet NSSearchField * searchField;

@property (nonatomic, strong) PIXAlbum *dragDropDestination;

-(IBAction)newAlbumPressed:(id)sender;
-(void)editSelectionName;

@end

@interface PIXSidebarViewController(NSOutlineViewDelegate)

/* View Based OutlineView: See the delegate method -tableView:viewForTableColumn:row: in NSTableView.
 */
- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item;
- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item;
- (void)outlineViewSelectionDidChange:(NSNotification *)notification;



@end

@interface PIXSidebarViewController(NSOutlineViewDataSource)

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;

@end
