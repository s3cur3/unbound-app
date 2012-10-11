#import <AppKit/AppKit.h>


@interface Utils
	: NSObject
{
}

+(void)bind:(id)src
	   keyPath:(NSString *)srcKey
	   to:(id)dest
	   keyPath:(id)destKey
	   continuous:(BOOL)continuous
	   twoWay:(BOOL)twoWay;
+(NSMutableParagraphStyle *)defaultParagraphStyle;
+(NSSize)stringSize:(NSString *)string withAttribute:(NSDictionary *)attributes;

@end


// Use this macro to output debug infos and strip them in release
#if defined(DEBUG)
#	define DEBUG_LOG(...) NSLog(__VA_ARGS__)
#else
#	define DEBUG_LOG(...)
#endif

// Use this macro to do something only in debug
#if defined(DEBUG)
#	define DEBUG_ONLY(args) args
#else
#	define DEBUG_ONLY(args)
#endif

// This macro is used when launching the ImageViewer from outside XCode :
// since we don't have access to the log, we need a way to debug
#if defined(DEBUG)
#	define DEBUG_ALERT(...) \
{ \
	NSAlert * __alert = [[[NSAlert alloc] init] autorelease]; \
	[__alert setMessageText:[NSString stringWithFormat:__VA_ARGS__]]; \
	[__alert runModal]; \
}
#else
#	define DEBUG_ALERT(...)
#endif

// this macro is used to release an object and re-assign its value to nil, only
// if it's different from nil.
#if !defined(SAFE_RELEASE)
#	define SAFE_RELEASE(x) if ((x) != nil) { [(x) release]; (x) = nil; }
#endif
