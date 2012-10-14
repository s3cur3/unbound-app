//
//  SimpleProfiler.m
//  Unbound5
//
//  Created by Bob on 10/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "SimpleProfiler.h"

static SimpleProfiler * mSimpleProfilerInstance = nil;

@implementation SimpleProfiler

+(SimpleProfiler *)instance
{
	if (mSimpleProfilerInstance == nil)
		mSimpleProfilerInstance = [[SimpleProfiler alloc] init];
	return mSimpleProfilerInstance;
}

+(void)destroyInstance
{
	if (mSimpleProfilerInstance != nil)
	{
		//[mSimpleProfilerInstance release];
		mSimpleProfilerInstance = nil;
	}
}

-(id)init
{
	self = [super init];
	if (self)
	{
		mEntries = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(void)dealloc
{
	[mEntries removeAllObjects];
	[mEntries release];
	[super dealloc];
}

-(void)addEntry:(NSString *)name withTime:(double)time
{
	ProfilingEntry * entry = nil;
	entry = [mEntries objectForKey:name];
	if (entry == nil)
	{
		entry = [ProfilingEntry entryWithName:name];
		[mEntries setValue:entry forKey:name];
	}
	[entry addTime:time];
}

-(void)log
{
	if ([mEntries count] == 0)
		return;
    
	NSLog(@"Profiling log");
	for (ProfilingEntry * entry in [mEntries allValues])
	{
		NSLog(@"%@ -- %f", [entry name], [entry averageTime]);
	}
}

@end

@implementation ProfilingEntry

@synthesize name = mName;

+(ProfilingEntry *)entryWithName:(NSString *)name
{
	ProfilingEntry * entry = [[[ProfilingEntry alloc] init] autorelease];
	[entry setName:name];
	return entry;
}

-(id)init
{
	self = [super init];
	if (self)
	{
		mName = nil;
		mTimes = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void)dealloc
{
	[mName release];
	[mTimes release];
	[super dealloc];
}

-(double)averageTime
{
	double averageTime = 0.0;
	for (NSNumber * number in mTimes)
	{
		averageTime += [number doubleValue];
	}
	return averageTime / (double)[mTimes count];
}

-(void)addTime:(double)time
{
	[mTimes addObject:[NSNumber numberWithDouble:time]];
}

@end

