#import "Preferences.h"
//#import "../Utils/Utils.h"


@implementation Preferences

static Preferences * instance = nil;

+(Preferences *)instance
{
	if (instance == nil)
		instance = [[Preferences alloc] init];
	return instance;
}

+(void)destroy
{
	//[instance release];
	instance = nil;
}

-(id)init
{
	self = [super init];
	if (self == nil)
		return nil;

	// initialize the default parameters for the application
	// first step : create objects for complex parameters
	NSData * colorData = [NSKeyedArchiver archivedDataWithRootObject:[NSColor blackColor]];

	// second step : create the dictionary containing the parameters' keys and values
	NSMutableDictionary * defaults = [NSMutableDictionary dictionary];
	[defaults setValue:colorData forKey:@"backgroundColor"];
	[defaults setValue:[NSNumber numberWithFloat:0.38f] forKey:@"thumbnailSize"];
	[defaults setValue:[NSNumber numberWithFloat:8.0f] forKey:@"thumbnailMargin"];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:@"showTitles"];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:@"permanentlyDeleteFiles"];
	[defaults setValue:[NSNumber numberWithFloat:3.0f] forKey:@"slideshowInterval"];
	[defaults setValue:[NSNumber numberWithBool:YES] forKey:@"slideshowLoop"];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:@"showHardDrive"];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:@"startInLastVisitedFolder"];
	[defaults setValue:@"" forKey:@"lastFolder"];

	// last step : register the default parameters
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

	// now, register which options can be resetted
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaults];
	
	return self;
}

-(void)bind:(NSObject *)src
	   key:(NSString *)srcKey
	   to:(NSString *)destKey
	   withUnarchiver:(BOOL)unarchiver
{
	if (unarchiver == YES)
	{
		[src bind:srcKey
			 toObject:[NSUserDefaultsController sharedUserDefaultsController]
			 withKeyPath:[NSString stringWithFormat:@"values.%@", destKey]
			 options:[NSDictionary dictionaryWithObjectsAndKeys:NSKeyedUnarchiveFromDataTransformerName,
																NSValueTransformerNameBindingOption,
																[NSNumber numberWithBool:YES],
																NSContinuouslyUpdatesValueBindingOption,
																nil]];
	}
	else
	{
		[src bind:srcKey
			 toObject:[NSUserDefaultsController sharedUserDefaultsController]
			 withKeyPath:[NSString stringWithFormat:@"values.%@", destKey]
			 options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],
																NSContinuouslyUpdatesValueBindingOption,
																nil]];
	}
}

-(void)resetToDefaults
{
	[[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:nil];
    NSURL *url = nil;
    [[NSUserDefaults standardUserDefaults] setValue:url forKey:@"searchLocationKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)boolForKey:(NSString *)key
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

-(NSString *)stringForKey:(NSString *)key
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:key];
}

-(void)setString:(NSString *)value forKey:(NSString *)key
{
	return [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
}

@end
