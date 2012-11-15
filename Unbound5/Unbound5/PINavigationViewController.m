//
//  PINavigationViewController.m
//  Unbound
//
//  Created by Bob on 11/7/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PINavigationViewController.h"
#import "PIViewController.h"

#import "AlbumViewController.h"
#import "PageViewController.h"

@interface PINavigationViewController ()

@property (strong, nonatomic) NSMutableArray *viewControllers;
@property (strong) IBOutlet NSView *menuView;
@property (strong) IBOutlet NSButton *backButton;



@end

@implementation PINavigationViewController

-(void)awakeFromNib
{
    DLog(@"awakeFromNib");
    //[self.mainWindow setContentView:self.view];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        self.viewControllers = [NSMutableArray arrayWithCapacity:5];
        //[self.mainWindow setContentView:self.view];
    }
    
    return self;
}

-(void)checkHideBackButton
{
    if (self.viewControllers.count <=1)
    {
        [self.backButton setTitle:@""];
        [self.backButton setImage:[NSImage imageNamed:NSImageNameAddTemplate]];
        //[self.backButton setHidden:YES];
    } else {
        [self.backButton setTitle:@"Back"];
        [self.backButton setImage:nil];
        [self.backButton setHidden:NO];
    }
}

-(void)pushViewController:(PIViewController *)aViewController;
{
    PIViewController *currentViewController = [self.viewControllers lastObject];
    [aViewController.view setFrame:self.view.bounds];
    aViewController.navigationViewController = self;
    
    [currentViewController.view removeFromSuperview];
    [self.view addSubview:aViewController.view];

    
    [self.viewControllers addObject:aViewController];
    
    [self checkHideBackButton];
    /*NSWindow *mainWindow = [[NSApplication sharedApplication] mainWindow];
    //[mainWindow setContentView:aViewController.view];

    NSView *aView = [aViewController.view enclosingScrollView];
    if (aView == nil) {
        aView = aViewController.view;
    }
    [mainWindow makeFirstResponder:aView];*/
}

-(void)popViewController;
{
    PIViewController *aViewController = [self.viewControllers lastObject];
    [aViewController.view removeFromSuperview];
    aViewController.navigationViewController = nil;
    [self.viewControllers removeLastObject];
    
    PIViewController * underViewController = [self.viewControllers lastObject];
    [underViewController.view setFrame:self.view.bounds];
    [self.view addSubview:[underViewController view]];
    [self checkHideBackButton];
}

-(NSArray *)viewControllerArray
{
    return [NSArray arrayWithArray:self.viewControllers];
}

- (IBAction)backPressed:(id)sender;
{
    if ([[self.viewControllers lastObject] class] == NSClassFromString(@"AlbumViewController"))
    {
        [(AlbumViewController *)[self.viewControllers lastObject] createNewAlbum:sender];
    } else {
        [self popViewController];
    }
}

@end
