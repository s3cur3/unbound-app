#import <Foundation/Foundation.h>


/**
	Provides utilities for preferences, such as registering defaults, resetting,
	bind, etc.
*/
@interface Preferences
	: NSObject
{
}

+(Preferences *)instance;
+(void)destroy;
-(id)init;

-(void)resetToDefaults;
-(void)bind:(NSObject *)src
	   key:(NSString *)srcKey
	   to:(NSString *)destKey
	   withUnarchiver:(BOOL)unarchiver;
-(BOOL)boolForKey:(NSString *)key;
-(NSString *)stringForKey:(NSString *)key;
-(void)setString:(NSString *)value forKey:(NSString *)key;

@end
