//
//  PIXNavigationController.m
//  UnboundApp
//
//  Created by Bob on 12/14/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXNavigationController.h"
#import "PIXViewController.h"
#import <QuartzCore/QuartzCore.h>


@interface PIXNavigationController ()

@property (strong, nonatomic) NSMutableArray *viewControllers;

@property (strong, nonatomic) NSArray * toolbarItems;


@end

@implementation PIXNavigationController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        self.viewControllers = [NSMutableArray arrayWithCapacity:5];
    }
    
    return self;
}


/*
-(void)awakeFromNib
{
    
    
    //
    PIXFileSystemDataSource *dataSource = [PIXFileSystemDataSource sharedInstance];
    if (!dataSource.finishedLoading) {
        [self startSpinner];
        PIXFileSystemDataSource *dataSource = [PIXFileSystemDataSource sharedInstance];
        [[NSNotificationCenter defaultCenter] addObserverForName:kUB_PHOTOS_LOADED_FROM_FILESYSTEM object:dataSource queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [self stopSpinner];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kUB_PHOTOS_LOADED_FROM_FILESYSTEM object:note.object];
            
        }];
    }
    //
}*/



- (void)setView:(NSView *)view;
{
    //self.viewControllers = [NSMutableArray arrayWithCapacity:5];
    [super setView:view];
}

-(void)pushViewController:(PIXViewController *)aViewController;
{
    PIXViewController *currentViewController = [self.viewControllers lastObject];
    [currentViewController willHidePIXView];
    [[currentViewController view] removeFromSuperview];
    
    aViewController.navigationViewController = self;
        
    [aViewController.view setFrame:self.view.bounds];
    
    
    [aViewController willShowPIXView];
    
    [self.view addSubview:aViewController.view];
        
    [aViewController.view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    
    [self.viewControllers addObject:aViewController];
    
    [self setupToolbar];
}

-(void)popViewController;
{
    PIXViewController *aViewController = [self.viewControllers lastObject];
    [aViewController willHidePIXView];
    [aViewController.view removeFromSuperview];
    aViewController.navigationViewController = nil;
    [self.viewControllers removeLastObject];
    
    PIXViewController * underViewController = [self.viewControllers lastObject];
    
    [underViewController.view setFrame:self.view.bounds];
    
    [underViewController willShowPIXView];
    
    [self.view addSubview:[underViewController view]];
    
    
        
    //[underViewController.view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    
    [self setupToolbar];
}

-(void)popToRootViewController
{
    // do nothing if we're already at the root
    if([self.viewControllers count] == 1) return;
    
    // remove the top vc
    PIXViewController *aViewController = [self.viewControllers lastObject];
    [aViewController willHidePIXView];
    [aViewController.view removeFromSuperview];
    aViewController.navigationViewController = nil;
    [self.viewControllers removeLastObject];
    
    // remove all middle vc's
    while ([self.viewControllers count] > 1) {
        [self.viewControllers removeLastObject];
    }
    
    // add the bottom vc to the view
    PIXViewController * underViewController = [self.viewControllers lastObject];
    [underViewController.view setFrame:self.view.bounds];
    [underViewController willShowPIXView];
    [self.view addSubview:[underViewController view]];
    
    //[underViewController.view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    
    [self setupToolbar];
}

-(NSArray *)viewControllerArray
{
    return [NSArray arrayWithArray:self.viewControllers];
}

- (IBAction)backPressed:(id)sender;
{
    [self popViewController];
}

-(void)setNavBarHidden:(BOOL)hidden
{
    /*
    NSRect frame = [[self.view window] frame];
    
    NSUInteger mask = 0;
    
    if(hidden)
    {
        mask = NSTexturedBackgroundWindowMask | NSResizableWindowMask;
    }
    
    else
    {
        mask = NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask;
    }
    
    [self.view.window setStyleMask:mask];
    
    [[self.view window] setFrame:frame display:YES];
     */
}

-(void)setupToolbar
{
    [[self.viewControllers lastObject] setupToolbar];
    
    [[self.view window] viewsNeedDisplay];
}

-(void)setToolbarItems:(NSArray *)items
{
    [self.mainWindow disableFlushWindow];

    NSDisableScreenUpdates();
    
    _toolbarItems = items;
    
    // remove all items from the toolbar
    while([[self.toolbar items] count] > 0)
    {
        [self.toolbar removeItemAtIndex:0];
    }
    
    int i = 0;
    for(NSToolbarItem * item in self.toolbarItems)
    {
        [self.toolbar insertItemWithItemIdentifier:[item itemIdentifier] atIndex:i];
        i++;
    }
    
    NSEnableScreenUpdates();
    [self.mainWindow enableFlushWindow];
    
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{    
    for(NSToolbarItem * item in self.toolbarItems)
    {
        if([[item itemIdentifier] isEqualToString:itemIdentifier])
        {
            return item;
        }
    }
    
    return nil;
}

- (NSToolbarItem *)backButton
{
    if(_backButton != nil) return _backButton;
    
    _backButton = [[NSToolbarItem alloc] initWithItemIdentifier:@"NormalBackButton"];
    
    NSButton * buttonView = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 50, 25)];
    //buttonView.image = [NSImage imageNamed:NSImageNameAddTemplate];
    [buttonView setImagePosition:NSImageOnly];
    [buttonView setBordered:YES];
    [buttonView setBezelStyle:NSTexturedSquareBezelStyle];
    [buttonView setTitle:@"Back"];
    
    
    _backButton.view = buttonView;

    [_backButton setLabel:@"Back"];
    [_backButton setPaletteLabel:@"Back"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_backButton setToolTip:@"Navigate Back"];
    
    
    // Tell the item what message to send when it is clicked
    [buttonView setTarget:self];
    [buttonView setAction:@selector(popViewController)];
    
    return _backButton;
    
}

/*
- (NSToolbarItem *)newAlbumButton
{
    if(_newAlbumButton != nil) return _newAlbumButton;
    
    _newAlbumButton = [[NSToolbarItem alloc] initWithItemIdentifier:@"NewAlbumButton"];
    //_settingsButton.image = [NSImage imageNamed:NSImageNameSmartBadgeTemplate];
    
    NSButton * buttonView = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    buttonView.image = [NSImage imageNamed:NSImageNameAddTemplate];
    [buttonView setImagePosition:NSImageOnly];
    [buttonView setBordered:YES];
    [buttonView setBezelStyle:NSTexturedSquareBezelStyle];
    [buttonView setTitle:nil];
    
    _newAlbumButton.view = buttonView;
    
    [_newAlbumButton setLabel:@"New Album"];
    [_newAlbumButton setPaletteLabel:@"New Album"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_newAlbumButton setToolTip:@"Create a New Album"];
    
    // Tell the item what message to send when it is clicked
    [buttonView setTarget:self];
    [buttonView setAction:@selector(newAlbumPressed:)];
    
    return _newAlbumButton;
    
}*/

- (NSToolbarItem *)middleSpacer
{
    if(_middleSpacer != nil) return _middleSpacer;
    
    _middleSpacer = [[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier];
   
    
    return _middleSpacer;
}



-(void)dealloc
{
    self.viewControllers = nil;
}

@end
