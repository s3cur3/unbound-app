//
//  ImageViewController.m
//  Unbound5
//
//  Created by Bob on 10/6/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "ImageViewController.h"
#import "AutoSizingImageView.h"
#import "PageViewController.h"

@interface ImageViewController ()

@end

@implementation ImageViewController


-(void)awakeFromNib
{
    self.imageView.delegate = self;
}

-(void)rightMouseDown:(NSEvent *)theEvent {
    DLog(@"rightMouseDown:%@", theEvent);
    NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Options"];
    [theMenu insertItemWithTitle:@"Set As Desktop Background" action:@selector(setDesktopImage:) keyEquivalent:@""atIndex:0];
    [NSMenu popUpContextMenu:theMenu withEvent:theEvent forView:self.imageView];
}

-(void)setDesktopImage:(id)sender
{
    if (self.pageViewController) {
        [self.pageViewController setDesktopImage:sender];
    }
}

-(void)moveToNextPage
{
    [self.pageViewController performSelector:@selector(moveToNextPage)];
}

/*

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)awakeFromNib
{
    NSLog(@"awakeFromNib");
    [self.view setWantsLayer:YES];
}

-(void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
}

-(id)representedObject
{
    return [super representedObject];
}
*/


@end
