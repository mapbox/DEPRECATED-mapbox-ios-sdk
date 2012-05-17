//
//  RMTileCache.m
//
// Copyright (c) 2008-2009, Route-Me Contributors
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import "RMTileCache.h"
#import "RMMemoryCache.h"
#import "RMDatabaseCache.h"

#import "RMConfiguration.h"
#import "RMTileSource.h"

@interface RMTileCache (Configuration)

- (id <RMTileCache>)memoryCacheWithConfig:(NSDictionary *)cfg;
- (id <RMTileCache>)databaseCacheWithConfig:(NSDictionary *)cfg;

@end

@implementation RMTileCache

- (id)initWithExpiryPeriod:(NSTimeInterval)period
{
	if (!(self = [super init]))
		return nil;

	caches = [[NSMutableArray alloc] init];
    memoryCache = nil;
    expiryPeriod = period;
    
	id cacheCfg = [[RMConfiguration configuration] cacheConfiguration];	
	if (!cacheCfg)
		cacheCfg = [NSArray arrayWithObjects:
                    [NSDictionary dictionaryWithObject: @"memory-cache" forKey: @"type"],
                    [NSDictionary dictionaryWithObject: @"db-cache"     forKey: @"type"],
                    nil];

	for (id cfg in cacheCfg) 
	{
		id <RMTileCache> newCache = nil;

		@try {

			NSString *type = [cfg valueForKey:@"type"];

			if ([@"memory-cache" isEqualToString:type])
            {
				memoryCache = [[self memoryCacheWithConfig:cfg] retain];
                continue;
            }

			if ([@"db-cache" isEqualToString:type])
				newCache = [self databaseCacheWithConfig:cfg];

			if (newCache)
				[caches addObject:newCache];
			else
				RMLog(@"failed to create cache of type %@", type);

		}
		@catch (NSException * e) {
			RMLog(@"*** configuration error: %@", [e reason]);
		}
	}

	return self;
}

- (id)init
{
    if (!(self = [self initWithExpiryPeriod:0]))
        return nil;
    
    return self;
}

- (void)dealloc
{
    [memoryCache release]; memoryCache = nil;
	[caches release]; caches = nil;
	[super dealloc];
}

- (void)addCache:(id <RMTileCache>)cache
{
    @synchronized (caches)
    {
        [caches addObject:cache];
    }
}

+ (NSNumber *)tileHash:(RMTile)tile
{
	return [NSNumber numberWithUnsignedLongLong:RMTileKey(tile)];
}

// Returns the cached image if it exists. nil otherwise.
- (UIImage *)cachedImage:(RMTile)tile withCacheKey:(NSString *)aCacheKey
{
    UIImage *image = [memoryCache cachedImage:tile withCacheKey:aCacheKey];

    if (image)
        return image;

    @synchronized (caches)
    {
        for (id <RMTileCache> cache in caches)
        {
            image = [cache cachedImage:tile withCacheKey:aCacheKey];

            if (image != nil)
            {
                [memoryCache addImage:image forTile:tile withCacheKey:aCacheKey];
                return image;
            }
        }
    }

	return nil;
}

- (void)addImage:(UIImage *)image forTile:(RMTile)tile withCacheKey:(NSString *)aCacheKey
{
    [memoryCache addImage:image forTile:tile withCacheKey:aCacheKey];

    @synchronized (caches)
    {
        for (id <RMTileCache> cache in caches)
        {	
            if ([cache respondsToSelector:@selector(addImage:forTile:withCacheKey:)])
                [cache addImage:image forTile:tile withCacheKey:aCacheKey];
        }
    }
}

- (void)didReceiveMemoryWarning
{
	LogMethod();
    [memoryCache didReceiveMemoryWarning];

    @synchronized (caches)
    {
        for (id<RMTileCache> cache in caches)
        {
            [cache didReceiveMemoryWarning];
        }
    }
}

- (void)removeAllCachedImages
{
    [memoryCache removeAllCachedImages];

    @synchronized (caches)
    {
        for (id<RMTileCache> cache in caches)
        {
            [cache removeAllCachedImages];
        }
    }
}

@end

#pragma mark -

@implementation RMTileCache (Configuration)

- (id <RMTileCache>)memoryCacheWithConfig:(NSDictionary *)cfg
{
	NSNumber *capacity = [cfg objectForKey:@"capacity"];
	if (capacity == nil) 
        capacity = [NSNumber numberWithInt:32];
    
	return [[[RMMemoryCache alloc] initWithCapacity:[capacity intValue]] autorelease];
}

- (id <RMTileCache>)databaseCacheWithConfig:(NSDictionary *)cfg
{
    BOOL useCacheDir = NO;
    RMCachePurgeStrategy strategy = RMCachePurgeStrategyFIFO;

    NSUInteger capacity = 1000;
    NSUInteger minimalPurge = capacity / 10;

    NSNumber *capacityNumber = [cfg objectForKey:@"capacity"];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && [cfg objectForKey:@"capacity-ipad"])
        capacityNumber = [cfg objectForKey:@"capacity-ipad"];

    if (capacityNumber != nil) {
        NSInteger value = [capacityNumber intValue];

        // 0 is valid: it means no capacity limit
        if (value >= 0) {
            capacity =  value;
            minimalPurge = MAX(1,capacity / 10);
        } else
            RMLog(@"illegal value for capacity: %d", value);
    }

    NSString *strategyStr = [cfg objectForKey:@"strategy"];
    if (strategyStr != nil) {
        if ([strategyStr caseInsensitiveCompare:@"FIFO"] == NSOrderedSame) strategy = RMCachePurgeStrategyFIFO;
        if ([strategyStr caseInsensitiveCompare:@"LRU"] == NSOrderedSame) strategy = RMCachePurgeStrategyLRU;
    }

    NSNumber *useCacheDirNumber = [cfg objectForKey:@"useCachesDirectory"];
    if (useCacheDirNumber != nil)
        useCacheDir = [useCacheDirNumber boolValue];

    NSNumber *minimalPurgeNumber = [cfg objectForKey:@"minimalPurge"];
    if (minimalPurgeNumber != nil && capacity != 0) {
        NSUInteger value = [minimalPurgeNumber unsignedIntValue];
        if (value > 0 && value<=capacity) {
            minimalPurge = value;
        } else {
            RMLog(@"minimalPurge must be at least one and at most the cache capacity");
        }
    }
    
    NSNumber *expiryPeriodNumber = [cfg objectForKey:@"expiryPeriod"];
    if (expiryPeriodNumber != nil)
        expiryPeriod = [expiryPeriodNumber intValue];

    RMDatabaseCache *dbCache = [[[RMDatabaseCache alloc] initUsingCacheDir:useCacheDir] autorelease];
    [dbCache setCapacity:capacity];
    [dbCache setPurgeStrategy:strategy];
    [dbCache setMinimalPurge:minimalPurge];
    [dbCache setExpiryPeriod:expiryPeriod];

    return dbCache;
}

@end
