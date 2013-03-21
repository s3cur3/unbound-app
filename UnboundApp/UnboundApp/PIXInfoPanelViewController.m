//
//  PIXInfoPanelViewController.m
//  UnboundApp
//
//  Created by Scott Sykora on 3/21/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXInfoPanelViewController.h"
#import <MapKit/MapKit.h>
#import "PIXPhoto.h"

@interface PIXInfoPanelViewController () <MKMapViewDelegate>

@property (weak) IBOutlet NSTextField * photoName;
@property (weak) IBOutlet NSTextField * dateTaken;
@property (weak) IBOutlet NSTextField * cameraModel;
@property (weak) IBOutlet NSTextField * resolution;
@property (weak) IBOutlet NSTextField * filesize;

@property (weak) IBOutlet MKMapView * mapView;

@end

@implementation PIXInfoPanelViewController

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
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"MapViewAdditions" ofType:@"css"];
    [self.mapView addStylesheetTag:path];
}

-(void)setPhoto:(PIXPhoto *)photo
{
    _photo = photo;
    
    [self updateLabels];
    [self updateMap];
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
    
    if(modelString == nil)
    {
        modelString = @"";
    }
    self.cameraModel.stringValue = modelString;
    
    [self.view setNeedsUpdateConstraints:YES];
    DLog(@"%@", self.photo);
}

-(void)updateMap
{
    if([[self.photo latitude] doubleValue] == 0 || [[self.photo longitude] doubleValue] == 0)
    {
        [self.mapView setHidden:YES];
    }
    
    else
    {
        [self.mapView setHidden:NO];
        MKCoordinateRegion region;
        
        region.center = [self.photo coordinate];
        region.span.latitudeDelta = 0.0;
        region.span.longitudeDelta = 0.0;
        
        // fix the region so it has the same aspect ratio as the view
        CGFloat viewAspectRatio = self.mapView.frame.size.width / self.mapView.frame.size.height;
        
        if(viewAspectRatio < 1)
        {
            region.span.latitudeDelta = region.span.latitudeDelta * viewAspectRatio;
        }
        
        else
        {
            region.span.longitudeDelta = region.span.longitudeDelta * (1.0/viewAspectRatio);
        }
        
        
        //[self.mapView setRegion:region animated:YES];
        
        
        [self.mapView removeAnnotations:self.mapView.annotations];
        [self.mapView addAnnotation:self.photo];
        
        [self.mapView setCenterCoordinate:[self.photo coordinate] animated:YES];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    //NSLog(@"mapView: %@ viewForAnnotation: %@", aMapView, annotation);
    //MKAnnotationView *view = [[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"blah"] autorelease];
    MKPinAnnotationView *view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"blah"];
    view.draggable = NO;
    view.animatesDrop = YES;
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"MarkerTest" ofType:@"png"];
    //NSURL *url = [NSURL fileURLWithPath:path];
    //view.imageUrl = [url absoluteString];
    return view;
}

@end
