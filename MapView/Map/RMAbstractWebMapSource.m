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
    UIImage *image = nil;

	tile = [[self mercatorToTileProjection] normaliseTile:tile];
    image = [tileCache cachedImage:tile withCacheKey:[self uniqueTilecacheKey]];
    if (image) return image;

    [[NSNotificationCenter defaultCenter] postNotificationName:RMTileRequested object:nil];

    [tileCache retain];

    // Beware: dataWithContentsOfURL is leaking like hell. Better use AFNetwork or ASIHTTPRequest
    for (NSURL *currentURL in [self URLsForTile:tile])
    {
        NSData *tileData = [NSData dataWithContentsOfURL:currentURL options:NSDataReadingUncached error:NULL];
        if (tileData && [tileData length]) {
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
