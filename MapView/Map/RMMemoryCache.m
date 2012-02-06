//
//  RMMemoryCache.m
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

#import "RMMemoryCache.h"
#import "RMTileImage.h"

@implementation RMMemoryCache

- (id)initWithCapacity:(NSUInteger)aCapacity
{
	if (!(self = [super init]))
		return nil;

	RMLog(@"initializing memory cache %@ with capacity %d", self, aCapacity);

	cache = [[NSMutableDictionary alloc] initWithCapacity:aCapacity];
	
	if (aCapacity < 1)
		aCapacity = 1;

	capacity = aCapacity;

	return self;
}

- (id)init
{
	return [self initWithCapacity:32];
}

- (void)dealloc
{
    @synchronized (cache)
    {
        [cache removeAllObjects];
        [cache release]; cache = nil;
    }

	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
	LogMethod();

    @synchronized (cache)
    {
        [cache removeAllObjects];
    }
}

- (void)removeTile:(RMTile)tile
{
    @synchronized (cache)
    {
        [cache removeObjectForKey:[RMTileCache tileHash:tile]];
    }
}

- (UIImage *)cachedImage:(RMTile)tile withCacheKey:(NSString *)aCacheKey
{
//    RMLog(@"Memory cache check  tile %d %d %d (%@)", tile.x, tile.y, tile.zoom, [RMTileCache tileHash:tile]);

    RMCacheObject *cachedObject = nil;
    NSNumber *tileHash = [RMTileCache tileHash:tile];

    @synchronized (cache)
    {
        cachedObject = [cache objectForKey:tileHash];
        if (!cachedObject)
            return nil;

        if (![[cachedObject cacheKey] isEqualToString:aCacheKey])
        {
            [cache removeObjectForKey:tileHash];
            return nil;
        }

        [cachedObject touch];
    }

//    RMLog(@"Memory cache hit    tile %d %d %d (%@)", tile.x, tile.y, tile.zoom, [RMTileCache tileHash:tile]);

    return [cachedObject cachedObject];
}

/// Remove the least-recently used image from cache, if cache is at or over capacity. Removes only 1 image.
- (void)makeSpaceInCache
{
    @synchronized (cache)
    {
        while ([cache count] >= capacity)
        {
            // Rather than scanning I would really like to be using a priority queue
            // backed by a heap here.

            // Maybe deleting one random element would work as well.

            NSEnumerator *enumerator = [cache objectEnumerator];
            RMCacheObject *image;

            NSDate *oldestDate = nil;
            RMCacheObject *oldestImage = nil;

            while ((image = (RMCacheObject *)[enumerator nextObject]))
            {
                if (oldestDate == nil || ([oldestDate timeIntervalSinceReferenceDate] > [[image timestamp] timeIntervalSinceReferenceDate]))
                {
                    oldestDate = [image timestamp];
                    oldestImage = image;
                }
            }

            if (oldestImage)
            {
                // RMLog(@"Memory cache delete tile %d %d %d (%@)", oldestImage.tile.x, oldestImage.tile.y, oldestImage.tile.zoom, [RMTileCache tileHash:oldestImage.tile]);
                [cache removeObjectForKey:[RMTileCache tileHash:oldestImage.tile]];
            }
        }
    }
}

- (void)addImage:(UIImage *)image forTile:(RMTile)tile withCacheKey:(NSString *)aCacheKey
{
//    RMLog(@"Memory cache insert tile %d %d %d (%@)", tile.x, tile.y, tile.zoom, [RMTileCache tileHash:tile]);

	[self makeSpaceInCache];

    @synchronized (cache)
    {
        [cache setObject:[RMCacheObject cacheObject:image forTile:tile withCacheKey:aCacheKey] forKey:[RMTileCache tileHash:tile]];
    }
}

- (void)removeAllCachedImages
{
    LogMethod();

    @synchronized (cache)
    {
        [cache removeAllObjects];
    }
}

@end
