//
//  PIXPhotoGridViewController.m
//  UnboundApp
//
//  Created by Bob on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXPhotoGridViewController.h"
#import "PIXAppDelegate.h"
#import "PIXAppDelegate+CoreDataUtils.h"
#import "PIXAlbum.h"

@interface PIXPhotoGridViewController ()

@end

@implementation PIXPhotoGridViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(NSMutableArray *)fetchItems
{
    return [[[PIXAppDelegate sharedAppDelegate] fetchAllPhotos] mutableCopy];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNGridView Delegate

//- (void)gridView:(CNGridView *)gridView didClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
//{
//    CNLog(@"didClickItemAtIndex: %li", index);
//}

- (void)gridView:(CNGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    CNLog(@"didDoubleClickItemAtIndex: %li", index);
}

//- (void)gridView:(CNGridView *)gridView rightMouseButtonClickedOnItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
//{
//    CNLog(@"rightMouseButtonClickedOnItemAtIndex: %li", index);
//}
//
//- (void)gridView:(CNGridView *)gridView didSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
//{
//    CNLog(@"didSelectItemAtIndex: %li", index);
//}
//
//- (void)gridView:(CNGridView *)gridView didDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
//{
//    CNLog(@"didDeselectItemAtIndex: %li", index);
//}

@end
