//
//  PINavigationViewController.m
//  Unbound
//
//  Created by Bob on 11/7/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PINavigationViewController.h"
#import "PIViewController.h"

@interface PINavigationViewController ()

@property (strong, nonatomic) NSMutableArray *viewControllers;
@property (strong) IBOutlet NSView *menuView;
@property (strong) IBOutlet NSButton *backButton;



@end

@implementation PINavigationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        self.viewControllers = [NSMutableArray arrayWithCapacity:5];
    }
    
    return self;
}

-(void)checkHideBackButton
{
    if (self.viewControllers.count <=1)
    {
        [self.backButton setHidden:YES];
    } else {
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
    [self popViewController];
}

@end
