//
//  RMTileSource.h
//
// Copyright (c) 2008-2012, Route-Me Contributors
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

#import <Foundation/Foundation.h>

#import "RMTile.h"
#import "RMFoundation.h"
#import "RMGlobalConstants.h"

#define RMTileRequested @"RMTileRequested"
#define RMTileRetrieved @"RMTileRetrieved"

@class RMFractalTileProjection, RMTileCache, RMProjection, RMTileImage, RMTileCache;

@protocol RMMercatorToTileProjection;

#pragma mark -

@protocol RMTileSource <NSObject>

// min and max zoom can be set externally since you might want to constrain the zoom level range
@property (nonatomic, assign) float minZoom;
@property (nonatomic, assign) float maxZoom;

@property (nonatomic, readonly) RMFractalTileProjection *mercatorToTileProjection;
@property (nonatomic, readonly) RMProjection *projection;

@property (nonatomic, readonly) RMSphericalTrapezium latitudeLongitudeBoundingBox;

@property (nonatomic, readonly) NSString *uniqueTilecacheKey;
@property (nonatomic, readonly) NSUInteger tileSideLength;

@property (nonatomic, readonly) NSString *shortName;
@property (nonatomic, readonly) NSString *longDescription;
@property (nonatomic, readonly) NSString *shortAttribution;
@property (nonatomic, readonly) NSString *longAttribution;

#pragma mark -

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache;
- (void)cancelAllDownloads;

- (void)didReceiveMemoryWarning;

@end
