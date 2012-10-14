//
//  SimpleProfiler.h
//  Unbound5
//
//  Created by Bob on 10/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ProfilingEntry;


@interface SimpleProfiler
: NSObject
{
    
@private
    
	NSMutableDictionary *	mEntries;
    
}

+(SimpleProfiler *)instance;
+(void)destroyInstance;

-(id)init;
-(void)addEntry:(NSString *)name withTime:(double)time;
-(void)log;

@end


@interface ProfilingEntry
: NSObject
{
    
@private
    
	NSString *			mName;
	NSMutableArray *	mTimes;
}

@property (copy) NSString * name;

+(ProfilingEntry *)entryWithName:(NSString *)name;

-(id)init;
-(void)dealloc;
-(double)averageTime;
-(void)addTime:(double)time;

@end

#if defined(PROFILING)
#	define PROFILING_START(name) \
NSString * __name = name; \
NSDate * __date = [NSDate date]
#else
#	define PROFILING_START(name)
#endif

#if defined(PROFILING)
#	define PROFILING_STOP() \
[[SimpleProfiler instance] addEntry:__name \
withTime:[[NSDate date] timeIntervalSinceDate:__date]]
#else
#	define PROFILING_STOP()
#endif
