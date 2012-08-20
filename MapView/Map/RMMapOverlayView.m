//
//  RMMapOverlayView.m
//  MapView
//
//  Created by Thomas Rasch on 25.08.11.
//  Copyright (c) 2011 Alpstein. All rights reserved.
//

#import "RMMapOverlayView.h"
#import "RMMarker.h"
#import "RMAnnotation.h"
#import "RMPixel.h"
#import "RMMapView.h"

@implementation RMMapOverlayView
{
    RMAnnotation *_userLocationAnnotation;
    RMAnnotation *_accuracyCircleAnnotation;
    RMAnnotation *_trackingHaloAnnotation;
}

+ (Class)layerClass
{
    return [CAScrollLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;

    self.layer.masksToBounds = NO;

    return self;
}

- (unsigned)sublayersCount
{
    return [self.layer.sublayers count];
}

- (void)addSublayer:(CALayer *)aLayer
{
    [self.layer addSublayer:aLayer];
}

- (void)insertSublayer:(CALayer *)aLayer atIndex:(unsigned)index
{
    [self.layer insertSublayer:aLayer atIndex:index];
}

- (void)insertSublayer:(CALayer *)aLayer below:(CALayer *)sublayer
{
    [self.layer insertSublayer:aLayer below:sublayer];
}

- (void)insertSublayer:(CALayer *)aLayer above:(CALayer *)sublayer
{
    [self.layer insertSublayer:aLayer above:sublayer];
}

- (void)moveLayersBy:(CGPoint)delta
{
    [self.layer scrollPoint:CGPointMake(-delta.x, -delta.y)];
}

- (CALayer *)overlayHitTest:(CGPoint)point
{
    RMMapView *mapView = ((RMMapView *)self.superview);

    if ( ! _userLocationAnnotation)
        _userLocationAnnotation = (RMAnnotation *)mapView.userLocation;

    if ( ! _accuracyCircleAnnotation)
        for (RMAnnotation *annotation in mapView.annotations)
            if ([annotation.annotationType isEqualToString:kRMAccuracyCircleAnnotationTypeName])
                _accuracyCircleAnnotation = annotation;

    if ( ! _trackingHaloAnnotation)
        for (RMAnnotation *annotation in mapView.annotations)
            if ([annotation.annotationType isEqualToString:kRMTrackingHaloAnnotationTypeName])
                _trackingHaloAnnotation = annotation;

    // here we hide the accuracy circle & tracking halo to exclude from hit
    // testing, as well as be sure to show the user location (even if in
    // heading mode) to ensure hits on it
    //
    BOOL flag = _userLocationAnnotation.layer.isHidden;

    _userLocationAnnotation.layer.hidden = NO;

    _accuracyCircleAnnotation.layer.hidden = _trackingHaloAnnotation.layer.hidden = YES;

    CALayer *hit = [self.layer hitTest:point];

    _userLocationAnnotation.layer.hidden = flag;

    _accuracyCircleAnnotation.layer.hidden = _trackingHaloAnnotation.layer.hidden = NO;

    return hit;
}

@end
