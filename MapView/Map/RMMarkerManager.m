//
//  RMMarkerManager.m
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

#import "RMMarkerManager.h"
#import "RMMercatorToScreenProjection.h"
#import "RMProjection.h"
#import "RMLayerCollection.h"

@implementation RMMarkerManager

@synthesize mapContents;

- (id)initWithContents:(RMMapContents *)contents
{
    if (!(self = [super init]))
        return nil;

    mapContents = contents;
    rotationTransform = CGAffineTransformIdentity;

    return self;
}

- (void)dealloc
{
    mapContents = nil;
    [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark 
#pragma mark Adding / Removing / Displaying Markers

/// place the (new created) marker onto the map at projected point and take ownership of it
- (void)addMarker:(RMMarker *)marker atProjectedPoint:(RMProjectedPoint)projectedPoint
{
    [marker setAffineTransform:rotationTransform];
    [marker setProjectedLocation:projectedPoint];
    [marker setPosition:[[mapContents mercatorToScreenProjection] projectProjectedPoint:projectedPoint]];
    [[mapContents overlay] addSublayer:marker];
}

/// place the (newly created) marker onto the map and take ownership of it
- (void)addMarker:(RMMarker *)marker atLatLong:(CLLocationCoordinate2D)point
{
    [marker setAffineTransform:rotationTransform];
    [marker setProjectedLocation:[[mapContents projection] coordinateToProjectedPoint:point]];
    [marker setPosition:[[mapContents mercatorToScreenProjection] projectProjectedPoint:[marker projectedLocation]]];
    [[mapContents overlay] addSublayer:marker];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark 
#pragma mark Marker information

- (NSArray *)markers
{
    return [[mapContents overlay] sublayers];
}

- (void)removeMarker:(RMMarker *)marker
{
    [[mapContents overlay] removeSublayer:marker];
}

- (void)removeMarkers:(NSArray *)markers
{
    [[mapContents overlay] removeSublayers:markers];
}

- (CGPoint)screenCoordinatesForMarker:(RMMarker *)marker
{
    return [[mapContents mercatorToScreenProjection] projectProjectedPoint:[marker projectedLocation]];
}

- (CLLocationCoordinate2D)latitudeLongitudeForMarker:(RMMarker *)marker
{
    return [mapContents pixelToLatLong:[self screenCoordinatesForMarker:marker]];
}

- (NSArray *)markersWithinScreenBounds
{
    NSMutableArray *markersInScreenBounds = [NSMutableArray array];
    CGRect rect = [[mapContents mercatorToScreenProjection] screenBounds];

    for (RMMarker *marker in [self markers]) {
        if ([self isMarker:marker withinBounds:rect]) {
            [markersInScreenBounds addObject:marker];
        }
    }

    return markersInScreenBounds;
}

- (BOOL)isMarkerWithinScreenBounds:(RMMarker *)marker
{
    return [self isMarker:marker withinBounds:[[mapContents mercatorToScreenProjection] screenBounds]];
}

/// \deprecated violates Objective-C naming rules
- (BOOL)isMarker:(RMMarker *)marker withinBounds:(CGRect)rect
{
    if (![self managingMarker:marker]) {
        return NO;
    }

    CGPoint markerCoord = [self screenCoordinatesForMarker:marker];
    if (markerCoord.x > rect.origin.x
        && markerCoord.x < rect.origin.x + rect.size.width
        && markerCoord.y > rect.origin.y
        && markerCoord.y < rect.origin.y + rect.size.height)
    {
        return YES;
    }

    return NO;
}

/// \deprecated violates Objective-C naming rules
- (BOOL)managingMarker:(RMMarker *)marker
{
    if (marker != nil && [[self markers] indexOfObject:marker] != NSNotFound) {
        return YES;
    }
    return NO;
}

- (void)moveMarker:(RMMarker *)marker atLatLon:(CLLocationCoordinate2D)point
{
    [marker setProjectedLocation:[[mapContents projection]coordinateToProjectedPoint:point]];
    [marker setPosition:[[mapContents mercatorToScreenProjection] projectProjectedPoint:[[mapContents projection] coordinateToProjectedPoint:point]]];
}

- (void)moveMarker:(RMMarker *)marker atXY:(CGPoint)point
{
    [marker setProjectedLocation:[[mapContents mercatorToScreenProjection] projectScreenPointToProjectedPoint:point]];
    [marker setPosition:point];
}

- (void)setRotation:(float)angle
{
    rotationTransform = CGAffineTransformMakeRotation(angle); // store rotation transform for subsequent markers

    for (RMMarker *marker in [self markers])
    {
        [marker setAffineTransform:rotationTransform];
    }
}

@end
