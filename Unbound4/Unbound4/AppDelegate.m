//
//  AppDelegate.m
//  Unbound4
//
//  Created by Bob on 10/1/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "IKBBrowserItem.h"
#import "MainWindowController.h"
#import "FileSystemItem.h"

@interface  AppDelegate()
@property (nonatomic,strong) IBOutlet MainViewController *masterViewController;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self loadDataFromDefaults];
    self.mainWindowController = [[MainWindowController alloc] initWithWindow:self.window];
    self.window.delegate = self.mainWindowController;
    [self.mainWindowController showWindow:self];
}


/*-(void)switchToView:(NSView *)aView
{
    [self.window.contentView addSubview:self.masterViewController.view];
    aView.frame = ((NSView*)self.window.contentView).bounds;
}*/


+ (AppDelegate *) applicationDelegate
{
    return (AppDelegate *)[[NSApplication sharedApplication] delegate];
}

-(void) loadDataWithPath:(NSString *)path
{
    BOOL firstLoad = YES;
    if (path==nil)
    {
        //path = @"/Users/inzan/Dropbox/Camera Uploads";
        NSError *error = nil;
        NSURL *defaultURL = [[NSFileManager defaultManager] URLForDirectory:NSPicturesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:&error];
        if (defaultURL!=nil) {
            path = defaultURL.path;
        } else {
            NSLog(@"not able to find default pictures folder");
        }
    } else {
        firstLoad = NO;
    }
    
    //FileSystemItem *rootItem = [FileSystemItem rootItem];
    
    self.currentFilePath = path;
    self.subdirectoryArray = [[NSMutableArray alloc] init];
    self.imagesArray = [[NSMutableArray alloc] init];
    //self.importedImages = [[NSMutableArray alloc] init];
    
    NSURL *dirURL = [NSURL fileURLWithPath:path];//[[NSFileManager defaultManager] url];
    //NSURL *dirURL = [[NSFileManager defaultManager] URLForDirectory:NSPicturesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    //NSURL *dirURL = [[NSBundle mainBundle] resourceURL];
    
    // load all the necessary image files by enumerating through the bundle's Resources folder,
    // this will only load images of type "kUTTypeImage"
    //
    //self.data = [[NSMutableArray alloc] initWithCapacity:1];
    
    NSDirectoryEnumerator *itr = [[NSFileManager defaultManager] enumeratorAtURL:dirURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLLocalizedNameKey, NSURLEffectiveIconKey, NSURLIsDirectoryKey, NSURLTypeIdentifierKey, nil] options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants /*| NSDirectoryEnumerationSkipsSubdirectoryDescendants*/ errorHandler:nil];
    
    for (NSURL *url in itr) {
        NSString *utiValue;
        [url getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:nil];
        
        if (UTTypeConformsTo((__bridge CFStringRef)(utiValue), kUTTypeImage)) {
            NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
            IKBBrowserItem *anObject = [[IKBBrowserItem alloc] init];
            anObject.image = image;
            anObject.url = url;
            [self.imagesArray addObject:anObject];
        } else if (UTTypeConformsTo((__bridge CFStringRef)(utiValue), kUTTypeFolder)) {
            NSMutableDictionary *aSubDir = [[NSMutableDictionary alloc] init];
            //FileSystemItem anItem = [[[FileSystemItem alloc] init];
            [aSubDir setObject:[url lastPathComponent] forKey:@"Name"];
            NSImage *image = [NSImage imageNamed:@"NSFolder"];
            [aSubDir setObject:image forKey:@"Image"];
            [aSubDir setObject:url forKey:@"URL"];
            [self.subdirectoryArray addObject:aSubDir];
            NSLog(@"Adding subdir at url : %@", url.path);
        } else {
            NSLog(@"Skipping file at url : %@", url.path);
        }
    }
    
    // set the first image in our list to the main magnifying view
    if ([self.imagesArray count] > 0) {
        NSLog(@"Images loaded");
        //[self.pageController setArrangedObjects:self.data];
        //self.images = self.data;
        //[self.imageBrowser reloadData];
        //[self.imageBrowser setNeedsDisplay:YES];
        
    }
    if (!firstLoad) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UB_PATH_CHANGED" object:nil];
    }
}

-(void)loadDataFromDefaults
{
    //TODO: find dropbox folder
    [self loadDataWithPath:nil];
}

#pragma mark import images from file system

/* Code that parse a repository and add all items in an independant array,
 When done, call updateDatasource, add these items to our datasource array
 This code is performed in an independant thread.
 */
- (void)addAnImageWithPath:(NSURL *)aURL
{
    IKBBrowserItem *p;
    
	/* add a path to our temporary array */
    p = [[IKBBrowserItem alloc] init];
    p.url = aURL;
    [self.imagesArray addObject:p];
}

- (void)addImagesWithPath:(NSString *)path recursive:(BOOL)recursive
{
    NSInteger i, n;
    BOOL dir;
    
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir];
    
    if (dir)
    {
        NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        
        n = [content count];
        
		// parse the directory content
        for (i=0; i<n; i++)
        {
            if (recursive)
                [self addImagesWithPath:[path stringByAppendingPathComponent:[content objectAtIndex:i]] recursive:YES];
            else
                [self addAnImageWithPath:[path stringByAppendingPathComponent:[content objectAtIndex:i]]];
        }
    }
    else
    {
        [self addAnImageWithPath:path];
    }
}

/* performed in an independant thread, parse all paths in "paths" and add these paths in our temporary array */
- (void)addImagesWithPaths:(NSArray *)urls
{
    NSInteger i, n;
    
    n = [urls count];
    for ( i= 0; i < n; i++)
    {
        NSURL *url = [urls objectAtIndex:i];
        [self addImagesWithPath:[url path] recursive:NO];
    }
    
	/* update the datasource in the main thread */
    [self performSelectorOnMainThread:@selector(updateDatasource) withObject:nil waitUntilDone:YES];

}


#pragma mark -

@end
