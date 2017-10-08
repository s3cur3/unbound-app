/*
     File: AutoSizingImageView.h 
 Abstract: Main image view properly sized within its scroll view.
  
  Version: 1.1 
  
 */

#import <Cocoa/Cocoa.h>

@class ImageViewController;

@interface AutoSizingImageView : NSImageView
{
    
}

@property (assign, nonatomic) id delegate;

@end
