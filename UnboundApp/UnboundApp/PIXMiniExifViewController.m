//
//  PIXMiniExifViewController.m
//  UnboundApp
//
//  Created by Scott Sykora on 2/25/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXMiniExifViewController.h"
#import "PIXPhoto.h"

@interface PIXMiniExifViewController () <NSTextFieldDelegate>

@property (weak) IBOutlet NSTextField * photoName;
@property (weak) IBOutlet NSTextField * dateTaken;
@property (weak) IBOutlet NSTextField * cameraModel;
@property (weak) IBOutlet NSTextField * resolution;
@property (weak) IBOutlet NSTextField * filesize;

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

-(void)awakeFromNib
{
    [self updateLabels];
}

-(void)setPhoto:(PIXPhoto *)photo
{
    _photo = photo;
    
    [self updateLabels];
}

-(void)updateLabels
{    
    NSString * nameString = [self.photo name];
    
    if(nameString == nil) nameString = @"";
        
    [self.photoName setStringValue:nameString];
    
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
    
    if(dateString == nil) dateString = @"";
    [self.dateTaken setStringValue:dateString];
    
    NSString * resolutionString = nil;
    NSString * pixelHeight = [[self.photo exifData] objectForKey:@"PixelHeight"];
    NSString * pixelWidth = [[self.photo exifData] objectForKey:@"PixelWidth"];
    
    if(pixelHeight && pixelWidth)
    {
        resolutionString = [NSString stringWithFormat:@"%@ x %@", pixelWidth, pixelHeight];
    }
    
    if(resolutionString == nil) resolutionString = @"";
    self.resolution.stringValue = resolutionString;
    
    NSUInteger * byteCount = [[self.photo fileSize] unsignedIntegerValue];
    
    NSString * sizeString = nil;
    if(byteCount)
    {
        sizeString = [NSByteCountFormatter stringFromByteCount:byteCount countStyle:NSByteCountFormatterCountStyleFile];
    }
    
    if(sizeString == nil) sizeString = @"";
    self.filesize.stringValue = sizeString;
    
    
    NSString * modelString = [[[self.photo exifData] objectForKey:@"{TIFF}"] objectForKey:@"Model"];
    
    if(modelString == nil) modelString = @"";
    self.cameraModel.stringValue = modelString;
    
    [self.view setNeedsUpdateConstraints:YES];
    DLog(@"%@", [self.photo exifData]);
}

-(void)controlTextDidChange:(NSNotification*)aNotification
{
    
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
    [self.photoName setBezelStyle:NSTextFieldSquareBezel];
    return YES;
    
}

@end
