#import "Preferences.h"
//#import "../Utils/Utils.h"

#import "PIXDefines.h"
#import "PIXAlbum.h"


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

	// second step : create the dictionary containing the parameters' keys and values
	NSMutableDictionary * defaults = [NSMutableDictionary dictionary];

	// 0 for light, 1 for dark
	if(@available(macOS 10.14, *)) {
		BOOL wantDark = [[[NSApplication sharedApplication] effectiveAppearance] name] == NSAppearanceNameDarkAqua;
		[defaults setValue:[NSNumber numberWithInt:wantDark] forKey:@"backgroundTheme"];
	}

	defaults[kAppShowedCrashDialog] = @NO;
    [defaults setValue:@"Compact" forKey:kPrefPhotoStyle];

	[defaults setValue:[NSNumber numberWithFloat:0.38f] forKey:@"thumbnailSize"];
	
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:@"showTitles"];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:@"permanentlyDeleteFiles"];
	[defaults setValue:[NSNumber numberWithFloat:3.0f] forKey:kSlideshowTimeInterval];
	[defaults setValue:[NSNumber numberWithBool:YES] forKey:@"slideshowLoop"];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:@"showHardDrive"];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:@"startInLastVisitedFolder"];
    
	[defaults setValue:@"" forKey:@"lastFolder"];
    
    [defaults setValue:[NSNumber numberWithBool:YES] forKey:kAppFirstRun];
    
    [defaults setValue:[NSNumber numberWithBool:NO] forKey:kAppObservedDirectoryUnavailable];
    [defaults setValue:[NSNumber numberWithBool:NO] forKey:kAppObservedDirectoryUnavailableSupressAlert];
    
    [defaults setValue:[NSNumber numberWithInteger:PIXPhotoSortOldToNew] forKey:kPrefPhotoSortOrder];
    [defaults setValue:[NSNumber numberWithInteger:PIXAlbumSortAtoZ] forKey:kPrefAlbumSortOrder];
	
	[[NSUserDefaults standardUserDefaults] setFloat:300 forKey:@"albumSideBarToggleWidth"];

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
