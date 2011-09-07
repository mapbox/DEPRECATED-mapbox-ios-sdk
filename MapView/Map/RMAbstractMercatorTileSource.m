//
//  RMMercatorWebSource.m
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

#import "RMAbstractMercatorTileSource.h"
#import "RMTileImage.h"
#import "RMFractalTileProjection.h"
#import "RMProjection.h"

@implementation RMAbstractMercatorTileSource

- (id)init
{
	if (!(self = [super init]))
		return nil;

    minZoom = kDefaultMinTileZoom;
    maxZoom = kDefaultMaxTileZoom;
    tileSideLength = kDefaultTileSize;
    
	return self;
}

- (void)dealloc
{
	[tileProjection release]; tileProjection = nil;
	[super dealloc];
}

- (int)tileSideLength
{
	return tileSideLength;
}

- (void)setTileSideLength:(NSUInteger)aTileSideLength
{
    tileSideLength = aTileSideLength;
}

- (float)minZoom
{
	return minZoom;
}

- (void)setMinZoom:(NSUInteger)aMinZoom
{
    minZoom = aMinZoom;
}

- (float)maxZoom
{
	return maxZoom;
}

- (void)setMaxZoom:(NSUInteger)aMaxZoom
{
    maxZoom = aMaxZoom;
}

- (RMSphericalTrapezium)latitudeLongitudeBoundingBox
{
	return kDefaultLatLonBoundingBox;
}

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache
{
	@throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                   reason:@"imageForTile: invoked on AbstractMercatorWebSource. Override this method when instantiating abstract class."
                                 userInfo:nil];
}    

- (void)cancelAllDownloads
{
}

- (RMFractalTileProjection *)mercatorToTileProjection
{
    if (!tileProjection) {
        tileProjection = [[RMFractalTileProjection alloc] initFromProjection:[self projection]
                                                              tileSideLength:[self tileSideLength]
                                                                     maxZoom:[self maxZoom]
                                                                     minZoom:[self minZoom]];
    }

	return tileProjection;
}

- (RMProjection *)projection
{
	return [RMProjection googleProjection];
}

- (void)didReceiveMemoryWarning
{
	LogMethod();		
}

- (NSString *)uniqueTilecacheKey
{
	@throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                   reason:@"uniqueTilecacheKey invoked on AbstractMercatorWebSource. Override this method when instantiating abstract class."
                                 userInfo:nil];
}

- (NSString *)shortName
{
	@throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                   reason:@"shortName invoked on AbstractMercatorWebSource. Override this method when instantiating abstract class."
                                 userInfo:nil];
}

- (NSString *)longDescription
{
	return [self shortName];
}

- (NSString *)shortAttribution
{
	@throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                   reason:@"shortAttribution invoked on AbstractMercatorWebSource. Override this method when instantiating abstract class."
                                 userInfo:nil];
}

- (NSString *)longAttribution
{
	return [self shortAttribution];
}

@end

