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

#import <sys/utsname.h>

#import "RMTileCache.h"
#import "RMMemoryCache.h"
#import "RMDatabaseCache.h"

#import "RMConfiguration.h"
#import "RMTileSource.h"

#import "RMTileCacheDownloadOperation.h"

@interface RMTileCache (Configuration)

- (id <RMTileCache>)memoryCacheWithConfig:(NSDictionary *)cfg;
- (id <RMTileCache>)databaseCacheWithConfig:(NSDictionary *)cfg;

@end

@implementation RMTileCache
{
    NSMutableArray *_tileCaches;

    // The memory cache, if we have one
    // This one has its own variable because we want to propagate cache hits down in
    // the cache hierarchy up to the memory cache
    RMMemoryCache *_memoryCache;
    NSTimeInterval _expiryPeriod;

    dispatch_queue_t _tileCacheQueue;
    
    id <RMTileSource>_activeTileSource;
    NSOperationQueue *_backgroundFetchQueue;
}

@synthesize backgroundCacheDelegate=_backgroundCacheDelegate;

- (id)initWithExpiryPeriod:(NSTimeInterval)period
{
    if (!(self = [super init]))
        return nil;

    _tileCaches = [[NSMutableArray alloc] init];
    _tileCacheQueue = dispatch_queue_create("routeme.tileCacheQueue", DISPATCH_QUEUE_CONCURRENT);

    _memoryCache = nil;
    _expiryPeriod = period;
    
    _backgroundCacheDelegate = nil;
    _activeTileSource = nil;
    _backgroundFetchQueue = nil;

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
                _memoryCache = [[self memoryCacheWithConfig:cfg] retain];
                continue;
            }

            if ([@"db-cache" isEqualToString:type])
                newCache = [self databaseCacheWithConfig:cfg];

            if (newCache)
                [_tileCaches addObject:newCache];
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
    if (self.isBackgroundCaching)
        [self cancelBackgroundCache];
    
    dispatch_barrier_sync(_tileCacheQueue, ^{
        [_memoryCache release]; _memoryCache = nil;
        [_tileCaches release]; _tileCaches = nil;
    });

	[super dealloc];
}

- (void)addCache:(id <RMTileCache>)cache
{
    dispatch_barrier_async(_tileCacheQueue, ^{
        [_tileCaches addObject:cache];
    });
}

- (void)insertCache:(id <RMTileCache>)cache atIndex:(NSUInteger)index
{
    dispatch_barrier_async(_tileCacheQueue, ^{
        if (index >= [_tileCaches count])
            [_tileCaches addObject:cache];
        else
            [_tileCaches insertObject:cache atIndex:index];
    });
}

+ (NSNumber *)tileHash:(RMTile)tile
{
	return [NSNumber numberWithUnsignedLongLong:RMTileKey(tile)];
}

// Returns the cached image if it exists. nil otherwise.
- (UIImage *)cachedImage:(RMTile)tile withCacheKey:(NSString *)aCacheKey
{
    __block UIImage *image = [_memoryCache cachedImage:tile withCacheKey:aCacheKey];

    if (image)
        return image;

    dispatch_sync(_tileCacheQueue, ^{

        for (id <RMTileCache> cache in _tileCaches)
        {
            image = [[cache cachedImage:tile withCacheKey:aCacheKey] retain];

            if (image != nil)
            {
                [_memoryCache addImage:image forTile:tile withCacheKey:aCacheKey];
                break;
            }
        }

    });

	return [image autorelease];
}

- (void)addImage:(UIImage *)image forTile:(RMTile)tile withCacheKey:(NSString *)aCacheKey
{
    if (!image || !aCacheKey)
        return;

    [_memoryCache addImage:image forTile:tile withCacheKey:aCacheKey];

    dispatch_sync(_tileCacheQueue, ^{

        for (id <RMTileCache> cache in _tileCaches)
        {	
            if ([cache respondsToSelector:@selector(addImage:forTile:withCacheKey:)])
                [cache addImage:image forTile:tile withCacheKey:aCacheKey];
        }

    });
}

- (void)didReceiveMemoryWarning
{
	LogMethod();

    [_memoryCache didReceiveMemoryWarning];

    dispatch_sync(_tileCacheQueue, ^{

        for (id<RMTileCache> cache in _tileCaches)
        {
            [cache didReceiveMemoryWarning];
        }

    });
}

- (void)removeAllCachedImages
{
    [_memoryCache removeAllCachedImages];

    dispatch_sync(_tileCacheQueue, ^{

        for (id<RMTileCache> cache in _tileCaches)
        {
            [cache removeAllCachedImages];
        }

    });
}

- (BOOL)isBackgroundCaching
{
    return (_activeTileSource || _backgroundFetchQueue);
}

- (void)beginBackgroundCacheForTileSource:(id <RMTileSource>)tileSource southWest:(CLLocationCoordinate2D)southWest northEast:(CLLocationCoordinate2D)northEast minZoom:(float)minZoom maxZoom:(float)maxZoom
{
    if (self.isBackgroundCaching)
        [self cancelBackgroundCache];
        
//    NSLog(@"resuming cache of %@ for %f, %f to %f, %f (z%f-%f)", tileSource, southWest.latitude, southWest.longitude, northEast.latitude, northEast.longitude, minZoom, maxZoom);
    
    _activeTileSource = [tileSource retain];
    
    _backgroundFetchQueue = [[NSOperationQueue alloc] init];
    [_backgroundFetchQueue setMaxConcurrentOperationCount:6];
    
    int   MINZOOM = (int)minZoom;
    int   MAXZOOM = (int)maxZoom;
    float MINLAT  = southWest.latitude;
    float MAXLAT  = northEast.latitude;
    float MINLONG = southWest.longitude;
    float MAXLONG = northEast.longitude;
    
    int totalTiles = 0;
    __block int progTile = 0;
    
    for (int zoom = MINZOOM; zoom <= MAXZOOM; zoom++)
    {
        int n = pow(2.0, zoom);   //n=2^ZOOM
        int xMin = floor(((MINLONG + 180.0) / 360.0) * n);  //longitude in degrees
        int yMax = floor((1.0 - (logf(tanf(MINLAT * M_PI / 180.0) + 1.0 / cosf(MINLAT * M_PI / 180.0)) / M_PI)) / 2.0 * n);  //latitude in degrees
        int xMax = floor(((MAXLONG + 180.0) / 360.0) * n);  //longitude in degrees
        int yMin = floor((1.0 - (logf(tanf(MAXLAT * M_PI / 180.0) + 1.0 / cosf(MAXLAT * M_PI / 180.0)) / M_PI)) / 2.0 * n);
//        NSLog(@"n=%d, xMin=%d, xMax=%d, yMin=%d, yMax=%d",n,xMin,xMax,yMin,yMax);
        totalTiles += (xMax + 1 - xMin) * (yMax + 1 - yMin);
//        NSLog(@"Total tiles for this zoom level: %d", totalTiles);
    }

    [_backgroundCacheDelegate tileCache:self didBeginBackgroundCacheWithCount:totalTiles forTileSource:_activeTileSource];

    for (int zoom = MINZOOM; zoom <= MAXZOOM; zoom++)
    {
        int n = pow(2.0, zoom);   //n=2^ZOOM
        int xMin = floor(((MINLONG + 180.0) / 360.0) * n);  //longitude in degrees
        int yMax = floor((1.0 - (logf(tanf(MINLAT * M_PI / 180.0) + 1.0 / cosf(MINLAT * M_PI / 180.0)) / M_PI)) / 2.0 * n);  //latitude in degrees
        int xMax = floor(((MAXLONG + 180.0) / 360.0) * n);  //longitude in degrees
        int yMin = floor((1.0 - (logf(tanf(MAXLAT * M_PI / 180.0) + 1.0 / cosf(MAXLAT * M_PI / 180.0)) / M_PI)) / 2.0 * n);

        for (int x = xMin; x<=xMax; x++)
        {
            // TODO: Create & drain autorelease pool for each iteration of the outer loop (we don't use the returned UIImages)
            for (int y = yMin; y <= yMax; y++)
            {
                RMTileCacheDownloadOperation *operation = [[[RMTileCacheDownloadOperation alloc] initWithTile:RMTileMake(x, y, zoom)
                                                                                                forTileSource:_activeTileSource
                                                                                                   usingCache:self] autorelease];

                [operation setCompletionBlock:^(void)
                {
                    dispatch_async(dispatch_get_main_queue(), ^(void)
                    {
                        if ( ! [operation isCancelled])
                        {
                            progTile++;

                            [_backgroundCacheDelegate tileCache:self didBackgroundCacheTileIndex:progTile ofTotalTileCount:totalTiles];

                            if (progTile == totalTiles)
                            {
                                if (_backgroundFetchQueue)
                                    [_backgroundFetchQueue release]; _backgroundFetchQueue = nil;

                                if (_activeTileSource)
                                    [_activeTileSource release]; _activeTileSource = nil;

                                [_backgroundCacheDelegate tileCacheDidFinishBackgroundCache:self];
                            }
                        }
                    });
                }];

                [_backgroundFetchQueue addOperation:operation];
            }
        }
    };
}

- (void)cancelBackgroundCache
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
    {
        if (_backgroundFetchQueue)
        {
            [_backgroundFetchQueue cancelAllOperations];
            [_backgroundFetchQueue waitUntilAllOperationsAreFinished];
            [_backgroundFetchQueue release]; _backgroundFetchQueue = nil;
        }

        if (_activeTileSource)
            [_activeTileSource release]; _activeTileSource = nil;

        dispatch_async(dispatch_get_main_queue(), ^(void)
        {
            [_backgroundCacheDelegate tileCacheDidCancelBackgroundCache:self];
        });
    });
}

@end

#pragma mark -

@implementation RMTileCache (Configuration)

static NSMutableDictionary *predicateValues = nil;

- (NSDictionary *)predicateValues
{
    static dispatch_once_t predicateValuesOnceToken;

    dispatch_once(&predicateValuesOnceToken, ^{
        struct utsname systemInfo;
        uname(&systemInfo);

        NSString *machine = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];

        predicateValues = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                           [[UIDevice currentDevice] model], @"model",
                           machine, @"machine",
                           [[UIDevice currentDevice] systemName], @"systemName",
                           [NSNumber numberWithFloat:[[[UIDevice currentDevice] systemVersion] floatValue]], @"systemVersion",
                           [NSNumber numberWithInt:[[UIDevice currentDevice] userInterfaceIdiom]], @"userInterfaceIdiom",
                           nil];

        if ( ! ([machine isEqualToString:@"i386"] || [machine isEqualToString:@"x86_64"]))
        {
            NSNumber *machineNumber = [NSNumber numberWithFloat:[[[machine stringByTrimmingCharactersInSet:[NSCharacterSet letterCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@"."] floatValue]];

            if ( ! machineNumber)
                machineNumber = [NSNumber numberWithFloat:0.0];

            [predicateValues setObject:machineNumber forKey:@"machineNumber"];
        }
        else
        {
            [predicateValues setObject:[NSNumber numberWithFloat:0.0] forKey:@"machineNumber"];
        }

        // A predicate might be:
        // (self.model = 'iPad' and self.machineNumber >= 3) or (self.machine = 'x86_64')
        // See NSPredicate

//        NSLog(@"Predicate values:\n%@", [predicateValues description]);
    });

    return predicateValues;
}

- (id <RMTileCache>)memoryCacheWithConfig:(NSDictionary *)cfg
{
    NSUInteger capacity = 32;

	NSNumber *capacityNumber = [cfg objectForKey:@"capacity"];
	if (capacityNumber != nil)
        capacity = [capacityNumber unsignedIntegerValue];

    NSArray *predicates = [cfg objectForKey:@"predicates"];

    if (predicates)
    {
        NSDictionary *predicateValues = [self predicateValues];

        for (NSDictionary *predicateDescription in predicates)
        {
            NSString *predicate = [predicateDescription objectForKey:@"predicate"];
            if ( ! predicate)
                continue;

            if ( ! [[NSPredicate predicateWithFormat:predicate] evaluateWithObject:predicateValues])
                continue;

            capacityNumber = [predicateDescription objectForKey:@"capacity"];
            if (capacityNumber != nil)
                capacity = [capacityNumber unsignedIntegerValue];
        }
    }

    RMLog(@"Memory cache configuration: {capacity : %d}", capacity);

	return [[[RMMemoryCache alloc] initWithCapacity:capacity] autorelease];
}

- (id <RMTileCache>)databaseCacheWithConfig:(NSDictionary *)cfg
{
    BOOL useCacheDir = NO;
    RMCachePurgeStrategy strategy = RMCachePurgeStrategyFIFO;

    NSUInteger capacity = 1000;
    NSUInteger minimalPurge = capacity / 10;

    // Defaults

    NSNumber *capacityNumber = [cfg objectForKey:@"capacity"];

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && [cfg objectForKey:@"capacity-ipad"])
    {
        NSLog(@"***** WARNING: deprecated config option capacity-ipad, use a predicate instead: -[%@ %@] (line %d)", self, NSStringFromSelector(_cmd), __LINE__);
        capacityNumber = [cfg objectForKey:@"capacity-ipad"];
    }

    NSString *strategyStr = [cfg objectForKey:@"strategy"];
    NSNumber *useCacheDirNumber = [cfg objectForKey:@"useCachesDirectory"];
    NSNumber *minimalPurgeNumber = [cfg objectForKey:@"minimalPurge"];
    NSNumber *expiryPeriodNumber = [cfg objectForKey:@"expiryPeriod"];

    NSArray *predicates = [cfg objectForKey:@"predicates"];

    if (predicates)
    {
        NSDictionary *predicateValues = [self predicateValues];

        for (NSDictionary *predicateDescription in predicates)
        {
            NSString *predicate = [predicateDescription objectForKey:@"predicate"];
            if ( ! predicate)
                continue;

            if ( ! [[NSPredicate predicateWithFormat:predicate] evaluateWithObject:predicateValues])
                continue;

            if ([predicateDescription objectForKey:@"capacity"])
                capacityNumber = [predicateDescription objectForKey:@"capacity"];
            if ([predicateDescription objectForKey:@"strategy"])
                strategyStr = [predicateDescription objectForKey:@"strategy"];
            if ([predicateDescription objectForKey:@"useCachesDirectory"])
                useCacheDirNumber = [predicateDescription objectForKey:@"useCachesDirectory"];
            if ([predicateDescription objectForKey:@"minimalPurge"])
                minimalPurgeNumber = [predicateDescription objectForKey:@"minimalPurge"];
            if ([predicateDescription objectForKey:@"expiryPeriod"])
                expiryPeriodNumber = [predicateDescription objectForKey:@"expiryPeriod"];
        }
    }

    // Check the values

    if (capacityNumber != nil)
    {
        NSInteger value = [capacityNumber intValue];

        // 0 is valid: it means no capacity limit
        if (value >= 0)
        {
            capacity =  value;
            minimalPurge = MAX(1,capacity / 10);
        }
        else
        {
            RMLog(@"illegal value for capacity: %d", value);
        }
    }

    if (strategyStr != nil)
    {
        if ([strategyStr caseInsensitiveCompare:@"FIFO"] == NSOrderedSame) strategy = RMCachePurgeStrategyFIFO;
        if ([strategyStr caseInsensitiveCompare:@"LRU"] == NSOrderedSame) strategy = RMCachePurgeStrategyLRU;
    }
    else
    {
        strategyStr = @"FIFO";
    }

    if (useCacheDirNumber != nil)
        useCacheDir = [useCacheDirNumber boolValue];

    if (minimalPurgeNumber != nil && capacity != 0)
    {
        NSUInteger value = [minimalPurgeNumber unsignedIntValue];

        if (value > 0 && value<=capacity)
            minimalPurge = value;
        else
            RMLog(@"minimalPurge must be at least one and at most the cache capacity");
    }

    if (expiryPeriodNumber != nil)
        _expiryPeriod = [expiryPeriodNumber doubleValue];

    RMLog(@"Database cache configuration: {capacity : %d, strategy : %@, minimalPurge : %d, expiryPeriod: %.0f, useCacheDir : %@}", capacity, strategyStr, minimalPurge, _expiryPeriod, useCacheDir ? @"YES" : @"NO");

    RMDatabaseCache *dbCache = [[[RMDatabaseCache alloc] initUsingCacheDir:useCacheDir] autorelease];
    [dbCache setCapacity:capacity];
    [dbCache setPurgeStrategy:strategy];
    [dbCache setMinimalPurge:minimalPurge];
    [dbCache setExpiryPeriod:_expiryPeriod];

    return dbCache;
}

@end
