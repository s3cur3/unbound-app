#import <Quartz/Quartz.h>


@class ImageItem;


/**
	Image browser view. Displays thumbnails of the images contained in a single
	folder. Fullscreen is binded to the image view, and it implements the
	CutCopy protocol.
*/
@interface ImageBrowser
	: IKImageBrowserView
{
}

-(void)awakeFromNib;
-(void)reloadData;
-(void)reloadDataAndKeepSelection;

// utils
-(BOOL)setFullscreen;
-(void)deleteSelectedImages;
-(void)cutSelectedImages;
-(void)copySelectedImages;
-(IBAction)selectAll:(id)sender;
-(IBAction)deselectAll:(id)sender;
-(void)setSelectedImage:(NSString *)image;
-(ImageItem *)itemAtIndex:(NSUInteger)index;
-(NSArray *)selectedImagesAsURLArray;

// used by the slide show timer
-(void)selectNextImage:(NSTimer *)timer;

// for binding
-(BOOL)showTitles;
-(void)setShowTitles:(BOOL)showTitles;
-(float)thumbnailMargin;
-(void)setThumbnailMargin:(BOOL)margin;

// event methods
-(void)keyDown:(NSEvent *)theEvent;
-(void)otherMouseDown:(NSEvent *)theEvent;

@end
