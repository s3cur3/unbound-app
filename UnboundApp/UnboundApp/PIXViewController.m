//
//  PIXViewController.m
//  UnboundApp
//
//  Created by Bob on 12/14/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXViewController.h"
#import "PIXNavigationController.h"
#import "PIXPhoto.h"
#import "PIXAlbum.h"
#import "PIXMiniExifViewController.h"
#import "PIXFileManager.h"
#import "PIXCNAlbumViewController.h"

@interface PIXViewController ()

@end

@implementation PIXViewController

+(BOOL)optionKeyIsPressed
{
    if(( [NSEvent modifierFlags] & NSAlternateKeyMask ) != 0 ) {
        return YES;
    } else {
        return NO;
    }
    
}

-(NSMenu *)menuForObjects:(NSArray *)objects selectedObject:(id)selectdObject
{
    id object = [objects lastObject];
    NSCParameterAssert(object);
    NSMenu*  menu = nil;
    
    menu = [[NSMenu alloc] initWithTitle:@"menu"];
    [menu setAutoenablesItems:NO];
    
    
    // only show the mini exif view on photos
    if([object isKindOfClass:[PIXPhoto class]])
    {
        NSMenuItem * miniExifDisplay = [[NSMenuItem alloc] init];
        
        PIXMiniExifViewController * exifVC = [[PIXMiniExifViewController alloc] initWithNibName:@"PIXMiniExifViewController" bundle:nil];
        
        exifVC.photo = object;
        
        miniExifDisplay.view = exifVC.view;
        
        [miniExifDisplay.view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        
        [menu addItem:miniExifDisplay];
    }
    
    // Get Info
    //TODO: pop up message if multiple items selected for these actions
    [menu addItemWithTitle:[NSString stringWithFormat:@"Get Info"] action:
     @selector(getInfo:) keyEquivalent:@""];
    
    // Show in Finder
    [menu addItemWithTitle:[NSString stringWithFormat:@"Show In Finder"] action:
     @selector(revealInFinder:) keyEquivalent:@""];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    // only show open with options on Photo objects
    if([object isKindOfClass:[PIXPhoto class]])
    {
        
        
        // Open with Defualt
        NSString *defaultAppName = [[PIXFileManager sharedInstance] defaultAppNameForOpeningFileWithPath:[object path]];
        if (defaultAppName!=nil && ([defaultAppName isEqualToString:@"Finder"]==NO)) {
            [menu addItemWithTitle:[NSString stringWithFormat:@"Open with %@", defaultAppName] action:
             @selector(openInApp:) keyEquivalent:@""];
        }
        
        // Open with Others
        NSArray *filePaths = [objects valueForKey:@"path"];
        NSMenu *openWithMenu = [[PIXFileManager sharedInstance] openWithMenuItemForFiles:filePaths];
        NSMenuItem *openWithMenuItem = [[NSMenuItem alloc] init];
        [openWithMenuItem setTitle:@"Open With"];
        [openWithMenuItem setSubmenu:openWithMenu];
        [menu addItem:openWithMenuItem];
        
        [menu addItem:[NSMenuItem separatorItem]];
    }
    
    // Selection Options
    if (objects.count >1 && [self isKindOfClass:[PIXCNAlbumViewController class]]) {
        [menu addItemWithTitle:[NSString stringWithFormat:@"Select All"] action:
         @selector(selectAll:) keyEquivalent:@""];
        [menu addItemWithTitle:[NSString stringWithFormat:@"Select None"] action:
         @selector(selectNone:) keyEquivalent:@""];
    
        [menu addItem:[NSMenuItem separatorItem]];
    }
    
    NSString * deleteString = @"Delete";
    
    if([object isKindOfClass:[PIXPhoto class]])
    {
        if([objects count] > 1)
        {
            deleteString = [NSString stringWithFormat:@"Delete %ld Photos", [objects count]];
        }
        
        else
        {
            deleteString = @"Delete Photo";
        }
    }
    
    else if([object isKindOfClass:[PIXAlbum class]])
    {
        if([objects count] > 1)
        {
            deleteString = [NSString stringWithFormat:@"Delete %ld Albums", [objects count]];
        }
        
        else
        {
            deleteString = @"Delete Album";
        }
    }
    
    
    
    [menu addItemWithTitle:deleteString action:@selector(deleteItems:) keyEquivalent:@""];
    
    for (NSMenuItem * anItem in [menu itemArray])
    {
        [anItem setRepresentedObject:object];
        [anItem setTarget:self];
    }
    
    //menu.delegate = self;
    
    
    //NSMenu *openWithMenu = [[PIXFileManager sharedInstance] openWithMenuItemForFile:[object path]];
    
    return menu;
}

-(NSMenu *)menuForObject:(id)object;
{
    return [self menuForObjects:[NSArray arrayWithObject:object] selectedObject:object];
//    NSMenu*  menu = nil;
//    
//    menu = [[NSMenu alloc] initWithTitle:@"menu"];
//    [menu setAutoenablesItems:NO];
//    
//    
//    // only show the mini exif view on photos
//    if([object isKindOfClass:[PIXPhoto class]])
//    {
//        NSMenuItem * miniExifDisplay = [[NSMenuItem alloc] init];
//        
//        PIXMiniExifViewController * exifVC = [[PIXMiniExifViewController alloc] initWithNibName:@"PIXMiniExifViewController" bundle:nil];
//        
//        exifVC.photo = object;
//        
//        miniExifDisplay.view = exifVC.view;
//        
//        [miniExifDisplay.view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
//        
//        [menu addItem:miniExifDisplay];
//    }
//    
//    // Get Info
//    //TODO: pop up message if multiple items selected for these actions
//    [menu addItemWithTitle:[NSString stringWithFormat:@"Get Info"] action:
//     @selector(getInfo:) keyEquivalent:@""];
//    
//    // Show in Finder
//    [menu addItemWithTitle:[NSString stringWithFormat:@"Show In Finder"] action:
//     @selector(revealInFinder:) keyEquivalent:@""];
//    
//    for (NSMenuItem * anItem in [menu itemArray])
//    {
//        [anItem setRepresentedObject:object];
//        [anItem setTarget:self];
//    }
//    
//    return menu;
    
    //[menu addItem:[NSMenuItem separatorItem]];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)setupToolbar
{
    NSArray * items = @[self.navigationViewController.backButton];
    
    [self.navigationViewController setToolbarItems:items];
     
}

-(void)willShowPIXView
{
    
}

-(void)willHidePIXView
{
    
} 

@end
