#import "Utils.h"


@implementation Utils



+(void)bind:(id)src
	   keyPath:(NSString *)srcKey
	   to:(id)dest
	   keyPath:(id)destKey
	   continuous:(BOOL)continuous
	   twoWay:(BOOL)twoWay
{
	NSMutableDictionary * options = nil;
	if (continuous == YES)
	{
		options = [[NSMutableDictionary alloc] init];
		[options setObject:[NSNumber numberWithBool:YES]
				 forKey:NSContinuouslyUpdatesValueBindingOption];
	}
	
	[src bind:srcKey toObject:dest withKeyPath:destKey options:options];
	if (twoWay == YES)
		[dest bind:destKey toObject:src withKeyPath:srcKey options:options];

	[options release];
}

+(NSMutableParagraphStyle *)defaultParagraphStyle
{
	return [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
}

+(NSSize)stringSize:(NSString *)string withAttribute:(NSDictionary *)attributes
{
	NSAttributedString * attributedString = [NSAttributedString alloc];
	attributedString = [attributedString initWithString:string];
	NSSize size = [attributedString size];
	[attributedString release];
	return size;
}

@end