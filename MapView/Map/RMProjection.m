//
//  RMProjection.m
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

#import "RMGlobalConstants.h"
#import "proj_api.h"
#import "RMProjection.h"

@implementation RMProjection
{
    // This is actually a PROJ4 projPJ, but it is typed as void* so the proj_api doesn't have to be included
    void *_internalProjection;

    // the size of the earth, in projected units (meters, most often)
    RMProjectedRect	_planetBounds;

    // hardcoded to YES in #initWithString:InBounds:
    BOOL _projectionWrapsHorizontally;
}

@synthesize internalProjection = _internalProjection;
@synthesize planetBounds = _planetBounds;
@synthesize projectionWrapsHorizontally = _projectionWrapsHorizontally;

- (id)initWithString:(NSString *)proj4String inBounds:(RMProjectedRect)projectedBounds
{
    if (!(self = [super init]))
        return nil;

    _internalProjection = pj_init_plus([proj4String UTF8String]);

    if (_internalProjection == NULL)
    {
        RMLog(@"Unhandled error creating projection. String is %@", proj4String);
        [self release];
        return nil;
    }

    _planetBounds = projectedBounds;
    _projectionWrapsHorizontally = YES;

    return self;
}

- (id)initWithString:(NSString *)proj4String
{
    RMProjectedRect theBounds;
    theBounds = RMProjectedRectMake(0, 0, 0, 0);

    return [self initWithString:proj4String inBounds:theBounds];
}

- (id)init
{
    return [self initWithString:@"+proj=latlong +ellps=WGS84"];
}

- (void)dealloc
{
    if (_internalProjection)
        pj_free(_internalProjection);

    [super dealloc];
}

- (RMProjectedPoint)wrapPointHorizontally:(RMProjectedPoint)aPoint
{
    if (!_projectionWrapsHorizontally || _planetBounds.size.width == 0.0f || _planetBounds.size.height == 0.0f)
        return aPoint;

    while (aPoint.x < _planetBounds.origin.x)
        aPoint.x += _planetBounds.size.width;

    while (aPoint.x > (_planetBounds.origin.x + _planetBounds.size.width))
        aPoint.x -= _planetBounds.size.width;

    return aPoint;
}

- (RMProjectedPoint)constrainPointToBounds:(RMProjectedPoint)aPoint
{
    if (_planetBounds.size.width == 0.0f || _planetBounds.size.height == 0.0f)
        return aPoint;

    [self wrapPointHorizontally:aPoint];

    if (aPoint.y < _planetBounds.origin.y)
        aPoint.y = _planetBounds.origin.y;
    else if (aPoint.y > (_planetBounds.origin.y + _planetBounds.size.height))
        aPoint.y = _planetBounds.origin.y + _planetBounds.size.height;

    return aPoint;
}

- (RMProjectedPoint)coordinateToProjectedPoint:(CLLocationCoordinate2D)aLatLong
{
    projUV uv = {
        aLatLong.longitude * DEG_TO_RAD,
        aLatLong.latitude * DEG_TO_RAD
    };

    projUV result = pj_fwd(uv, _internalProjection);

    RMProjectedPoint result_point = {
        result.u,
        result.v,
    };

    return result_point;
}

- (CLLocationCoordinate2D)projectedPointToCoordinate:(RMProjectedPoint)aPoint
{
    projUV uv = {
        aPoint.x,
        aPoint.y,
    };

    projUV result = pj_inv(uv, _internalProjection);

    CLLocationCoordinate2D result_coordinate = {
        result.v * RAD_TO_DEG,
        result.u * RAD_TO_DEG,
    };

    return result_coordinate;
}

static RMProjection *_googleProjection = nil;
static RMProjection *_latitudeLongitudeProjection = nil;

+ (RMProjection *)googleProjection
{
    if (_googleProjection)
    {
        return _googleProjection;
    }
    else
    {
        RMProjectedRect theBounds = RMProjectedRectMake(-20037508.34, -20037508.34, 20037508.34 * 2, 20037508.34 * 2);

        _googleProjection = [[RMProjection alloc] initWithString:@"+title= Google Mercator EPSG:900913 +proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs"
                                                        inBounds:theBounds];
        return _googleProjection;
    }
}

+ (RMProjection *)EPSGLatLong
{
    if (_latitudeLongitudeProjection)
    {
        return _latitudeLongitudeProjection;
    }
    else
    {
        RMProjectedRect theBounds = RMProjectedRectMake(-kMaxLong, -kMaxLat, 360.0, kMaxLong);

        _latitudeLongitudeProjection = [[RMProjection alloc] initWithString:@"+proj=latlong +ellps=WGS84"
                                                                   inBounds:theBounds];
        return _latitudeLongitudeProjection;
    }
}

@end
