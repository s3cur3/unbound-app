//
//  PIXNavigationController.m
//  UnboundApp
//
//  Created by Bob on 12/14/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXNavigationController.h"
#import "PIXViewController.h"
#import "PIXFileSystemDataSource.h"
#import "PIXDefines.h"

@interface PIXNavigationController ()

@property (strong, nonatomic) NSMutableArray *viewControllers;
@property (strong) IBOutlet NSButton *backButton;

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
    
    [self checkHideBackButton];
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
    [self checkHideBackButton];
}

-(NSArray *)viewControllerArray
{
    return [NSArray arrayWithArray:self.viewControllers];
}

- (IBAction)backPressed:(id)sender;
{
    [self popViewController];
}

-(void)checkHideBackButton
{
    if (self.viewControllers.count <=1)
    {
        //[self.backButton setTitle:@""];
        //[self.backButton setImage:[NSImage imageNamed:NSImageNameAddTemplate]];
        [self.backButton setHidden:YES];
    } else {
        [self.backButton setTitle:@"Back"];
        [self.backButton setImage:nil];
        [self.backButton setHidden:NO];
    }
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
