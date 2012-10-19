#import "FileUtils.h"
#import "Utils.h"
#import "SimpleProfiler.h"
#import "Preferences.h"


@implementation FileUtils


static FileUtils * instance = nil;

@synthesize destinationDirectory = mDestinationDirectory;


-(void)awakeFromNib
{
	instance				= self;
	mDestinationDirectory	= nil;
	mCutItems				= [[NSMutableArray alloc] init];
	mCopiedItems			= [[NSMutableArray alloc] init];
}

-(void)dealloc
{
	instance = nil;
	//[mCutItems release];
	//[mCopiedItems release];
	//[mDestinationDirectory release];
	//[super dealloc];
}

+(FileUtils *)instance
{
	return instance;
}

+(BOOL)isImage:(NSString *)path
{
	PROFILING_START(@"FileUtils - isImage");

	NSString * extension = [[path pathExtension] lowercaseString];
	if ([extension isEqualToString:@"jpg"] == YES ||
		[extension isEqualToString:@"jpeg"] == YES ||
		[extension isEqualToString:@"gif"] == YES ||
		[extension isEqualToString:@"png"] == YES ||
		[extension isEqualToString:@"psd"] == YES ||
		[extension isEqualToString:@"tiff"] == YES ||
		[extension isEqualToString:@"tif"] == YES ||
		[extension isEqualToString:@"dng"] == YES ||
		[extension isEqualToString:@"cr2"] == YES ||
		[extension isEqualToString:@"raw"] == YES ||
		[extension isEqualToString:@"pdf"] == YES)
	{
		PROFILING_STOP();
		return YES;
	}

	PROFILING_STOP();
	return NO;
}

+(BOOL)isGIF:(NSString *)path
{
	NSString * extension = [[path pathExtension] lowercaseString];
	return [extension isEqualToString:@"gif"];
}

-(void)removeItemAtPath:(NSString *)path
{
	// check the preferences to see if we need to use the recycled bin, or
	// permanently delete files
	BOOL permanently = [[Preferences instance] boolForKey:@"permanentlyDeleteFiles"];
	if (permanently == YES)
	{
		NSFileManager * fileManager = [NSFileManager defaultManager];
		[fileManager removeItemAtPath:path error:NULL];
	}
	else
	{
		NSInteger tag = 0;
		NSString * source = [path stringByDeletingLastPathComponent];
		NSArray * files = [NSArray arrayWithObject:[path lastPathComponent]];
		NSWorkspace * workspace = [NSWorkspace sharedWorkspace];
		[workspace performFileOperation:NSWorkspaceRecycleOperation
				   source:source
				   destination:nil
				   files:files
				   tag:&tag];
	}
}

/**
	Private method used to clear previously copied/cut items.
*/
-(void)clear
{
	[mCopiedItems removeAllObjects];
	[mCutItems removeAllObjects];
}

-(void)copyItems:(NSArray *)items
{
	[self clear];
	[mCopiedItems addObjectsFromArray:items];
	[self setCanPaste:YES];
}

-(void)cutItems:(NSArray *)items
{
	[self clear];
	[mCutItems addObjectsFromArray:items];
	[self setCanPaste:YES];
}

-(BOOL)canPaste
{
	if ([mCutItems count] > 0 || [mCopiedItems count] > 0)
		return YES;
	return NO;
}

-(void)setCanPaste:(BOOL)canPaste
{
	// this is just used for binding : when an item is added to the copy or
	// cut list, we call [self setCanPaste:whatever] to notify binded objects.
}

-(void)paste
{
	if (mDestinationDirectory != nil)
		[self pasteTo:mDestinationDirectory];
}

-(void)pasteTo:(NSString *)destination
{
	NSFileManager * fileManager = [NSFileManager defaultManager];

	// handle cut files
	for (NSURL * url in mCutItems)
	{
		// check if the destination folder is different from the source folder
		if ([destination isEqualToString:[[url path] stringByDeletingLastPathComponent]])
			continue;
	
		NSURL * destinationURL = [NSURL fileURLWithPath:destination];
		destinationURL = [destinationURL URLByAppendingPathComponent:[url lastPathComponent]];
		
		// little hack : if the destination already exists, moving wont work,
		// so I remove the destination before moving. This might be a bit
		// "unsafe", but I don't want to bloat the code for something that will
		// happen with a 0.000001% chance.
		[fileManager removeItemAtURL:destinationURL error:nil];
		[fileManager moveItemAtURL:url toURL:destinationURL error:nil];
	}

	// handle copied files
	for (NSURL * url in mCopiedItems)
	{
		// check if the destination folder is different from the source folder
		if ([destination isEqualToString:[[url path] stringByDeletingLastPathComponent]])
			continue;

		NSURL * destinationURL = [NSURL fileURLWithPath:destination];
		destinationURL = [destinationURL URLByAppendingPathComponent:[url lastPathComponent]];
		[fileManager copyItemAtURL:url toURL:destinationURL error:nil];
	}

	[self clear];
}

@end
