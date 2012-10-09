//
//  PageViewController.m
//  Unbound4
//
//  Created by Bob on 10/1/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PageViewController.h"
#import "AppDelegate.h"
#import "IKBBrowserItem.h"
#import "MainWindowController.h"
#import "IKImageViewController.h"
#import "SearchItem.h"
#import "ImageViewController.h"

@interface PageViewController ()
@end


@implementation PageViewController

- (IBAction)goBack:sender;
{
    [self.parentWindowController showMainView];
    //[self.view setHidden:YES];
    //[self.parentViewController unhideSubviews];
    //[(MainWindowController *)self.view.window setContentView showMainView];
}

- (IBAction)editPhoto:(id)sender;
{
    IKImageViewController *anImageViewController = [[IKImageViewController alloc] initWithNibName:@"IKImageViewController" bundle:nil];
    NSViewController *currentView = self.pageController.selectedViewController;
    id aURL = currentView.representedObject;
    anImageViewController.url = aURL;
    anImageViewController.view.frame = ((NSView*)self.pageController.selectedViewController.view).bounds;
    
    [self.view addSubview:anImageViewController.view];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        //[self updateData];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateData) name:@"UB_PATH_CHANGED" object:nil];
    }
    
    return self;
}

/*-(void) updateData
{
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:350];
    for (IKBBrowserItem *item in [[AppDelegate applicationDelegate]
                                  imagesArray])
    {
        [tmp addObject:item.image];
    }
	//Allocate some space for the data source
    self.pagerData = tmp;
    if (!self.pagerData) {
        self.pagerData = [[NSMutableArray alloc] initWithCapacity:10];
    }
	
    [self.pageController setArrangedObjects:self.pagerData];
    [self.view setNeedsDisplay:YES];
}*/

- (void)updateData {
    //NSURL *dirURL = [NSURL fileURLWithPath:@"/Users/inzan/Dropbox/Camera Uploads"];//[[NSFileManager defaultManager] url];
    //NSURL *dirURL = [[NSFileManager defaultManager] URLForDirectory:NSPicturesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSURL *dirURL = [[NSBundle mainBundle] resourceURL];
    if (self.directoryURL == nil) {
        self.directoryURL = dirURL;
    }
    
    // load all the necessary image files by enumerating through the bundle's Resources folder,
    // this will only load images of type "kUTTypeImage"
    //
    self.pageController.delegate = self;
    self.pagerData = [[NSMutableArray alloc] initWithCapacity:1];
    
    NSDirectoryEnumerator *itr = [[NSFileManager defaultManager] enumeratorAtURL:self.directoryURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLLocalizedNameKey, NSURLEffectiveIconKey, NSURLIsDirectoryKey, NSURLTypeIdentifierKey, nil] options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil];
    
    // loop through tags and set them up in a background thread
    /*dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity:10];
        for (NSURL *url in itr) {
            
            if (YES )//| i<6000)
            {
                NSString *utiValue;
                [url getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:nil];
                
                if (UTTypeConformsTo((__bridge CFStringRef)(utiValue), kUTTypeImage)) {
                    NSImage *image = [[NSImage alloc] initByReferencingURL:url];
                    [tmpArray addObject:image];
                    //i++;
                }
            } //else {
               //[self.pagerData addObject:[NSImage imageNamed:@"earring.jpg"]];
               //}
        }
    });*/
    
    
    for (NSURL *url in itr) {

            NSString *utiValue;
            [url getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:nil];
            
            if (UTTypeConformsTo((__bridge CFStringRef)(utiValue), kUTTypeImage)) {
                //NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
                NSImage *image = [[NSImage alloc] initByReferencingURL:url];
                [self.pagerData addObject:image];
            }
    }
    
    // set the first image in our list to the main magnifying view
    if ([self.pagerData count] > 0) {
        [self.pageController setArrangedObjects:self.pagerData];
    }
    
    //[self.view setNeedsDisplay:YES];
}


- (void)awakeFromNib
{
    self.pageController.transitionStyle = NSPageControllerTransitionStyleHorizontalStrip;
    
    if (NO || [self.pagerData count] > 0) {
        //[self.pagerData makeObjectsPerformSelector:@selector(thumbnailImage)];
        [self.pageController setArrangedObjects:self.pagerData];
    } else {
    //[self.view setNeedsDisplay:YES];
        [self updateData];
    }
}

@end

@implementation PageViewController (NSPageControllerDelegate)
- (NSString *)pageController:(NSPageController *)pageController identifierForObject:(id)object {
    return @"picture";
    //return [NSString stringWithFormat:@"picture-%@", [NSDate date]];
}

- (NSViewController *)pageController:(NSPageController *)pageController viewControllerForIdentifier:(NSString *)identifier {
    //NSLog(@"pageController.selectedIndex : %ld", pageController.selectedIndex);
    return [[NSViewController alloc] initWithNibName:@"imageview" bundle:nil];
}

-(void)pageController:(NSPageController *)pageController prepareViewController:(NSViewController *)viewController withObject:(id)object {
    viewController.representedObject = object;
    // viewControllers may be reused... make sure to reset important stuff like the current magnification factor.
    
    // Normally, we want to reset the magnification value to 1 as the user swipes to other images. However if the user cancels the swipe, we want to leave the original magnificaiton and scroll position alone.
    
    /*BOOL isRepreparingOriginalView = (self.initialSelectedObject && self.initialSelectedObject == object) ? YES : NO;
    if (!isRepreparingOriginalView) {
        [(NSScrollView*)viewController.view setMagnification:1.0];
    }*/
    
    // Since we implement this delegate method, we are reponsible for setting the representedObject.
    /*if ([NSImage imageNamed:@"earring.jpg"] == object)
    {
        SearchItem *anItem = [self.searchData objectAtIndex:pageController.selectedIndex];
        NSImage *anImage = [[NSImage alloc] initByReferencingFile:anItem.filePathURL.path];
        
        viewController.representedObject = anImage;
    } else {
        viewController.representedObject = object;
    }
    return;
    
    SearchItem *anItem = (SearchItem *)viewController.representedObject;
    BOOL isItem = [viewController.representedObject respondsToSelector:@selector(thumbnailImage)];
    //[anItem thumbnailImage];
    //viewController.representedObject = [[NSImage alloc] initByReferencingFile:anItem.filePathURL.path];
    if (!isItem || [anItem thumbnailImage] == nil) {
        viewController.representedObject = [NSImage imageNamed:@"earring.jpg"];
    } else {
        viewController.representedObject = [NSImage imageNamed:@"image1.jpg"];
        //viewController.representedObject = anItem.thumbnailImage;
    }*/  
}

- (void)pageControllerWillStartLiveTransition:(NSPageController *)pageController {
    // Remember the initial selected object so we can determine when a cancel occurred.
    //self.initialSelectedObject = [pageController.arrangedObjects objectAtIndex:pageController.selectedIndex];
}

- (void)pageControllerWillStartLiveTransition1:(NSPageController *)aPageController {
    // Remember the initial selected object so we can determine when a cancel occurred.
    //id anObject = [aPageController.arrangedObjects objectAtIndex:aPageController.selectedIndex];
    
    /*if ([NSImage imageNamed:@"earring.jpg"] == self.initialSelectedObject)
    {
        SearchItem *anItem = [self.searchData objectAtIndex:aPageController.selectedIndex];
        NSImage *anImage = [[NSImage alloc] initByReferencingFile:anItem.filePathURL.path];
        
        anObject = anImage;
    }*/     
    //self.initialSelectedObject = anObject;
    return;
}

- (void)pageController:(NSPageController *)pageController didTransitionToObject:(id)object
{
    NSLog(@"didTransitionToObject : %@", object);
    /*if ([NSImage imageNamed:@"earring.jpg"] == object)
    {
        SearchItem *anItem = [self.searchData objectAtIndex:pageController.selectedIndex];
        NSImage *anImage = [[NSImage alloc] initByReferencingFile:anItem.filePathURL.path];
        
        self.pageController.selectedViewController.representedObject = anImage;
    } else {
        //viewController.representedObject = object;
    }
    return;*/
}

- (void)pageControllerDidEndLiveTransition:(NSPageController *)aPageController {
    [aPageController completeTransition];
}


///BELEOW IS THE OLD STUFF TRYING TO USE IKIMAGEVIEW

/*- (NSString *)pageController:(NSPageController *)pageController identifierForObject:(id)object {
 //[(SearchItem *)object thumbnailImage];
 return [(SearchItem *)object imageUID];
 //return [NSString stringWithFormat:@"picture-%ld", pageController.selectedIndex];
 }
 
 - (NSViewController *)pageController:(NSPageController *)pageController viewControllerForIdentifier:(NSString *)identifier {
 IKImageViewController *aView =  [[IKImageViewController alloc] initWithNibName:@"IKImageViewController" bundle:nil];
 aView.representedObject = [NSURL fileURLWithPath:identifier isDirectory:NO];
 return aView;
 }
 
 
 -(void)pageController:(NSPageController *)pageController prepareViewController:(NSViewController *)viewController withObject:(id)object {
 // viewControllers may be reused... make sure to reset important stuff like the current magnification factor.
 
 // Normally, we want to reset the magnification value to 1 as the user swipes to other images. However if the user cancels the swipe, we want to leave the original magnificaiton and scroll position alone.
 
 BOOL isRepreparingOriginalView = (self.initialSelectedObject && self.initialSelectedObject == object) ? YES : NO;
 if (!isRepreparingOriginalView) {
 //[(NSScrollView*)viewController.view setMagnification:1.0];
 //[[(IKImageViewController *)viewController imageView] setZoomFactor:1.0];
 }
 
 //NSImage *image = [[NSImage alloc] initWithContentsOfURL:[object filePathURL]];
 // Since we implement this delegate method, we are reponsible for setting the representedObject.
 viewController.representedObject = [object filePathURL];
 //viewController.view.frame = self.parentWindowController.window.contentView.bounds;
 }*/

@end
