//
//  PIXMiniExifViewController.m
//  UnboundApp
//
//  Created by Scott Sykora on 2/25/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXMiniExifViewController.h"
#import "PIXPhoto.h"

@interface PIXMiniExifViewController ()

@property (weak) IBOutlet NSTextField * photoName;
@property (weak) IBOutlet NSTextField * dateTaken;

@end

@implementation PIXMiniExifViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)setPhoto:(PIXPhoto *)photo
{
    _photo = photo;
    
    [self.photoName setStringValue:[self.photo name]];
    
    NSDateFormatter * dateFormatter = [NSDateFormatter new];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    NSString * dateString = nil;
    if([self.photo dateTaken])
    {
        dateString = [dateFormatter stringFromDate:[self.photo dateTaken]];
    }
    
    else if([self.photo dateCreated])
    {
        dateString = [dateFormatter stringFromDate:[self.photo dateCreated]];
    }
    
    [self.dateTaken setStringValue:dateString];
}

@end
