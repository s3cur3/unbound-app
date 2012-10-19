#import <Cocoa/Cocoa.h>


/**
	This class is responsible for interacting with the filesystem. It's meant
	to be instanciated through a XIB file (I use awakFromNib to initialize it)
*/
@interface FileUtils
	: NSObject
{

@private

	NSMutableArray *	mCutItems;
	NSMutableArray *	mCopiedItems;
	NSString *			mDestinationDirectory;

}

@property (copy) NSString *	destinationDirectory;

// init / deinit
-(void)awakeFromNib;
-(void)dealloc;

// global accessor
+(FileUtils *)instance;

// misc
+(BOOL)isImage:(NSString *)path;
+(BOOL)isGIF:(NSString *)path;

// delete / copy-cut / paste support
-(void)removeItemAtPath:(NSString *)path;
-(void)copyItems:(NSArray *)items;
-(void)cutItems:(NSArray *)items;
-(void)paste;
-(void)pasteTo:(NSString *)destination;
-(BOOL)canPaste;
-(void)setCanPaste:(BOOL)canPaste;

@end
