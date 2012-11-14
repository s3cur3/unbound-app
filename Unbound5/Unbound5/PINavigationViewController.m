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
    
    
    
    if(NO )//|| self.viewControllers.count)
    {
        [self.view replaceSubview:currentViewController.view with:aViewController.view];
        currentViewController.navigationViewController = nil;
        [self.viewControllers removeObject:currentViewController];
        //[self.view addSubview:aViewController.view];
    } else {
        [self.view addSubview:aViewController.view];
    }
    
    [self.viewControllers addObject:aViewController];
    for (PIViewController *aVC in self.viewControllers)
    {
        if (aVC!=aViewController) {
            [aVC.view setHidden:YES];
        } else {
            [aVC.view setHidden:NO];
        }
    }
    
    
    
    [self checkHideBackButton];
    //NSWindow *mainWindow = [[NSApplication sharedApplication] mainWindow];
    //[mainWindow setContentView:aViewController.view];
    //[mainWindow makeFirstResponder:aViewController.view];
}

-(void)popViewController;
{
    PIViewController *aViewController = [self.viewControllers lastObject];
    [aViewController.view removeFromSuperview];
    aViewController.navigationViewController = nil;
    [self.viewControllers removeLastObject];
    [[[self.viewControllers lastObject] view] setHidden:NO];
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
