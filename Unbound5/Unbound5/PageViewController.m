//
//  PageViewController.m
//  Unbound4
//
//  Created by Bob on 10/1/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PageViewController.h"
#import "AppDelegate.h"
#import "MainWindowController.h"
#import "IKImageViewController.h"
#import "SearchItem.h"
#import "ImageViewController.h"
#import "Album.h"
#import "SearchItem.h"
#import <QTKit/QTKit.h>
#import <Quartz/Quartz.h>

// Make sure that we have the right headers.
#import <objc/runtime.h>

// The selectors should be recognized by class_addMethod().
@interface PageViewController (SliderCellBugFix)

- (NSSliderType)sliderType;
- (NSInteger)numberOfTickMarks;

@end


@interface PageViewController ()
@end


@implementation PageViewController

// Add C implementations of missing methods that we’ll add
// to the StdMovieUISliderCell class later.
static NSSliderType SliderType(id self, SEL _cmd)
{
    return NSLinearSlider;
}

static NSInteger NumberOfTickMarks(id self, SEL _cmd)
{
    return 0;
}

// rot13, just to be extra safe.
static NSString *ResolveName(NSString *aName)
{
    const char *_string = [aName cStringUsingEncoding:NSASCIIStringEncoding];
    NSUInteger stringLength = [aName length];
    char newString[stringLength+1];
    
    NSUInteger x;
    for(x = 0; x < stringLength; x++)
    {
        unsigned int aCharacter = _string[x];
        
        if( 0x40 < aCharacter && aCharacter < 0x5B ) // A - Z
            newString[x] = (((aCharacter - 0x41) + 0x0D) % 0x1A) + 0x41;
        else if( 0x60 < aCharacter && aCharacter < 0x7B ) // a-z
            newString[x] = (((aCharacter - 0x61) + 0x0D) % 0x1A) + 0x61;
        else  // Not an alpha character
            newString[x] = aCharacter;
    }
    newString[x] = '\0';
    
    return [NSString stringWithCString:newString encoding:NSASCIIStringEncoding];
}

// Add both methods if they aren’t already there. This should makes this
// code safe, even if Apple decides to implement the methods later on.
+ (void)load
{
    Class MovieSliderCell = NSClassFromString(ResolveName(@"FgqZbivrHVFyvqrePryy"));
    
    if (!class_getInstanceMethod(MovieSliderCell, @selector(sliderType)))
    {
        const char *types = [[NSString stringWithFormat:@"%s%s%s",
                              @encode(NSSliderType), @encode(id), @encode(SEL)] UTF8String];
        class_addMethod(MovieSliderCell, @selector(sliderType),
                        (IMP)SliderType, types);
    }
    if (!class_getInstanceMethod(MovieSliderCell, @selector(numberOfTickMarks)))
    {
        const char *types = [[NSString stringWithFormat: @"%s%s%s",
                              @encode(NSInteger), @encode(id), @encode(SEL)] UTF8String];
        class_addMethod(MovieSliderCell, @selector(numberOfTickMarks),
                        (IMP)NumberOfTickMarks, types);
    }
}



- (IBAction)goBack:sender;
{
    if (self.imageEditViewController!=nil)
    {
        [self.imageEditViewController.view removeFromSuperview];
        self.imageEditViewController = nil;
    }
    [self.parentWindowController showMainView];
}

- (IBAction)editPhoto:(id)sender;
{
    if (self.imageEditViewController!=nil)
    {
        [self.imageEditViewController.view removeFromSuperview];
        self.imageEditViewController = nil;
        return;
    }

    //NSViewController *currentView = self.pageController.selectedViewController;
    //id aURL = currentView.representedObject;
    id anItem = [self.album.photos objectAtIndex:self.pageController.selectedIndex];
    self.imageEditViewController = [[IKImageViewController alloc] initWithNibName:@"IKImageViewController"
                                                                                           bundle:nil
                                                                                              url:(NSURL *)[anItem imageRepresentation]];
    
    
    //anImageViewController.url = anItem.filePathURL;
    self.imageEditViewController.view.frame = ((NSView*)self.pageController.selectedViewController.view).bounds;
    
    [self.view addSubview:self.imageEditViewController.view];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [PageViewController load];
    }
    
    return self;
}


- (void)updateData {
    
    self.pageController.delegate = self;
    self.pagerData = [[NSMutableArray alloc] initWithCapacity:self.album.photos.count];
    
    for (id anItem in self.album.photos) {
        
        BOOL isSelected = anItem == self.initialSelectedItem;
        NSURL *fileURL = (NSURL *)[anItem imageRepresentation];
        if ([[anItem imageRepresentationType] isEqualToString:IKImageBrowserPathRepresentationType])
        {
            NSImage *image = [[NSImage alloc] initByReferencingURL:fileURL];
            [self.pagerData addObject:image];
            if (isSelected)
            {
                self.initialSelectedObject = image;
            }
        } else if ([[anItem imageRepresentationType] isEqualToString:IKImageBrowserQTMoviePathRepresentationType]) {
            DLog(@"video found : %@", fileURL);
            NSError *error=nil;
            id movie = [QTMovie movieWithURL:fileURL error:&error];
            if (!movie)
            {
                ALog(@"error loading movie : %@", error);
                [self.pagerData addObject:[NSImage imageNamed:@"NSImage"]];
            } else {
                [self.pagerData addObject:movie];
                if (isSelected)
                {
                    self.initialSelectedObject = movie;
                }
            }
        } else {
            ALog(@"Unexpected file type found : %@", fileURL);
            [self.pagerData addObject:[NSImage imageNamed:@"NSImage"]];
        }
    }

    
    // set the first image in our list to the main magnifying view
    if ([self.pagerData count] > 0) {
        [self.pageController setArrangedObjects:self.pagerData];
        NSInteger index = [self.album.photos indexOfObject:self.initialSelectedItem];
        [self.pageController setSelectedIndex:index];
    }
}


- (void)awakeFromNib
{
    self.pageController.transitionStyle = NSPageControllerTransitionStyleHorizontalStrip;
    [self updateData];
}

@end

@implementation PageViewController (NSPageControllerDelegate)
- (NSString *)pageController:(NSPageController *)pageController identifierForObject:(id)object {
    if ([object class] == [NSImage class])
    {
        return @"picture";
    } else {
        return @"video";
    };
}

- (NSViewController *)pageController:(NSPageController *)pageController viewControllerForIdentifier:(NSString *)identifier {
    //NSLog(@"pageController.selectedIndex : %ld", pageController.selectedIndex);
    if (![identifier isEqualToString:@"video"])
    {
        return [[NSViewController alloc] initWithNibName:@"imageview" bundle:nil];
    } else {
        NSViewController *videoView = [[NSViewController alloc] initWithNibName:@"videoview" bundle:nil];
        return videoView;
    }
}

-(void)pageController:(NSPageController *)pageController prepareViewController:(NSViewController *)viewController withObject:(id)object {
    viewController.representedObject = object;
    // viewControllers may be reused... make sure to reset important stuff like the current magnification factor.
    
    // Normally, we want to reset the magnification value to 1 as the user swipes to other images. However if the user cancels the swipe, we want to leave the original magnificaiton and scroll position alone.
    
    /*BOOL isRepreparingOriginalView = (self.initialSelectedObject && self.initialSelectedObject == object) ? YES : NO;
    if (!isRepreparingOriginalView) {
        [(NSScrollView*)viewController.view setMagnification:1.0];
    }*/

}

- (void)pageControllerWillStartLiveTransition:(NSPageController *)pageController {
    // Remember the initial selected object so we can determine when a cancel occurred.
    //self.initialSelectedObject = [pageController.arrangedObjects objectAtIndex:pageController.selectedIndex];
}


- (void)pageController:(NSPageController *)pageController didTransitionToObject:(id)object
{
    NSLog(@"didTransitionToObject : %@", object);
}

- (void)pageControllerDidEndLiveTransition:(NSPageController *)aPageController {
    [aPageController completeTransition];
}



@end
