//
// RMWebMapSource.m
//
// Copyright (c) 2009, Frank Schroeder, SharpMind GbR
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

#import "RMAbstractWebMapSource.h"
#import "RMTileCache.h"
#import "RMTileImage.h"

#define RMAbstractWebMapSourceRetryCount  3
#define RMAbstractWebMapSourceWaitSeconds 2

@implementation RMAbstractWebMapSource

- (id)init
{
    if (!(self = [super init]))
        return nil;
    
    return self;
}

- (NSURL *)URLForTile:(RMTile)tile
{
	@throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                   reason:@"URLForTile: invoked on AbstractMercatorWebSource. Override this method when instantiating abstract class."
                                 userInfo:nil];
}

- (NSArray *)URLsForTile:(RMTile)tile
{
    return [NSArray arrayWithObjects:[self URLForTile:tile], nil];
}

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache
{
    __block UIImage *image = nil;

	tile = [[self mercatorToTileProjection] normaliseTile:tile];
    image = [tileCache cachedImage:tile withCacheKey:[self uniqueTilecacheKey]];
    if (image) return image;

    [[NSNotificationCenter defaultCenter] postNotificationName:RMTileRequested object:nil];

    [tileCache retain];

    NSArray *URLs = [self URLsForTile:tile];
    
    // fill up collection array with placeholders
    //
    NSMutableArray *tilesData = [NSMutableArray arrayWithCapacity:[URLs count]];
    
    for (int p = 0; p < [URLs count]; p++)
        [tilesData addObject:[NSNull null]];

    dispatch_group_t fetchGroup = dispatch_group_create();
    
    for (int u = 0; u < [URLs count]; u++)
    {
        NSURL *currentURL = [URLs objectAtIndex:u];
        
        dispatch_group_async(fetchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
        {
            NSData *tileData = nil;
            
            for (int try = 0; try < RMAbstractWebMapSourceRetryCount; try++)
                if ( ! tileData)
                    // Beware: dataWithContentsOfURL is leaking like hell. Better use AFNetwork or ASIHTTPRequest
                    tileData = [NSData dataWithContentsOfURL:currentURL options:NSDataReadingUncached error:NULL];
            
            if (tileData)
            {
                dispatch_sync(dispatch_get_main_queue(), ^(void)
                {
                    // safely put into collection array in proper order
                    //
                    [tilesData replaceObjectAtIndex:u withObject:tileData]; 
                });
            }
        });
    }
    
    // wait for whole group of fetches (with retries) to finish, then clean up
    //
    dispatch_group_wait(fetchGroup, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * RMAbstractWebMapSourceWaitSeconds));
    dispatch_release(fetchGroup);
    
    // composite the collected images together
    //
    for (NSData *tileData in tilesData)
    {
        if (tileData && [tileData isKindOfClass:[NSData class]] && [tileData length]) {
            if (image != nil) {
                UIGraphicsBeginImageContext(image.size);
                [image drawAtPoint:CGPointMake(0,0)];
                [[UIImage imageWithData:tileData] drawAtPoint:CGPointMake(0,0)];

                image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            } else {
                image = [UIImage imageWithData:tileData];
            }
        }
    }
    if (image) [tileCache addImage:image forTile:tile withCacheKey:[self uniqueTilecacheKey]];

    [tileCache release];

    [[NSNotificationCenter defaultCenter] postNotificationName:RMTileRetrieved object:nil];

    if (!image) return [RMTileImage errorTile];

    return image;
}

@end
