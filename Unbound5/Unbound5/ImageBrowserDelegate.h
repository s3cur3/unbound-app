#import <Cocoa/Cocoa.h>


@class IKImageBrowserView;
@class ImageBrowserView;


@interface ImageBrowserDelegate
	: NSObject
{

@private

	NSString *		mSelectedImage;
	ImageBrowserView *	mImageBrowser;
	BOOL			mIgnoreSelectionChanges;

}

@property BOOL								ignoreSelectionChanges;
@property BOOL								fullscreen;
@property (assign) IBOutlet ImageBrowserView *	imageBrowser;

-(id)init;

// used to bind the image view and the image browser view
-(NSString *)selectedImage;
-(void)setSelectedImage:(NSString *)image;

// implementation of IKImageBrowserDelegate protocol
-(void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser;
-(void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index;
-(NSUInteger)imageBrowser:(IKImageBrowserView *)aBrowser writeItemsAtIndexes:(NSIndexSet *)itemIndexes toPasteboard:(NSPasteboard *)pasteboard;

@end
