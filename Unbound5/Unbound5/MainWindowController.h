//
//  MainWindowController.h
//  Unbound5
//
//  Created by Bob on 10/4/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <AppKit/NSPathCell.h>
#import <AppKit/NSPathControl.h>
#import <AppKit/NSPathComponentCell.h>
#import <Quartz/Quartz.h>


@class Album;
@class PageViewController;

extern NSString *searchLocationKey;
extern NSString *dropboxHomeLocationKey;
extern NSString *dropboxHomeStringKey;

@interface MainWindowController : NSObject <NSWindowDelegate,
                                            NSPathControlDelegate,
                                            NSTableViewDelegate,
                                            NSSplitViewDelegate,
                                            NSOutlineViewDataSource,
                                            NSOutlineViewDelegate>
{
@private
    NSMutableArray *iSearchQueries;
    CGFloat iThumbnailSize;
    //NSTextFieldCell *iGroupRowCell;
    //NSInteger iPreviousRowCount;
    NSURL *_searchLocation;
    
@public
    //IBOutlet NSOutlineView *resultsOutlineView;
    //IBOutlet NSPathControl *pathControl;            // path control showing the search result item's location
    //IBOutlet NSPredicateEditor *predicateEditor;
    IBOutlet NSWindow *window;
    IBOutlet NSPathControl *searchLocationPathControl;  // path control determining the search location
}

@property (strong,nonatomic) NSMutableDictionary *directoryDict;
@property (nonatomic, readonly) NSMutableArray *albumArray;
@property (strong,nonatomic) NSMutableArray *directoryArray;
@property(readwrite,retain) NSMutableArray * browserData;
@property IBOutlet IKImageBrowserView * browserView;
@property (nonatomic, assign) IBOutlet NSTableView *tableView;
@property (nonatomic, assign) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, strong) PageViewController *pageViewController;
@property (nonatomic, strong) NSView *mainContentView;


@property (nonatomic, strong) Album *selectedAlbum;
@property (nonatomic, strong) Album *dragDropDestination;

@property (nonatomic, strong) NSArray *albumSortDescriptors;

//- (IBAction)predicateEditorChanged:(id)sender;

- (IBAction)searchLocationChanged:(id)sender;
- (IBAction)zoomSliderDidChange:(id)sender;

-(void)showMainView;
-(void)startLoading;
-(void)albumsFinishedLoading;

//-(NSMutableArray *)albumArray;

@end
