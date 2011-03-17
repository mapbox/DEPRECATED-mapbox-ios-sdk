//
//  RMDatabaseCache.m
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

#import "RMDatabaseCache.h"
#import "RMTileCacheDAO.h"
#import "RMTileImage.h"
#import "RMTile.h"

@implementation RMDatabaseCache

@synthesize databasePath;

+ (NSString *)dbPathUsingCacheDir:(BOOL)useCacheDir
{
	NSArray *paths;

	if (useCacheDir) {
		paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	} else {
		paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	}

	if ([paths count] > 0) // Should only be one...
	{
		NSString *cachePath = [paths objectAtIndex:0];
		
		// check for existence of cache directory
		if ( ![[NSFileManager defaultManager] fileExistsAtPath: cachePath]) 
		{
			// create a new cache directory
			[[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:nil];
		}
		
		NSString *filename = [NSString stringWithFormat:@"MapCache.sqlite"];
		return [cachePath stringByAppendingPathComponent:filename];
	}

	return nil;
}

- (id)initWithDatabase:(NSString *)path
{
	if (!(self = [super init]))
		return nil;

	self.databasePath = path;
	dao = [[RMTileCacheDAO alloc] initWithDatabase:path];
    if (!dao) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
        dao = [[RMTileCacheDAO alloc] initWithDatabase:path];
    }

	if (dao == nil)
		return nil;

	return self;	
}

- (id)initUsingCacheDir:(BOOL)useCacheDir
{
	return [self initWithDatabase:[RMDatabaseCache dbPathUsingCacheDir:useCacheDir]];
}

- (void)dealloc
{
    self.databasePath = nil;
	[dao release]; dao = nil;
	[super dealloc];
}

- (void)setPurgeStrategy:(RMCachePurgeStrategy)theStrategy
{
	purgeStrategy = theStrategy;
}

- (void)setCapacity:(NSUInteger)theCapacity
{
	capacity = theCapacity;
}

- (void)setMinimalPurge:(NSUInteger)theMinimalPurge
{
	minimalPurge = theMinimalPurge;
}

- (UIImage *)cachedImage:(RMTile)tile withCacheKey:(NSString *)aCacheKey
{
//	RMLog(@"DB cache check for tile %d %d %d", tile.x, tile.y, tile.zoom);

	NSData *data = [dao dataForTile:RMTileKey(tile) withKey:aCacheKey];
    if (data == nil)
        return nil;

    if (capacity != 0 && purgeStrategy == RMCachePurgeStrategyLRU) {
        [dao touchTile:RMTileKey(tile) withKey:aCacheKey];
    }

//    RMLog(@"DB cache     hit    tile %d %d %d (%@)", tile.x, tile.y, tile.zoom, [RMTileCache tileHash:tile]);

	return [UIImage imageWithData:data];
}

- (void)addImage:(UIImage *)image forTile:(RMTile)tile withCacheKey:(NSString *)aCacheKey
{
    // TODO: Converting the image here (again) is not so good...
	NSData *data = UIImagePNGRepresentation(image);
    
    if (capacity != 0) {
        NSUInteger tilesInDb = [dao count];
        if (capacity <= tilesInDb) {
            [dao purgeTiles: MAX(minimalPurge, 1+tilesInDb-capacity)];
        }
        
//        RMLog(@"DB cache     insert tile %d %d %d (%@)", tile.x, tile.y, tile.zoom, [RMTileCache tileHash:tile]);
        
		[dao addData:data forTile:RMTileKey(tile) withKey:aCacheKey];
	}
}

- (void)didReceiveMemoryWarning
{
    [dao didReceiveMemoryWarning];
}

- (void)removeAllCachedImages 
{
    [dao removeAllCachedImages];
}

@end
