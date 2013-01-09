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
#import "PIXFileSystemDataSource.h"
#import "PIXDefines.h"

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
}


- (void)setView:(NSView *)view;
{
    //self.viewControllers = [NSMutableArray arrayWithCapacity:5];
    [super setView:view];
}

-(void)pushViewController:(PIXViewController *)aViewController;
{
    PIXViewController *currentViewController = [self.viewControllers lastObject];
    [aViewController.view setFrame:self.view.bounds];
    aViewController.navigationViewController = self;
    
    [currentViewController.view removeFromSuperview];
    [self.view addSubview:aViewController.view];
    [aViewController.view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    
    
    [self.viewControllers addObject:aViewController];
    
    [self setupToolbar];
}

-(void)popViewController;
{
    PIXViewController *aViewController = [self.viewControllers lastObject];
    [aViewController.view removeFromSuperview];
    aViewController.navigationViewController = nil;
    [self.viewControllers removeLastObject];
    
    PIXViewController * underViewController = [self.viewControllers lastObject];
    [underViewController.view setFrame:self.view.bounds];
    [self.view addSubview:[underViewController view]];
    [aViewController.view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
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

-(void)setupToolbar
{
    
    [[self.viewControllers lastObject] setupToolbar];
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
    _backButton.image = [NSImage imageNamed:NSImageNameGoLeftTemplate];

    [_backButton setLabel:@"Back"];
    [_backButton setPaletteLabel:@"Back"];
    
    // Set up a reasonable tooltip, and image
    // you will likely want to localize many of the item's properties
    [_backButton setToolTip:@"Navigate Back"];
    
    // Tell the item what message to send when it is clicked
    [_backButton setTarget:self];
    [_backButton setAction:@selector(popViewController)];
    
    return _backButton;
    
}

- (NSToolbarItem *)middleSpacer
{
    if(_middleSpacer != nil) return _middleSpacer;
    
    _middleSpacer = [[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier];
   
    
    return _middleSpacer;
}

//TODO: better system of showing activity
-(void)startSpinner
{
    [self updateActivityIndicatorAnimation:YES];
}
-(void)stopSpinner
{
    [self updateActivityIndicatorAnimation:NO];
}
-(void)updateActivityIndicatorAnimation:(BOOL)shouldAnimate
{
    if (shouldAnimate) {
        [self.activitySpinner startAnimation:self];
    } else {
        [self.activitySpinner stopAnimation:self];
    }
    [self.activitySpinner setNeedsDisplay:YES];
}
//

-(void)dealloc
{
    self.viewControllers = nil;
}

@end
