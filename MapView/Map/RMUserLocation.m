//
//  RMUserLocation.m
//  MapView
//
//  Created by Justin Miller on 5/8/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import "RMUserLocation.h"
#import "RMMarker.h"
#import "RMMapView.h"

#define kRMUserLocationAnnotationTypeName @"RMUserLocationAnnotation"

@interface RMUserLocation ()

@property (nonatomic, assign) BOOL hasCustomLayer;

@end

#pragma mark -

@implementation RMUserLocation

@synthesize updating = _updating;
@synthesize location = _location;
@synthesize heading = _heading;
@synthesize hasCustomLayer = _hasCustomLayer;

- (id)initWithMapView:(RMMapView *)aMapView coordinate:(CLLocationCoordinate2D)aCoordinate andTitle:(NSString *)aTitle
{
    if ( ! (self = [super initWithMapView:aMapView coordinate:aCoordinate andTitle:aTitle]))
        return nil;

    self.annotationType = kRMUserLocationAnnotationTypeName;

    self.clusteringEnabled = NO;

    return self;
}

- (RMMapLayer *)layer
{
    if ( ! super.layer)
    {
        if ([self.mapView.delegate respondsToSelector:@selector(mapView:layerForAnnotation:)])
            super.layer = [self.mapView.delegate mapView:self.mapView layerForAnnotation:self];

        if (super.layer)
            self.hasCustomLayer = YES;

        if ( ! super.layer)
            super.layer = [[RMMarker alloc] initWithUIImage:[RMMapView resourceImageNamed:@"TrackingDot.png"]];

        super.layer.zPosition = -MAXFLOAT + 2;
    }

    return super.layer;
}

- (BOOL)isUpdating
{
    return (self.mapView.userTrackingMode != RMUserTrackingModeNone);
}

- (void)setLocation:(CLLocation *)newLocation
{
    if ([newLocation distanceFromLocation:_location] && newLocation.coordinate.latitude != 0 && newLocation.coordinate.longitude != 0)
    {
        [self willChangeValueForKey:@"location"];
        _location = newLocation;
        self.coordinate = _location.coordinate;
        [self didChangeValueForKey:@"location"];
    }
}

- (void)setHeading:(CLHeading *)newHeading
{
    if (newHeading.trueHeading != _heading.trueHeading)
    {
        [self willChangeValueForKey:@"heading"];
        _heading = newHeading;
        [self didChangeValueForKey:@"heading"];
    }
}

- (BOOL)isUserLocationAnnotation
{
    return YES;
}

@end
