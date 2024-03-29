//
//  PIXInfoPanelViewController.m
//  UnboundApp
//
//  Created by Scott Sykora on 3/21/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXInfoPanelViewController.h"

#import "PIXPhoto.h"
#import "PIXPageViewController.h"
#import "PIXFileManager.h"
#import "PIXDefines.h"

NSString * formatByteCount(NSUInteger byteCount);

@interface PIXInfoPanelViewController () <MKMapViewDelegate, NSTextFieldDelegate>

@property (weak) IBOutlet NSTextField * photoName;
@property (weak) IBOutlet NSTextField * dateTaken;
@property (weak) IBOutlet NSTextField * cameraModel;
@property (weak) IBOutlet NSTextField * resolution;
@property (weak) IBOutlet NSTextField * filesize;

@property (weak) IBOutlet NSLayoutConstraint * exifHeight;

@property (weak) IBOutlet MKMapView * mapView;

@property (strong) NSMutableArray * exifStringArray;

-(void)updateMap;
-(BOOL)showMoreExif;
-(void)setShowMoreExif:(BOOL)newValue;

@end

@implementation PIXInfoPanelViewController {
    NSDictionary *_exifData;
}

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
    [self updateMap];
    
    [self.mapView setDelegate:self];
    
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"MapViewAdditions" ofType:@"css"];
    //[self.mapView addStylesheetTag:path];
}

-(void)setPhoto:(PIXPhoto *)photo
{
    if(_photo != photo)
    {    
        _photo = photo;
        
        [self updateLabels];
        [self updateMap];
        if([self showMoreExif])
        {
            [self convertAndRefreshExif];
        }
        [self setShowMoreExif:[self showMoreExif]];
    }
}

-(BOOL)showMoreExif
{
    return [NSUserDefaults.standardUserDefaults boolForKey:kPrefShowMoreExifInfo];
}

-(void)setShowMoreExif:(BOOL)shouldShow
{
    [NSUserDefaults.standardUserDefaults setBool:shouldShow forKey:kPrefShowMoreExifInfo];
    if(shouldShow)
    {
        [self.exifHeight.animator setConstant:92];
        self.moreExifButton.title = @"More ▾";
        [self.exifScrollView removeFromSuperview];
    }
    else
    {
        [self.exifHeight.animator setConstant:500];
        self.moreExifButton.title = @"Less ▴";

        [self convertAndRefreshExif];

        // add the scroll view to the exif view
        [self.exifHolder addSubview:self.exifScrollView];
        [self.exifScrollView setTranslatesAutoresizingMaskIntoConstraints:NO];

        NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_exifScrollView);
        NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-8-[_exifScrollView]-0-|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:viewsDictionary];
        NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-92-[_exifScrollView]-8-|"
                                                                               options:0
                                                                               metrics:nil
                                                                                 views:viewsDictionary];

        [self.exifHolder addConstraints:horizontalConstraints];
        [self.exifHolder addConstraints:verticalConstraints];
    }
}

NSString * formatByteCount(NSUInteger byteCount)
{
    return byteCount ?
           [NSByteCountFormatter stringFromByteCount:(long long)byteCount countStyle:NSByteCountFormatterCountStyleFile] :
           @"";
}

-(void)updateLabels
{
    BOOL useVideoLabels = [self.photo isVideo];
    NSDictionary *videoAttributes = nil;
    if (useVideoLabels) {
        videoAttributes = [self.photo videoAttributes];
        NSString *name = videoAttributes[@"Name"];
        if (name) {
            self.photoName.stringValue = name;
        }
        
        self.filesize.stringValue = formatByteCount([videoAttributes[@"Size"] unsignedIntegerValue]);
        
        NSString *dateString = videoAttributes[@"Created"];
        if (dateString) {
            self.dateTaken.stringValue = dateString;
        }
        
        NSString *duration = videoAttributes[@"Duration"];
        if (duration) {
            self.cameraModel.stringValue = duration;
        }
    } else {
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
        NSString * pixelHeight = self.photo.exifData[@"PixelHeight"];
        NSString * pixelWidth = self.photo.exifData[@"PixelWidth"];
        
        if(pixelHeight && pixelWidth)
        {
            resolutionString = [NSString stringWithFormat:@"%@ x %@", pixelWidth, pixelHeight];
        }
        
        if(resolutionString == nil) resolutionString = @"";
        self.resolution.stringValue = resolutionString;

        self.filesize.stringValue = formatByteCount([[self.photo fileSize] unsignedIntegerValue]);

        NSString * modelString = [[[self.photo exifData] objectForKey:@"{TIFF}"] objectForKey:@"Model"];
        if(modelString == nil)
        {
            modelString = @"";
        }
        self.cameraModel.stringValue = modelString;
        
    }
    
    [self.view setNeedsUpdateConstraints:YES];
    //DLog(@"%@", self.photo);
}

-(void)updateMap
{
    if([[self.photo latitude] doubleValue] == 0 || [[self.photo longitude] doubleValue] == 0) {
        self.mapView.animator.hidden = YES;
    } else {
        self.mapView.animator.hidden = NO;

        [self.mapView removeAnnotations:self.mapView.annotations];
        [self.mapView addAnnotation:self.photo];
        [self.mapView setRegion:MKCoordinateRegionMake([self.photo coordinate], MKCoordinateSpanMake(1.0, 1.0)) animated:YES];
//        self.mapView.showsZoomControls = YES;
    }
}

-(void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    
    //[self updateMap];
}

- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    NSString *identifier = @"Pin";
    MKPinAnnotationView *view = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    if (view == nil) {
        view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        view.animatesDrop = YES;
    } else {
        view.annotation = annotation;
    }
    return view;
}

-(void)mouseDown:(NSEvent *)theEvent
{
    // grab the first responder on mouse down
    [self.view.window makeFirstResponder:self];
    [super mouseDown:theEvent];
}


-(BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    // seem to need to handl
    if (commandSelector == @selector(cancelOperation:)) {
        // reset the filename so we don't edit it
        [self.photoName setStringValue:self.photo.name];
        [self fileNameAction:nil];
        return YES;
    }
    
    return NO;
}


-(IBAction)fileNameAction:(id)sender
{
    if(![[self.photoName stringValue] isEqualToString:self.photo.name])
    {
        [[PIXFileManager sharedInstance] renamePhoto:self.photo withName:[self.photoName stringValue]];
        
        [self.photoName setStringValue:self.photo.name];
    }
    
    // get rid of the first responder status
    [self.view.window makeFirstResponder:self.pageView.view];
}

-(void)dealloc
{
    [self.mapView setDelegate:nil];
}

-(IBAction)moreExifAction:(id)sender
{
    [self setShowMoreExif:![self showMoreExif]];
}

-(void)convertAndRefreshExif
{
    if ([self.photo isVideo]) {
        self.exifStringArray = [self exifDictToStringArray:[self.photo videoAttributes]];
    } else {
        self.exifStringArray = [self exifDictToStringArray:self.photo.exifData];
    }
    
    
    [self.exifTableView reloadData];
}

-(NSMutableArray *)exifDictToStringArray:(NSDictionary *)inputDict
{
    NSMutableArray * outputArray = [NSMutableArray new];
    
    [inputDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            
            if([(NSDictionary *)obj count] > 0)
            {
                // trip {}'s from exif section titles
                NSString * sectionTitle = (NSString * )key;
                
                if([sectionTitle hasPrefix:@"{"])
                {
                    sectionTitle = [sectionTitle substringFromIndex:1];
                }
                
                if([sectionTitle hasSuffix:@"}"])
                {
                    sectionTitle = [sectionTitle substringToIndex:[sectionTitle length]-1];
                }
                
                
                [outputArray addObject:@{@"left": sectionTitle}];
                
                // recursively traverse section
                [outputArray addObjectsFromArray:[self exifDictToStringArray:(NSDictionary *)obj]];
            }
        }
        else if ([obj isKindOfClass:[NSString class]])
        {
            [outputArray addObject:@{@"right": obj, @"left": [NSString stringWithFormat:@" %@",key]}];
        } else if ([obj respondsToSelector:@selector(stringValue)])
        {
            [outputArray addObject:@{@"right": [obj stringValue], @"left": [NSString stringWithFormat:@" %@",key]}];
        }
    }];
        
    return outputArray;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    [aTableView setDelegate:self];
    
    NSInteger count = [self.exifStringArray count];
    return count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(rowIndex < [self.exifStringArray count])
    {
        NSDictionary * rowDict = [self.exifStringArray objectAtIndex:rowIndex];
        
        NSString * exifString = [rowDict objectForKey:aTableColumn.identifier];
        return exifString;
        
        
    }

    return @"";
}


-(void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    // Maybe a test on the table column is recommanded if some cells should not be modified

    NSDictionary * rowDict = [self.exifStringArray objectAtIndex:rowIndex];
    
    if ([rowDict objectForKey:@"right"]) {
        [aCell setFont:[NSFont fontWithName:@"Helvetica" size:10]];
    } else {
        [aCell setFont:[NSFont fontWithName:@"Helvetica bold" size:11]];
    }
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    // Grab the fully prepared cell with our content filled in. Note that in IB the cell's Layout is set to Wraps.
    NSCell *cell = [self.exifTableView preparedCellAtColumn:1 row:row];
    
    // See how tall it naturally would want to be if given a restricted width, but unbound height
    CGFloat theWidth = [(NSTableColumn *)[[self.exifTableView tableColumns] objectAtIndex:1] width];
    NSRect constrainedBounds = NSMakeRect(0, 0, theWidth, CGFLOAT_MAX);
    NSSize naturalSize = [cell cellSizeForBounds:constrainedBounds];
    
    // compute and return row height
    CGFloat result;
    // Make sure we have a minimum height -- use the table's set height as the minimum.
    if (naturalSize.height > [self.exifTableView rowHeight]) {
        result = naturalSize.height;
    } else {
        result = [self.exifTableView rowHeight];
    }
    return result;
}



@end
