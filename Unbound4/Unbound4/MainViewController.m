//
//  MainViewController.m
//  Unbound4
//
//  Created by Bob on 10/1/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "MainViewController.h"
#import "PageViewController.h"
#import "IKBController.h"
#import "AppDelegate.h"
#import "Item.h"
#import "FileSystemItem.h"
#import <Quartz/Quartz.h>

// openFiles is a simple C function that opens an NSOpenPanel and return an array of URLs
static NSArray *openFiles()
{
    NSOpenPanel *panel;
    
    panel = [NSOpenPanel openPanel];
    [panel setFloatingPanel:YES];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:YES];
	NSInteger i = [panel runModal];
	if (i == NSOKButton)
    {
		return [panel URLs];
    }
    
    return nil;
}

@interface MainViewController ()

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateData) name:@"UB_PATH_CHANGED" object:nil];
        _tableContents = [[AppDelegate applicationDelegate] subdirectoryArray];
    }
    
    return self;
}

-(void)updateData
{
    _tableContents = [[AppDelegate applicationDelegate] subdirectoryArray];
    
    [self.tableView reloadData];
}

- (void)awakeFromNib
{
    NSLog(@"awakeFromNib");
    NSString *curPath = [[AppDelegate applicationDelegate] currentFilePath];
    [_pathLabel setStringValue:curPath];
    
    _tableContents = [[AppDelegate applicationDelegate] subdirectoryArray];
    
    [self.tableView reloadData];
}

-(void) loadView
{
    [super loadView];
    _tableContents = [[AppDelegate applicationDelegate] subdirectoryArray];
}

#pragma mark actions

/* "add" button was clicked */
- (IBAction)addImageButtonClicked:(id)sender
{
    NSArray *urls = openFiles();
    
    if (!urls)
    {
        NSLog(@"No files selected, return...");
        return;
    }
	NSLog(@"Got the URLS");
    NSURL *url = (NSURL *)[urls lastObject];
    [self.pathLabel setStringValue:url.path];
    [[AppDelegate applicationDelegate] loadDataWithPath:url.path];
    self.imageBrowserController.browserData = [[AppDelegate applicationDelegate] imagesArray];
    [self.imageBrowserController updateBrowserView];
	/* launch import in an independent thread */
    //[NSThread detachNewThreadSelector:@selector(addImagesWithPaths:) toTarget:self withObject:urls];
}

/* action called when the zoom slider did change */
- (IBAction)zoomSliderDidChange:(id)sender
{
	/* update the zoom value to scale images */
    [self.imageBrowserController.browserView setZoomValue:[sender floatValue]];
	
	/* redisplay */
    [self.imageBrowserController.browserView setNeedsDisplay:YES];
}



#pragma mark -


// The only essential/required tableview dataSource method
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_tableContents count];
}

// This method is optional if you use bindings to provide the data
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // Group our "model" object, which is a dictionary
    NSDictionary *dictionary = [_tableContents objectAtIndex:row];
    
    // In IB the tableColumn has the identifier set to the same string as the keys in our dictionary
    NSString *identifier = [tableColumn identifier];
    
    if (YES || [identifier isEqualToString:@"MainCell"]) {
        // We pass us as the owner so we can setup target/actions into this main controller object
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
        // Then setup properties on the cellView based on the column
        cellView.textField.stringValue = [dictionary objectForKey:@"Name"];
        cellView.imageView.objectValue = [dictionary objectForKey:@"Image"];
        return cellView;
    } else if ([identifier isEqualToString:@"SizeCell"]) {
        NSTextField *textField = [tableView makeViewWithIdentifier:identifier owner:self];
        NSImage *image = [dictionary objectForKey:@"Image"];
        NSSize size = image ? [image size] : NSZeroSize;
        NSString *sizeString = [NSString stringWithFormat:@"%.0fx%.0f", size.width, size.height];
        textField.objectValue = sizeString;
        return textField;
    } else {
        NSAssert1(NO, @"Unhandled table column identifier %@", identifier);
    }
    return nil;
}

// Data Source methods


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    
    return (item == nil) ? 1 : [item numberOfChildren];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return (item == nil) ? YES : ([item numberOfChildren] != -1);
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    
    return (item == nil) ? [FileSystemItem rootItem] : [(FileSystemItem *)item childAtIndex:index];
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSString *rootPath = [[AppDelegate applicationDelegate] currentFilePath];
    return (item == nil) ? rootPath : [item relativePath];
}



/*-(void)switchToPageView
{
    for (NSView *view in self.view.subviews)
    {
        [view setHidden:YES];
    }
    self.pageViewController = [[PageViewController alloc] initWithNibName:@"PageViewController" bundle:nil];
    self.pageViewController.parentViewController = self;
    [self.view addSubview:self.pageViewController.view];
    self.pageViewController.view.frame = ((NSView*)self.view).bounds;
    [self.view setNeedsDisplay:YES];
}

-(void)unhideSubviews
{
    [self.pageViewController.view setHidden:YES];
    self.pageViewController = nil;
    for (NSView *view in self.view.subviews)
    {
        [view setHidden:NO];
    }
}*/

@end
