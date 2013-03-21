//
//  PIXCustomShareSheetViewController.m
//  UnboundApp
//
//  Created by Scott Sykora on 2/14/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXCustomShareSheetViewController.h"

#import "PIXPhoto.h"
#import "PIXAlbum.h"

#import "PIXShareManager.h"

@interface PIXCustomShareSheetViewController ()

@property (strong) NSArray * itemsToShare;
@property BOOL itemsAreAlbums; // if YES they are albums, if NO they are photos

@property (weak) IBOutlet NSTextField * titleLabel;
@property (weak) IBOutlet NSView * buttonHolder;
@property (weak) IBOutlet NSLayoutConstraint * buttonHolderHeight;

@end

@implementation PIXCustomShareSheetViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


-(void)setPhotosToShare:(NSArray *)photos
{
    [self view]; // make sure the nib has been loaded
    
    self.itemsToShare = [photos copy];
    self.itemsAreAlbums = NO;
    
    
    if([photos count] == 1)
    {
        self.titleLabel.stringValue = @"Share Photo";
        
        NSButton * emailButton = [NSButton new];
        emailButton.image = [NSImage imageNamed:@"buttongrid_email"];
        emailButton.title = @"Email";
        emailButton.target = self;
        emailButton.action = @selector(emailItems:);
        
        NSButton * copyButton = [NSButton new];
        copyButton.image = [NSImage imageNamed:@"buttongrid_copy"];
        copyButton.title = @"Copy";
        copyButton.target = self;
        copyButton.action = @selector(copyItems:);
        
        NSButton * exportButton = [NSButton new];
        exportButton.image = [NSImage imageNamed:@"buttongrid_share"];
        exportButton.title = @"Export";
        exportButton.target = self;
        exportButton.action = @selector(exportItems:);
        
        NSButton * tweetButton = [NSButton new];
        tweetButton.image = [NSImage imageNamed:@"buttongrid_twitter"];
        tweetButton.title = @"Tweet";
        tweetButton.target = self;
        tweetButton.action = @selector(tweetItems:);
        
        
        [self setButtons:@[emailButton, copyButton, exportButton, tweetButton]];
    }
    
    else
    {
        self.titleLabel.stringValue = [NSString stringWithFormat:@"Share %ld Photos", [photos count]];
        
        NSButton * emailButton = [NSButton new];
        emailButton.image = [NSImage imageNamed:@"buttongrid_email"];
        emailButton.title = @"Email";
        emailButton.target = self;
        emailButton.action = @selector(emailItems:);
        
        NSButton * copyButton = [NSButton new];
        copyButton.image = [NSImage imageNamed:@"buttongrid_copy"];
        copyButton.title = @"Copy";
        copyButton.target = self;
        copyButton.action = @selector(copyItems:);
        
        NSButton * exportButton = [NSButton new];
        exportButton.image = [NSImage imageNamed:@"buttongrid_share"];
        exportButton.title = @"Export";
        exportButton.target = self;
        exportButton.action = @selector(exportItems:);
        
        [self setButtons:@[emailButton, copyButton, exportButton]];
    }
    
}

-(void)setAlbumsToShare:(NSArray *)albums
{
    [self view]; // make sure the nib has been loaded
    
    self.itemsToShare = [albums copy];
    self.itemsAreAlbums = YES;
    

    if([albums count] == 1)
    {
        self.titleLabel.stringValue = @"Share Album";
        
        NSButton * emailButton = [NSButton new];
        emailButton.image = [NSImage imageNamed:@"buttongrid_emaillink"];
        emailButton.title = @"Email Link";
        emailButton.target = self;
        emailButton.action = @selector(emailItems:);
        
        NSButton * copyButton = [NSButton new];
        copyButton.image = [NSImage imageNamed:@"buttongrid_copy"];
        copyButton.title = @"Copy";
        copyButton.target = self;
        copyButton.action = @selector(copyItems:);
        
        NSButton * exportButton = [NSButton new];
        exportButton.image = [NSImage imageNamed:@"buttongrid_share"];
        exportButton.title = @"Export";
        exportButton.target = self;
        exportButton.action = @selector(exportItems:);
        
        [self setButtons:@[emailButton, copyButton, exportButton]];
    }
    
    else
    {
        self.titleLabel.stringValue = [NSString stringWithFormat:@"Share %ld Albums", [albums count]];
        
        NSButton * emailButton = [NSButton new];
        emailButton.image = [NSImage imageNamed:@"buttongrid_emaillink"];
        emailButton.title = @"Email Links";
        emailButton.target = self;
        emailButton.action = @selector(emailItems:);
        
        NSButton * copyButton = [NSButton new];
        copyButton.image = [NSImage imageNamed:@"buttongrid_copy"];
        copyButton.title = @"Copy";
        copyButton.target = self;
        copyButton.action = @selector(copyItems:);
        
        NSButton * exportButton = [NSButton new];
        exportButton.image = [NSImage imageNamed:@"buttongrid_share"];
        exportButton.title = @"Export";
        exportButton.target = self;
        exportButton.action = @selector(exportItems:);
        
        [self setButtons:@[emailButton, copyButton, exportButton]];
    }
}

-(void)setButtons:(NSArray *)buttons
{
    int i = 0;
    int buttonWidth = 90;
    int buttonHeight = 90;
    
    float viewHeight = (((buttons.count-1)/3)*buttonHeight)+buttonHeight;
    [self.buttonHolderHeight setConstant:viewHeight];
    
    for(NSButton * aButton in buttons)
    {
        aButton.font = [NSFont fontWithName:@"Helvetica Neue" size:12];
        aButton.imagePosition = NSImageAbove;
        [aButton setButtonType:NSMomentaryChangeButton];
        [aButton setBordered:NO];
        
        CGRect outerFrame = CGRectMake((i%3)*buttonWidth, viewHeight - (((i/3)+1) * buttonHeight), buttonWidth, buttonHeight);
        
        [aButton setFrame:CGRectInset(outerFrame, 10, 10)];
        
        [self.buttonHolder addSubview:aButton];
        i++;
    }
    
    
}


-(void)emailItems:(id)sender
{
    //[[PIXShareManager defaultShareManager] emailPhotos:self.itemsToShare];
}

-(void)copyItems:(id)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Not yet Implemented"];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

-(void)exportItems:(id)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Not yet Implemented"];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

-(void)tweetItems:(id)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Not yet Implemented"];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}


@end
