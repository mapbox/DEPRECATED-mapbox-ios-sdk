//
//  RMMapView.m
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

#import "RMMapView.h"
#import "RMMapViewDelegate.h"
#import "RMPixel.h"

#import "RMTileLoader.h"

#import "RMMercatorToScreenProjection.h"
#import "RMMarker.h"
#import "RMFoundation.h"
#import "RMProjection.h"
#import "RMMarker.h"
#import "RMPath.h"
#import "RMAnnotation.h"

#import "RMMercatorToScreenProjection.h"
#import "RMMercatorToTileProjection.h"
#import "RMOpenStreetMapSource.h"

#import "RMTileCache.h"
#import "RMTileSource.h"
#import "RMTileLoader.h"
#import "RMTileImageSet.h"

#import "RMCoreAnimationRenderer.h"

#pragma mark --- begin constants ----

#define kDefaultDecelerationFactor .88f
#define kMinDecelerationDelta 0.6f
#define kDecelerationTimerInterval 0.02f

#define kZoomAnimationStepTime 0.03f
#define kZoomAnimationAnimationTime 0.1f
#define kiPhoneMilimeteresPerPixel .1543
#define kZoomRectPixelBuffer 50

#define kMoveAnimationDuration 0.25f
#define kMoveAnimationStepDuration 0.02f

#define kDefaultInitialLatitude -33.858771
#define kDefaultInitialLongitude 151.201596

#define kDefaultMinimumZoomLevel 0.0
#define kDefaultMaximumZoomLevel 25.0
#define kDefaultInitialZoomLevel 13.0

#pragma mark --- end constants ----

@interface RMMapView (PrivateMethods)

@property (nonatomic, retain) RMMapLayer *overlay;

// methods for post-touch deceleration
- (void)startDecelerationWithDelta:(CGSize)delta;
- (void)incrementDeceleration:(NSTimer *)timer;
- (void)stopDeceleration;

- (void)animationFinishedWithZoomFactor:(float)zoomFactor near:(CGPoint)p;
- (void)animationStepped;

- (void)correctPositionOfAllAnnotations;
- (void)correctPositionOfAllAnnotationsIncludingInvisibles:(BOOL)correctAllLayers;

@end

#pragma mark -

@implementation RMMapView

@synthesize decelerationFactor;
@synthesize deceleration;

@synthesize enableDragging;
@synthesize enableZoom;
@synthesize lastGesture;

@synthesize boundingMask;
@synthesize minZoom;
@synthesize maxZoom;
@synthesize screenScale;
@synthesize markerManager;
@synthesize imagesOnScreen;
@synthesize tileCache;

#pragma mark -
#pragma mark Initialization

- (id)initWithFrame:(CGRect)frame
{
	LogMethod();
    return [self initWithFrame:frame andTilesource:[[RMOpenStreetMapSource new] autorelease]];
}

- (id)initWithFrame:(CGRect)frame andTilesource:(id <RMTileSource>)newTilesource
{
	LogMethod();
	CLLocationCoordinate2D coordinate;
	coordinate.latitude = kDefaultInitialLatitude;
	coordinate.longitude = kDefaultInitialLongitude;

	return [self initWithFrame:frame
                 andTilesource:newTilesource
              centerCoordinate:coordinate
                     zoomLevel:kDefaultInitialZoomLevel
                  maxZoomLevel:kDefaultMaximumZoomLevel
                  minZoomLevel:kDefaultMinimumZoomLevel
               backgroundImage:nil];
}

- (id)initWithFrame:(CGRect)frame
      andTilesource:(id <RMTileSource>)newTilesource
   centerCoordinate:(CLLocationCoordinate2D)initialCenterCoordinate
          zoomLevel:(float)initialZoomLevel
       maxZoomLevel:(float)maxZoomLevel
       minZoomLevel:(float)minZoomLevel
    backgroundImage:(UIImage *)backgroundImage
{
    LogMethod();
    if (!(self = [super initWithFrame:frame]))
        return nil;

    enableDragging = YES;
    enableZoom = YES;
    decelerationFactor = kDefaultDecelerationFactor;
    deceleration = NO;

    if (enableZoom)
        [self setMultipleTouchEnabled:TRUE];

    self.backgroundColor = [UIColor grayColor];

	_constrainMovement = NO;

    tileSource = nil;
    projection = nil;
    mercatorToTileProjection = nil;
    renderer = nil;
    imagesOnScreen = nil;
    tileLoader = nil;

    screenScale = 1.0;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
    {
        screenScale = [[[UIScreen mainScreen] valueForKey:@"scale"] floatValue];
    }

    boundingMask = RMMapMinWidthBound;

    mercatorToScreenProjection = [[RMMercatorToScreenProjection alloc] initFromProjection:[newTilesource projection] toScreenBounds:[self bounds]];

    [self setTileCache:[[[RMTileCache alloc] init] autorelease]];
    [self setTileSource:newTilesource];
    [self setRenderer:[[[RMCoreAnimationRenderer alloc] initWithView:self] autorelease]];

    imagesOnScreen = [[RMTileImageSet alloc] initWithDelegate:renderer];
    [imagesOnScreen setTileSource:tileSource];
    [imagesOnScreen setTileCache:tileCache];
    [imagesOnScreen setCurrentCacheKey:[newTilesource uniqueTilecacheKey]];

    tileLoader = [[RMTileLoader alloc] initWithView:self];
    [tileLoader setSuppressLoading:YES];

    [self setMinZoom:minZoomLevel];
    [self setMaxZoom:maxZoomLevel];
    [self setZoom:initialZoomLevel];
    [self moveToCoordinate:initialCenterCoordinate];

    [tileLoader setSuppressLoading:NO];

    /// \bug TODO: Make a nice background class
    [self setBackground:[[[CALayer alloc] init] autorelease]];
    [self setOverlay:[[[RMMapLayer alloc] init] autorelease]];

    annotations = [NSMutableArray new];
    visibleAnnotations = [NSMutableSet new];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMemoryWarningNotification:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];

    RMLog(@"Map initialised. tileSource:%@, renderer:%@, minZoom:%.0f, maxZoom:%.0f", tileSource, renderer, [self minZoom], [self maxZoom]);
    return self;
}

- (void)setFrame:(CGRect)frame
{
    CGRect r = self.frame;
    [super setFrame:frame];

    // only change if the frame changes
    if (!CGRectEqualToRect(r, frame)) {
        CGRect bounds = CGRectMake(0, 0, frame.size.width, frame.size.height);
        [mercatorToScreenProjection setScreenBounds:bounds];
        background.frame = bounds;
        overlay.frame = bounds;
        [tileLoader clearLoadedBounds];
        [tileLoader updateLoadedImages];
        [self correctPositionOfAllAnnotations];
    }
}

- (void)dealloc
{
    LogMethod();
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setDelegate:nil];
    [self stopDeceleration];
    [imagesOnScreen cancelLoading];
    [self setRenderer:nil];
    [self setTileCache:nil];
    [imagesOnScreen release]; imagesOnScreen = nil;
    [tileLoader release]; tileLoader = nil;
    [projection release]; projection = nil;
    [mercatorToTileProjection release]; mercatorToTileProjection = nil;
    [mercatorToScreenProjection release]; mercatorToScreenProjection = nil;
    [tileSource release]; tileSource = nil;
    [self setOverlay:nil];
    [self setBackground:nil];
    [annotations release]; annotations = nil;
    [visibleAnnotations release]; visibleAnnotations = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    LogMethod();
    [tileSource didReceiveMemoryWarning];
    [tileCache didReceiveMemoryWarning];
}

- (void)handleMemoryWarningNotification:(NSNotification *)notification
{
	[self didReceiveMemoryWarning];
}

- (NSString *)description
{
	CGRect bounds = [self bounds];
	return [NSString stringWithFormat:@"MapView at %.0f,%.0f-%.0f,%.0f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height];
}

#pragma mark -
#pragma mark Delegate

@dynamic delegate;

- (void)setDelegate:(id <RMMapViewDelegate>)aDelegate
{
    if (delegate == aDelegate)
        return;

    delegate = aDelegate;

    _delegateHasBeforeMapMove = [delegate respondsToSelector:@selector(beforeMapMove:)];
    _delegateHasAfterMapMove  = [delegate respondsToSelector:@selector(afterMapMove:)];
    _delegateHasAfterMapMoveDeceleration = [delegate respondsToSelector:@selector(afterMapMoveDeceleration:)];

    _delegateHasBeforeMapZoomByFactor = [delegate respondsToSelector:@selector(beforeMapZoom:byFactor:near:)];
    _delegateHasAfterMapZoomByFactor  = [delegate respondsToSelector:@selector(afterMapZoom:byFactor:near:)];

    _delegateHasMapViewRegionDidChange = [delegate respondsToSelector:@selector(mapViewRegionDidChange:)];

    _delegateHasBeforeMapRotate  = [delegate respondsToSelector:@selector(beforeMapRotate:fromAngle:)];
    _delegateHasAfterMapRotate  = [delegate respondsToSelector:@selector(afterMapRotate:toAngle:)];

    _delegateHasDoubleTapOnMap = [delegate respondsToSelector:@selector(doubleTapOnMap:at:)];
    _delegateHasDoubleTapTwoFingersOnMap = [delegate respondsToSelector:@selector(doubleTapTwoFingersOnMap:at:)];
    _delegateHasSingleTapOnMap = [delegate respondsToSelector:@selector(singleTapOnMap:at:)];
    _delegateHasLongSingleTapOnMap = [delegate respondsToSelector:@selector(longSingleTapOnMap:at:)];

    _delegateHasTapOnMarker = [delegate respondsToSelector:@selector(tapOnAnnotation:onMap:)];
    _delegateHasTapOnLabelForMarker = [delegate respondsToSelector:@selector(tapOnLabelForAnnotation:onMap:)];

    _delegateHasAfterMapTouch  = [delegate respondsToSelector:@selector(afterMapTouch:)];

    _delegateHasShouldDragMarker = [delegate respondsToSelector:@selector(mapView:shouldDragAnnotation:withEvent:)];
    _delegateHasDidDragMarker = [delegate respondsToSelector:@selector(mapView:didDragAnnotation:withEvent:)];
}

- (id <RMMapViewDelegate>)delegate
{
	return delegate;
}

#pragma mark -
#pragma mark Tile Source Bounds

- (BOOL)projectedBounds:(RMProjectedRect)bounds containsPoint:(RMProjectedPoint)point
{
    if (bounds.origin.easting > point.easting ||
        bounds.origin.easting + bounds.size.width < point.easting ||
        bounds.origin.northing > point.northing ||
        bounds.origin.northing + bounds.size.height < point.northing)
    {
        return NO;
    }

    return YES;
}

- (RMProjectedRect)projectedRectFromLatitudeLongitudeBounds:(RMSphericalTrapezium)bounds
{
    CLLocationCoordinate2D ne = bounds.northeast;
    CLLocationCoordinate2D sw = bounds.southwest;
    float pixelBuffer = kZoomRectPixelBuffer;
    CLLocationCoordinate2D midpoint = {
        .latitude = (ne.latitude + sw.latitude) / 2,
        .longitude = (ne.longitude + sw.longitude) / 2
    };
    RMProjectedPoint myOrigin = [projection coordinateToProjectedPoint:midpoint];
    RMProjectedPoint nePoint = [projection coordinateToProjectedPoint:ne];
    RMProjectedPoint swPoint = [projection coordinateToProjectedPoint:sw];
    RMProjectedPoint myPoint = {.easting = nePoint.easting - swPoint.easting, .northing = nePoint.northing - swPoint.northing};

    // Create the new zoom layout
    RMProjectedRect zoomRect;

    //Default is with scale = 2.0 mercators/pixel
    zoomRect.size.width = [self screenBounds].size.width * 2.0;
    zoomRect.size.height = [self screenBounds].size.height * 2.0;
    if ((myPoint.easting / [self screenBounds].size.width) < (myPoint.northing / [self screenBounds].size.height))
    {
        if ((myPoint.northing / ([self screenBounds].size.height - pixelBuffer)) > 1)
        {
            zoomRect.size.width = [self screenBounds].size.width * (myPoint.northing / ([self screenBounds].size.height - pixelBuffer));
            zoomRect.size.height = [self screenBounds].size.height * (myPoint.northing / ([self screenBounds].size.height - pixelBuffer));
        }
    }
    else
    {
        if ((myPoint.easting / ([self screenBounds].size.width - pixelBuffer)) > 1)
        {
            zoomRect.size.width = [self screenBounds].size.width * (myPoint.easting / ([self screenBounds].size.width - pixelBuffer));
            zoomRect.size.height = [self screenBounds].size.height * (myPoint.easting / ([self screenBounds].size.width - pixelBuffer));
        }
    }
    myOrigin.easting = myOrigin.easting - (zoomRect.size.width / 2);
    myOrigin.northing = myOrigin.northing - (zoomRect.size.height / 2);

    RMLog(@"Origin is calculated at: %f, %f", [projection projectedPointToCoordinate:myOrigin].latitude, [projection projectedPointToCoordinate:myOrigin].longitude);

    zoomRect.origin = myOrigin;

//    RMLog(@"Origin: x=%f, y=%f, w=%f, h=%f", zoomRect.origin.easting, zoomRect.origin.northing, zoomRect.size.width, zoomRect.size.height);

    return zoomRect;
}

- (BOOL)tileSourceBoundsContainProjectedPoint:(RMProjectedPoint)point
{
    RMSphericalTrapezium bounds = [self.tileSource latitudeLongitudeBoundingBox];
    if (bounds.northeast.latitude == 90 && bounds.northeast.longitude == 180 &&
        bounds.southwest.latitude == -90 && bounds.southwest.longitude == -180) {
        return YES;
    }
    return [self projectedBounds:tileSourceProjectedBounds containsPoint:point];
}

- (BOOL)tileSourceBoundsContainScreenPoint:(CGPoint)point
{
    RMProjectedPoint projectedPoint = [mercatorToScreenProjection projectScreenPointToProjectedPoint:point];
    return [self tileSourceBoundsContainProjectedPoint:projectedPoint];
}

#pragma mark -
#pragma mark Movement

- (void)moveToProjectedPoint:(RMProjectedPoint)aPoint
{
    if (_delegateHasBeforeMapMove) [delegate beforeMapMove:self];
    [self setMapCenterProjectedPoint:aPoint];
    if (_delegateHasAfterMapMove) [delegate afterMapMove:self];
    if (_delegateHasMapViewRegionDidChange) [delegate mapViewRegionDidChange:self];
}

- (void)moveToCoordinate:(CLLocationCoordinate2D)coordinate
{
    if (_delegateHasBeforeMapMove) [delegate beforeMapMove:self];
	RMProjectedPoint projectedPoint = [[self projection] coordinateToProjectedPoint:coordinate];
	[self setMapCenterProjectedPoint:projectedPoint];
    if (_delegateHasAfterMapMove) [delegate afterMapMove:self];
    if (_delegateHasMapViewRegionDidChange) [delegate mapViewRegionDidChange:self];
}

- (void)moveBy:(CGSize)delta andCorrectAllAnnotations:(BOOL)correctAllSublayers
{
    RMProjectedPoint projectedCenter = [mercatorToScreenProjection projectedCenter];
    RMProjectedSize XYDelta = [mercatorToScreenProjection projectScreenSizeToProjectedSize:delta];
    projectedCenter.easting = projectedCenter.easting - XYDelta.width;
    projectedCenter.northing = projectedCenter.northing - XYDelta.height;

    if (![self tileSourceBoundsContainProjectedPoint:projectedCenter])
        return;

	[mercatorToScreenProjection moveScreenBy:delta];
	[imagesOnScreen moveBy:delta];
	[tileLoader moveBy:delta];
	[self correctPositionOfAllAnnotationsIncludingInvisibles:correctAllSublayers];
}

- (void)moveToCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated
{
    if (!animated) {
        [self moveToCoordinate:coordinate];
        return;
    }

    if (_delegateHasBeforeMapMove) [delegate beforeMapMove:self];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        long int steps = lroundf(kMoveAnimationDuration / kMoveAnimationStepDuration);

        while (--steps > 0)
        {
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:kMoveAnimationStepDuration]];

            CGPoint startPoint = [self coordinateToPixel:self.mapCenterCoordinate];
            CGPoint endPoint   = [self coordinateToPixel:coordinate];
            CGPoint delta = CGPointMake((startPoint.x - endPoint.x) / steps, (startPoint.y - endPoint.y) / steps);
            if (delta.x == 0.0 && delta.y == 0.0) return;

            RMLog(@"%d steps from (%f,%f) to final location (%f,%f)", steps, self.mapCenterCoordinate.longitude, self.mapCenterCoordinate.latitude, coordinate.longitude, coordinate.latitude);

            dispatch_sync(dispatch_get_main_queue(), ^{
                [self moveBy:CGSizeMake(delta.x, delta.y) andCorrectAllAnnotations:NO];
            });
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self moveToCoordinate:coordinate];
            if (_delegateHasAfterMapMove) [delegate afterMapMove:self];
            if (_delegateHasAfterMapMoveDeceleration) [delegate afterMapMoveDeceleration:self];
            if (_delegateHasMapViewRegionDidChange) [delegate mapViewRegionDidChange:self];
        });
    });
}

- (void)moveBy:(CGSize)delta isAnimationStep:(BOOL)isAnimationStep
{
    if (_constrainMovement)
    {
        RMMercatorToScreenProjection *mtsp = self.mercatorToScreenProjection;

        // calculate new bounds after move
        RMProjectedRect pBounds = [mtsp projectedBounds];
        RMProjectedSize XYDelta = [mtsp projectScreenSizeToProjectedSize:delta];
        CGSize sizeRatio = CGSizeMake(((delta.width == 0) ? 0 : XYDelta.width / delta.width),
                                      ((delta.height == 0) ? 0 : XYDelta.height / delta.height));
        RMProjectedRect newBounds = pBounds;

        // move the rect by delta
        newBounds.origin.northing -= XYDelta.height;
        newBounds.origin.easting -= XYDelta.width;

        // see if new bounds are within constrained bounds, and constrain if necessary
        BOOL constrained = NO;
        if (newBounds.origin.northing < _southWestConstraint.northing) {
            newBounds.origin.northing = _southWestConstraint.northing;
            constrained = YES;
        }
        if (newBounds.origin.northing + newBounds.size.height > _northEastConstraint.northing) {
            newBounds.origin.northing = _northEastConstraint.northing - newBounds.size.height;
            constrained = YES;
        }
        if (newBounds.origin.easting < _southWestConstraint.easting) {
            newBounds.origin.easting = _southWestConstraint.easting;
            constrained = YES;
        }
        if (newBounds.origin.easting + newBounds.size.width > _northEastConstraint.easting) {
            newBounds.origin.easting = _northEastConstraint.easting - newBounds.size.width;
            constrained = YES;
        }

        if (constrained)
        {
            // Adjust delta to match constraint
            XYDelta.height = pBounds.origin.northing - newBounds.origin.northing;
            XYDelta.width = pBounds.origin.easting - newBounds.origin.easting;
            delta = CGSizeMake(((sizeRatio.width == 0) ? 0 : XYDelta.width / sizeRatio.width), 
                               ((sizeRatio.height == 0) ? 0 : XYDelta.height / sizeRatio.height));
        }
    }

    if (_delegateHasBeforeMapMove) [delegate beforeMapMove:self];
    [self moveBy:delta andCorrectAllAnnotations:!isAnimationStep];
    if (_delegateHasAfterMapMove) [delegate afterMapMove:self];
}

- (void)moveBy:(CGSize)delta
{
    [self moveBy:delta isAnimationStep:NO];
}

- (void)setConstraintsSouthWest:(CLLocationCoordinate2D)sw northEeast:(CLLocationCoordinate2D)ne
{
    RMProjection *proj = self.projection;

    RMProjectedPoint projectedNE = [proj coordinateToProjectedPoint:ne];
    RMProjectedPoint projectedSW = [proj coordinateToProjectedPoint:sw];

    [self setProjectedConstraintsSouthWest:projectedSW northEast:projectedNE];
}

- (void)setProjectedConstraintsSouthWest:(RMProjectedPoint)sw northEast:(RMProjectedPoint)ne
{
    _southWestConstraint = sw;
    _northEastConstraint = ne;
    _constrainMovement = YES;
}

#pragma mark -
#pragma mark Zoom

- (float)adjustedZoomForCurrentBoundingMask:(float)zoomFactor
{
    if (boundingMask == RMMapNoMinBound)
        return zoomFactor;

    double newMPP = self.metersPerPixel / zoomFactor;

    RMProjectedRect mercatorBounds = [[tileSource projection] planetBounds];

    // Check for MinWidthBound
    if (boundingMask & RMMapMinWidthBound)
    {
        double newMapContentsWidth = mercatorBounds.size.width / newMPP;
        double screenBoundsWidth = [self screenBounds].size.width;
        double mapContentWidth;

        if (newMapContentsWidth < screenBoundsWidth)
        {
            // Calculate new zoom facter so that it does not shrink the map any further.
            mapContentWidth = mercatorBounds.size.width / self.metersPerPixel;
            zoomFactor = screenBoundsWidth / mapContentWidth;
        }
    }

    // Check for MinHeightBound
    if (boundingMask & RMMapMinHeightBound)
    {
        double newMapContentsHeight = mercatorBounds.size.height / newMPP;
        double screenBoundsHeight = [self screenBounds].size.height;
        double mapContentHeight;

        if (newMapContentsHeight < screenBoundsHeight)
        {
            // Calculate new zoom facter so that it does not shrink the map any further.
            mapContentHeight = mercatorBounds.size.height / self.metersPerPixel;
            zoomFactor = screenBoundsHeight / mapContentHeight;
        }
    }

    return zoomFactor;
}

- (BOOL)shouldZoomToTargetZoom:(float)targetZoom withZoomFactor:(float)zoomFactor
{
    // bools for syntactical sugar to understand the logic in the if statement below
    BOOL zoomAtMax = ([self zoom] == [self maxZoom]);
    BOOL zoomAtMin = ([self zoom] == [self minZoom]);
    BOOL zoomGreaterMin = ([self zoom] > [self minZoom]);
    BOOL zoomLessMax = ([self zoom] < [self maxZoom]);

    //zooming in zoomFactor > 1
    //zooming out zoomFactor < 1
    if ((zoomGreaterMin && zoomLessMax) || (zoomAtMax && zoomFactor<1) || (zoomAtMin && zoomFactor>1)) {
        return YES;
    } else {
        return NO;
    }
}

// \bug this is a no-op, not a clamp, if new zoom would be outside of minzoom/maxzoom range
- (void)zoomContentByFactor:(float)zoomFactor near:(CGPoint)pivot
{
    if (![self tileSourceBoundsContainScreenPoint:pivot])
        return;

    zoomFactor = [self adjustedZoomForCurrentBoundingMask:zoomFactor];

    // pre-calculate zoom so we can tell if we want to perform it
    float newZoom = [mercatorToTileProjection calculateZoomFromScale:(self.metersPerPixel / zoomFactor)];

    if ((newZoom > minZoom) && (newZoom < maxZoom))
    {
        [mercatorToScreenProjection zoomScreenByFactor:zoomFactor near:pivot];
        [imagesOnScreen zoomByFactor:zoomFactor near:pivot];
        [tileLoader zoomByFactor:zoomFactor near:pivot];
        [self correctPositionOfAllAnnotations];
    }
}

- (void)zoomContentByFactor:(float)zoomFactor near:(CGPoint)pivot animated:(BOOL)animated withCallback:(RMMapView *)callback isAnimationStep:(BOOL)isAnimationStep
{
    if (![self tileSourceBoundsContainScreenPoint:pivot])
        return;

    zoomFactor = [self adjustedZoomForCurrentBoundingMask:zoomFactor];
    float zoomDelta = log2f(zoomFactor);
    float targetZoom = zoomDelta + [self zoom];

    if (targetZoom == [self zoom])
        return;

    // clamp zoom to remain below or equal to maxZoom after zoomAfter will be applied
    // Set targetZoom to maxZoom so the map zooms to its maximum
    if (targetZoom > [self maxZoom]) {
        zoomFactor = exp2f([self maxZoom] - [self zoom]);
        targetZoom = [self maxZoom];
    }

    // clamp zoom to remain above or equal to minZoom after zoomAfter will be applied
    // Set targetZoom to minZoom so the map zooms to its maximum
    if (targetZoom < [self minZoom]) {
        zoomFactor = 1/exp2f([self zoom] - [self minZoom]);
        targetZoom = [self minZoom];
    }

    if ([self shouldZoomToTargetZoom:targetZoom withZoomFactor:zoomFactor])
    {
        if (animated)
        {
            // goal is to complete the animation in animTime seconds
            double nSteps = round(kZoomAnimationAnimationTime / kZoomAnimationStepTime);
            double zoomIncr = zoomDelta / nSteps;

            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithDouble:zoomIncr], @"zoomIncr",
                                      [NSNumber numberWithDouble:targetZoom], @"targetZoom",
                                      [NSValue valueWithCGPoint:pivot], @"pivot",
                                      [NSNumber numberWithFloat:zoomFactor], @"factor",
                                      callback, @"callback",
                                      nil];
            [NSTimer scheduledTimerWithTimeInterval:kZoomAnimationStepTime
                                             target:self
                                           selector:@selector(animatedZoomStep:)
                                           userInfo:userInfo
                                            repeats:YES];
        }
        else
        {
            [mercatorToScreenProjection zoomScreenByFactor:zoomFactor near:pivot];
            [imagesOnScreen zoomByFactor:zoomFactor near:pivot];
            [tileLoader zoomByFactor:zoomFactor near:pivot];
            [self correctPositionOfAllAnnotationsIncludingInvisibles:!isAnimationStep];
        }
    }
    else
    {
        if ([self zoom] > [self maxZoom])
            [self setZoom:[self maxZoom]];
        if ([self zoom] < [self minZoom])
            [self setZoom:[self minZoom]];
    }
}

- (void)zoomContentByFactor:(float)zoomFactor near:(CGPoint)pivot animated:(BOOL)animated
{
    [self zoomContentByFactor:zoomFactor near:pivot animated:animated withCallback:nil isAnimationStep:NO];
}

- (void)animationStepped
{
    if (_delegateHasMapViewRegionDidChange) [delegate mapViewRegionDidChange:self];
}

- (void)animationFinishedWithZoomFactor:(float)zoomFactor near:(CGPoint)p
{
    if (_delegateHasAfterMapZoomByFactor)
        [delegate afterMapZoom:self byFactor:zoomFactor near:p];
}

- (void)animatedZoomStep:(NSTimer *)timer
{
    double zoomIncr = [[[timer userInfo] objectForKey:@"zoomIncr"] doubleValue];
    double targetZoom = [[[timer userInfo] objectForKey:@"targetZoom"] doubleValue];

    NSDictionary *userInfo = [[[timer userInfo] retain] autorelease];
    RMMapView *callback = [userInfo objectForKey:@"callback"];

    if ((zoomIncr > 0 && [self zoom] >= targetZoom-1.0e-6) || (zoomIncr < 0 && [self zoom] <= targetZoom+1.0e-6))
    {
        if ([self zoom] != targetZoom)
            [self setZoom:targetZoom];

        [timer invalidate];	// ASAP
        if ([callback respondsToSelector:@selector(animationFinishedWithZoomFactor:near:)])
            [callback animationFinishedWithZoomFactor:[[userInfo objectForKey:@"factor"] floatValue] near:[[userInfo objectForKey:@"pivot"] CGPointValue]];

        [self correctPositionOfAllAnnotationsIncludingInvisibles:YES];
    }
    else
    {
        float zoomFactorStep = exp2f(zoomIncr);
        [self zoomContentByFactor:zoomFactorStep near:[[[timer userInfo] objectForKey:@"pivot"] CGPointValue] animated:NO withCallback:nil isAnimationStep:YES];
        if ([callback respondsToSelector:@selector(animationStepped)])
            [callback animationStepped];
    }
}

- (float)nextNativeZoomFactor
{
    float newZoom = fminf(floorf([self zoom] + 1.0), [self maxZoom]);
    return exp2f(newZoom - [self zoom]);
}

- (float)previousNativeZoomFactor
{
    float newZoom = fmaxf(floorf([self zoom] - 1.0), [self minZoom]);
    return exp2f(newZoom - [self zoom]);
}

- (void)zoomInToNextNativeZoomAt:(CGPoint)pivot
{
    [self zoomInToNextNativeZoomAt:pivot animated:NO];
}

- (void)zoomInToNextNativeZoomAt:(CGPoint)pivot animated:(BOOL)animated
{
    // Calculate rounded zoom
    float newZoom = fmin(floorf([self zoom] + 1.0), [self maxZoom]);
    RMLog(@"[self minZoom] %f [self zoom] %f [self maxZoom] %f newzoom %f", [self minZoom], [self zoom], [self maxZoom], newZoom);

    float factor = exp2f(newZoom - [self zoom]);
    [self zoomContentByFactor:factor near:pivot animated:animated];
}

- (void)zoomOutToNextNativeZoomAt:(CGPoint)pivot animated:(BOOL) animated
{
    // Calculate rounded zoom
    float newZoom = fmax(ceilf([self zoom] - 1.0), [self minZoom]);
    RMLog(@"[self minZoom] %f [self zoom] %f [self maxZoom] %f newzoom %f", [self minZoom], [self zoom], [self maxZoom], newZoom);

    float factor = exp2f(newZoom - [self zoom]);
    [self zoomContentByFactor:factor near:pivot animated:animated];
}

- (void)zoomOutToNextNativeZoomAt:(CGPoint)pivot
{
	[self zoomOutToNextNativeZoomAt:pivot animated:NO];
}

- (void)zoomByFactor:(float)zoomFactor near:(CGPoint)center animated:(BOOL)animated
{
    if (_constrainMovement)
    {
        // check that bounds after zoom don't exceed map constraints
        // the logic is copued from the method zoomByFactor,
        float _zoomFactor = [self adjustedZoomForCurrentBoundingMask:zoomFactor];
        float zoomDelta = log2f(_zoomFactor);
        float targetZoom = zoomDelta + [self zoom];
        BOOL canZoom = NO;
        if (targetZoom == [self zoom]) {
            //OK... . I could even do a return here.. but it will hamper with future logic..
            canZoom = YES;
        }
        // clamp zoom to remain below or equal to maxZoom after zoomAfter will be applied
        if (targetZoom > [self maxZoom]) {
            zoomFactor = exp2f([self maxZoom] - [self zoom]);
        }

        // clamp zoom to remain above or equal to minZoom after zoomAfter will be applied
        if (targetZoom < [self minZoom]) {
            zoomFactor = 1/exp2f([self zoom] - [self minZoom]);
        }

        // bools for syntactical sugar to understand the logic in the if statement below
        BOOL zoomAtMax = ([self zoom] == [self maxZoom]);
        BOOL zoomAtMin = ([self zoom] == [self minZoom]);
        BOOL zoomGreaterMin = ([self zoom] > [self minZoom]);
        BOOL zoomLessMax = ([self zoom] < [ self maxZoom]);

        //zooming in zoomFactor > 1
        //zooming out zoomFactor < 1
        if ((zoomGreaterMin && zoomLessMax) || (zoomAtMax && zoomFactor<1) || (zoomAtMin && zoomFactor>1))
        {
            // if I'm here it means I could zoom, now we have to see what will happen after zoom
            RMMercatorToScreenProjection *mtsp = self.mercatorToScreenProjection;

            // get copies of mercatorRoScreenProjection's data
            RMProjectedPoint origin = [mtsp origin];
            float metersPerPixel = mtsp.metersPerPixel;
            CGRect screenBounds = [mtsp screenBounds];

            // this is copied from [RMMercatorToScreenBounds zoomScreenByFactor]
            // First we move the origin to the pivot...
            origin.easting += center.x * metersPerPixel;
            origin.northing += (screenBounds.size.height - center.y) * metersPerPixel;

            // Then scale by 1/factor
            metersPerPixel /= _zoomFactor;

            // Then translate back
            origin.easting -= center.x * metersPerPixel;
            origin.northing -= (screenBounds.size.height - center.y) * metersPerPixel;

            origin = [mtsp.projection wrapPointHorizontally:origin];

            // calculate new bounds
            RMProjectedRect zRect;
            zRect.origin = origin;
            zRect.size.width = screenBounds.size.width * metersPerPixel;
            zRect.size.height = screenBounds.size.height * metersPerPixel;

            // can zoom only if within bounds
            canZoom = !(zRect.origin.northing < _southWestConstraint.northing || zRect.origin.northing+zRect.size.height > _northEastConstraint.northing ||
                        zRect.origin.easting < _southWestConstraint.easting || zRect.origin.easting+zRect.size.width > _northEastConstraint.easting);
        }

        if (!canZoom) {
            RMLog(@"Zooming will move map out of bounds: no zoom");
            return;
        }
    }

    if (_delegateHasBeforeMapZoomByFactor) [delegate beforeMapZoom:self byFactor:zoomFactor near:center];
    [self zoomContentByFactor:zoomFactor near:center animated:animated withCallback:((animated && (_delegateHasAfterMapZoomByFactor || _delegateHasMapViewRegionDidChange)) ? self : nil) isAnimationStep:!animated];

    if (!animated) {
        if (_delegateHasAfterMapZoomByFactor) [delegate afterMapZoom:self byFactor:zoomFactor near:center];
        if (_delegateHasMapViewRegionDidChange) [delegate mapViewRegionDidChange:self];
    }
}

- (void)zoomByFactor:(float)zoomFactor near:(CGPoint)center
{
	[self zoomByFactor:zoomFactor near:center animated:NO];
}

#pragma mark -
#pragma mark Zoom With Bounds

- (void)zoomWithLatitudeLongitudeBoundsSouthWest:(CLLocationCoordinate2D)sw northEast:(CLLocationCoordinate2D)ne
{
    if (ne.latitude == sw.latitude && ne.longitude == sw.longitude) //There are no bounds, probably only one marker.
    {
        RMProjectedRect zoomRect;
        RMProjectedPoint myOrigin = [projection coordinateToProjectedPoint:sw];
        // Default is with scale = 2.0 mercators/pixel
        zoomRect.size.width = [self screenBounds].size.width * 2.0;
        zoomRect.size.height = [self screenBounds].size.height * 2.0;
        myOrigin.easting = myOrigin.easting - (zoomRect.size.width / 2);
        myOrigin.northing = myOrigin.northing - (zoomRect.size.height / 2);
        zoomRect.origin = myOrigin;
        [self zoomWithProjectedBounds:zoomRect];
    }
    else
    {
        // Convert ne/sw into RMMercatorRect and call zoomWithBounds
        float pixelBuffer = kZoomRectPixelBuffer;
        CLLocationCoordinate2D midpoint = {
            .latitude = (ne.latitude + sw.latitude) / 2,
            .longitude = (ne.longitude + sw.longitude) / 2
        };
        RMProjectedPoint myOrigin = [projection coordinateToProjectedPoint:midpoint];
        RMProjectedPoint nePoint = [projection coordinateToProjectedPoint:ne];
        RMProjectedPoint swPoint = [projection coordinateToProjectedPoint:sw];
        RMProjectedPoint myPoint = {
            .easting = nePoint.easting - swPoint.easting,
            .northing = nePoint.northing - swPoint.northing
        };

		// Create the new zoom layout
        RMProjectedRect zoomRect;

        // Default is with scale = 2.0 mercators/pixel
        zoomRect.size.width = [self screenBounds].size.width * 2.0;
        zoomRect.size.height = [self screenBounds].size.height * 2.0;
        if ((myPoint.easting / [self screenBounds].size.width) < (myPoint.northing / [self screenBounds].size.height))
        {
            if ((myPoint.northing / ([self screenBounds].size.height - pixelBuffer)) > 1)
            {
                zoomRect.size.width = [self screenBounds].size.width * (myPoint.northing / ([self screenBounds].size.height - pixelBuffer));
                zoomRect.size.height = [self screenBounds].size.height * (myPoint.northing / ([self screenBounds].size.height - pixelBuffer));
            }
        }
        else
        {
            if ((myPoint.easting / ([self screenBounds].size.width - pixelBuffer)) > 1)
            {
                zoomRect.size.width = [self screenBounds].size.width * (myPoint.easting / ([self screenBounds].size.width - pixelBuffer));
                zoomRect.size.height = [self screenBounds].size.height * (myPoint.easting / ([self screenBounds].size.width - pixelBuffer));
            }
        }
        myOrigin.easting = myOrigin.easting - (zoomRect.size.width / 2);
        myOrigin.northing = myOrigin.northing - (zoomRect.size.height / 2);
        RMLog(@"Origin is calculated at: %f, %f", [projection projectedPointToCoordinate:myOrigin].latitude, [projection projectedPointToCoordinate:myOrigin].longitude);

        zoomRect.origin = myOrigin;
        [self zoomWithProjectedBounds:zoomRect];
    }

    [self moveBy:CGSizeZero andCorrectAllAnnotations:YES];
}

- (void)zoomWithProjectedBounds:(RMProjectedRect)bounds
{
    [self setProjectedBounds:bounds];
    [tileLoader clearLoadedBounds];
    [tileLoader updateLoadedImages];
    [self correctPositionOfAllAnnotations];
}

#pragma mark -
#pragma mark Cache

- (void)removeAllCachedImages
{
    [tileCache removeAllCachedImages];
}

#pragma mark -
#pragma mark Properties

- (void)setTileSource:(id <RMTileSource>)newTileSource
{
    if (tileSource == newTileSource)
        return;

    minZoom = newTileSource.minZoom;
    maxZoom = newTileSource.maxZoom + 1;

    [self setZoom:[self zoom]]; // setZoom clamps zoom level to min/max limits

    [tileSource autorelease];
    tileSource = [newTileSource retain];

    if (([tileSource minZoom] - minZoom) <= 1.0) {
        RMLog(@"Graphics & memory are overly taxed if [contents minZoom] is more than 1.5 smaller than [tileSource minZoom]");
    }

    [projection release];
    projection = [[tileSource projection] retain];

    [mercatorToTileProjection release];
    mercatorToTileProjection = [[tileSource mercatorToTileProjection] retain];
    tileSourceProjectedBounds = (RMProjectedRect)[self projectedRectFromLatitudeLongitudeBounds:[tileSource latitudeLongitudeBoundingBox]];

    [imagesOnScreen setTileCache:tileCache];
    [imagesOnScreen setTileSource:tileSource];
    [imagesOnScreen setCurrentCacheKey:[newTileSource uniqueTilecacheKey]];

    [tileLoader reset];
    [tileLoader reload];
}

- (id <RMTileSource>)tileSource
{
    return [[tileSource retain] autorelease];
}

- (void)setRenderer:(RMCoreAnimationRenderer *)newRenderer
{
    if (renderer == newRenderer)
        return;

    [imagesOnScreen setDelegate:newRenderer];

    [[renderer layer] removeFromSuperlayer];
    [renderer release];

    renderer = [newRenderer retain];
    if (renderer == nil)
        return;

    //	CGRect rect = [self screenBounds];
    //	RMLog(@"%f %f %f %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    [[renderer layer] setFrame:[self screenBounds]];

    if (background != nil)
        [self.layer insertSublayer:[renderer layer] above:background];
    else if (overlay != nil)
        [self.layer insertSublayer:[renderer layer] below:overlay];
    else
        [self.layer insertSublayer:[renderer layer] atIndex: 0];
}

- (RMCoreAnimationRenderer *)renderer
{
    return [[renderer retain] autorelease];
}

- (void)setBackground:(CALayer *)aLayer
{
    if (background == aLayer)
        return;

    if (background != nil) {
        [background release];
        [background removeFromSuperlayer];
    }

    background = [aLayer retain];
    if (background == nil)
        return;

    background.frame = [self screenBounds];

    if ([renderer layer] != nil)
        [self.layer insertSublayer:background below:[renderer layer]];
    else if (overlay != nil)
        [self.layer insertSublayer:background below:overlay];
    else
        [self.layer insertSublayer:[renderer layer] atIndex:0];
}

- (CALayer *)background
{
    return [[background retain] autorelease];
}

- (void)setOverlay:(RMMapLayer *)aLayer
{
    if (overlay == aLayer)
        return;

    if (overlay != nil)	{
        [overlay release];
        [overlay removeFromSuperlayer];
    }

    overlay = [aLayer retain];
    if (overlay == nil)
        return;

    overlay.frame = [self screenBounds];
    overlay.masksToBounds = YES;

    if ([renderer layer] != nil)
        [self.layer insertSublayer:overlay above:[renderer layer]];
    else if (background != nil)
        [self.layer insertSublayer:overlay above:background];
    else
        [self.layer insertSublayer:[renderer layer] atIndex:0];
}

- (RMMapLayer *)overlay
{
    return [[overlay retain] autorelease];
}

- (CLLocationCoordinate2D)mapCenterCoordinate
{
    return [projection projectedPointToCoordinate:[mercatorToScreenProjection projectedCenter]];
}

- (void)setMapCenterCoordinate:(CLLocationCoordinate2D)center
{
    [self moveToCoordinate:center];
}

- (RMProjectedPoint)mapCenterProjectedPoint
{
    return [mercatorToScreenProjection projectedCenter];
}

- (void)setMapCenterProjectedPoint:(RMProjectedPoint)projectedPoint
{
    if (![self tileSourceBoundsContainProjectedPoint:projectedPoint])
        return;

    [mercatorToScreenProjection setProjectedCenter:projectedPoint];
    [self correctPositionOfAllAnnotations];
    [tileLoader reload];
    [overlay setNeedsDisplay];
}

- (RMProjectedRect)projectedBounds
{
    return [mercatorToScreenProjection projectedBounds];
}

- (void)setProjectedBounds:(RMProjectedRect)boundsRect
{
    [mercatorToScreenProjection setProjectedBounds:boundsRect];
}

- (RMTileRect)tileBounds
{
    return [mercatorToTileProjection projectRect:[mercatorToScreenProjection projectedBounds] atScale:[self scaledMetersPerPixel]];
}

- (CGRect)screenBounds
{
    if (mercatorToScreenProjection != nil)
        return [mercatorToScreenProjection screenBounds];
    else
        return CGRectZero;
}

- (float)metersPerPixel
{
    return [mercatorToScreenProjection metersPerPixel];
}

- (void)setMetersPerPixel:(float)newMPP
{
    float zoomFactor = self.metersPerPixel / newMPP;
    CGPoint pivot = CGPointZero;

    [mercatorToScreenProjection setMetersPerPixel:newMPP];
    [imagesOnScreen zoomByFactor:zoomFactor near:pivot];
    [tileLoader zoomByFactor:zoomFactor near:pivot];
    [self correctPositionOfAllAnnotations];
}

- (float)scaledMetersPerPixel
{
    return [mercatorToScreenProjection metersPerPixel] / screenScale;
}

- (double)scaleDenominator
{
    double routemeMetersPerPixel = [self metersPerPixel];
    double iphoneMillimetersPerPixel = kiPhoneMilimeteresPerPixel;
    double truescaleDenominator =  routemeMetersPerPixel / (0.001 * iphoneMillimetersPerPixel);
    return truescaleDenominator;
}

- (void)setMaxZoom:(float)newMaxZoom
{
    maxZoom = newMaxZoom;
}

- (void)setMinZoom:(float)newMinZoom
{
    minZoom = newMinZoom;

    if (!tileSource || (([tileSource minZoom] - minZoom) <= 1.0)) {
        RMLog(@"Graphics & memory are overly taxed if [contents minZoom] is more than 1.5 smaller than [tileSource minZoom]");
    }
}

- (float)zoom
{
    return [mercatorToTileProjection calculateZoomFromScale:[mercatorToScreenProjection metersPerPixel]];
}

// if #zoom is outside of range #minZoom to #maxZoom, zoom level is clamped to that range.
- (void)setZoom:(float)zoom
{
    zoom = (zoom > maxZoom) ? maxZoom : zoom;
    zoom = (zoom < minZoom) ? minZoom : zoom;

    float scale = [mercatorToTileProjection calculateScaleFromZoom:zoom];
    [self setMetersPerPixel:scale];
}

- (RMTileImageSet *)imagesOnScreen
{
    return [[imagesOnScreen retain] autorelease];
}

- (RMTileLoader *)tileLoader
{
    return [[tileLoader retain] autorelease];
}

- (RMProjection *)projection
{
    return [[projection retain] autorelease];
}

- (id <RMMercatorToTileProjection>)mercatorToTileProjection
{
    return [[mercatorToTileProjection retain] autorelease];
}

- (RMMercatorToScreenProjection *)mercatorToScreenProjection
{
    return [[mercatorToScreenProjection retain] autorelease];
}

#pragma mark -
#pragma mark LatLng/Pixel translation functions

- (CGPoint)coordinateToPixel:(CLLocationCoordinate2D)latlong
{
    return [mercatorToScreenProjection projectProjectedPoint:[projection coordinateToProjectedPoint:latlong]];
}

- (CGPoint)coordinateToPixel:(CLLocationCoordinate2D)latlong withMetersPerPixel:(float)aScale
{
    return [mercatorToScreenProjection projectProjectedPoint:[projection coordinateToProjectedPoint:latlong] withMetersPerPixel:aScale];
}

- (RMTilePoint)coordinateToTilePoint:(CLLocationCoordinate2D)latlong withMetersPerPixel:(float)aScale
{
    return [mercatorToTileProjection project:[projection coordinateToProjectedPoint:latlong] atZoom:aScale];
}

- (CLLocationCoordinate2D)pixelToCoordinate:(CGPoint)aPixel
{
    return [projection projectedPointToCoordinate:[mercatorToScreenProjection projectScreenPointToProjectedPoint:aPixel]];
}

- (CLLocationCoordinate2D)pixelToCoordinate:(CGPoint)aPixel withMetersPerPixel:(float)aScale
{
    return [projection projectedPointToCoordinate:[mercatorToScreenProjection projectScreenPointToProjectedPoint:aPixel withMetersPerPixel:aScale]];
}

#pragma mark -
#pragma mark Markers and overlays

- (RMSphericalTrapezium)latitudeLongitudeBoundingBoxForScreen
{
    return [self latitudeLongitudeBoundingBoxFor:[mercatorToScreenProjection screenBounds]];
}

- (RMSphericalTrapezium)latitudeLongitudeBoundingBoxFor:(CGRect)rect
{
    RMSphericalTrapezium boundingBox;
    CGPoint northwestScreen = rect.origin;

    CGPoint southeastScreen;
    southeastScreen.x = rect.origin.x + rect.size.width;
    southeastScreen.y = rect.origin.y + rect.size.height;

    CGPoint northeastScreen, southwestScreen;
    northeastScreen.x = southeastScreen.x;
    northeastScreen.y = northwestScreen.y;
    southwestScreen.x = northwestScreen.x;
    southwestScreen.y = southeastScreen.y;

    CLLocationCoordinate2D northeastLL, northwestLL, southeastLL, southwestLL;
    northeastLL = [self pixelToCoordinate:northeastScreen];
    northwestLL = [self pixelToCoordinate:northwestScreen];
    southeastLL = [self pixelToCoordinate:southeastScreen];
    southwestLL = [self pixelToCoordinate:southwestScreen];

    boundingBox.northeast.latitude = fmax(northeastLL.latitude, northwestLL.latitude);
    boundingBox.southwest.latitude = fmin(southeastLL.latitude, southwestLL.latitude);

    // westerly computations:
    // -179, -178 -> -179 (min)
    // -179, 179  -> 179 (max)
    if (fabs(northwestLL.longitude - southwestLL.longitude) <= kMaxLong)
        boundingBox.southwest.longitude = fmin(northwestLL.longitude, southwestLL.longitude);
    else
        boundingBox.southwest.longitude = fmax(northwestLL.longitude, southwestLL.longitude);

    if (fabs(northeastLL.longitude - southeastLL.longitude) <= kMaxLong)
        boundingBox.northeast.longitude = fmax(northeastLL.longitude, southeastLL.longitude);
    else
        boundingBox.northeast.longitude = fmin(northeastLL.longitude, southeastLL.longitude);

    return boundingBox;
}

- (void)printDebuggingInformation
{
    [imagesOnScreen printDebuggingInformation];
}

- (short)tileDepth
{
    return imagesOnScreen.tileDepth;
}

- (void)setTileDepth:(short)value
{
    imagesOnScreen.tileDepth = value;
}

- (BOOL)fullyLoaded
{
    return imagesOnScreen.fullyLoaded;
}

#pragma mark -
#pragma mark Annotations

- (void)correctScreenPosition:(RMAnnotation *)annotation
{
    annotation.position = [[self mercatorToScreenProjection] projectProjectedPoint:[annotation projectedLocation]];
}

- (void)correctPositionOfAllAnnotationsIncludingInvisibles:(BOOL)correctAllAnnotations
{
    CGRect screenBounds = [[self mercatorToScreenProjection] screenBounds];
    CALayer *lastLayer = nil;

    @synchronized (annotations)
    {
        if (correctAllAnnotations)
        {
            for (RMAnnotation *annotation in annotations)
            {
                [self correctScreenPosition:annotation];
                if ([annotation isAnnotationWithinBounds:screenBounds]) {
                    if (annotation.layer == nil)
                        annotation.layer = [delegate mapView:self layerForAnnotation:annotation];
                    if (annotation.layer == nil)
                        continue;

                    if (![visibleAnnotations containsObject:annotation]) {
                        if (!lastLayer)
                            [overlay insertSublayer:annotation.layer atIndex:0];
                        else
                            [overlay insertSublayer:annotation.layer above:lastLayer];

                        [visibleAnnotations addObject:annotation];
                    }
                } else {
                    annotation.layer = nil;
                    [visibleAnnotations removeObject:annotation];
                }
                lastLayer = annotation.layer;
            }
            RMLog(@"%d annotations on screen, %d total", [[overlay sublayers] count], [annotations count]);
        } else {
            for (RMAnnotation *annotation in visibleAnnotations)
            {
                [self correctScreenPosition:annotation];
            }
            RMLog(@"%d annotations corrected", [visibleAnnotations count]);
        }
    }
}

- (void)correctPositionOfAllAnnotations
{
    [self correctPositionOfAllAnnotationsIncludingInvisibles:YES];
}

- (NSArray *)annotations
{
    return annotations;
}

- (void)addAnnotation:(RMAnnotation *)annotation
{
    @synchronized (annotations) {
        [annotations addObject:annotation];
    }
    [self correctScreenPosition:annotation];

    if ([annotation isAnnotationOnScreen]) {
        annotation.layer = [delegate mapView:self layerForAnnotation:annotation];
        if (annotation.layer) {
            [overlay addSublayer:annotation.layer];
            [visibleAnnotations addObject:annotation];
        }
    }
}

- (void)addAnnotations:(NSArray *)newAnnotations
{
    @synchronized (annotations) {
        for (RMAnnotation *annotation in newAnnotations)
        {
            [annotations addObject:annotation];
        }
    }
    [self correctPositionOfAllAnnotationsIncludingInvisibles:YES];
}

- (void)removeAnnotation:(RMAnnotation *)annotation
{
    @synchronized (annotations) {
        [annotations removeObject:annotation];
        [visibleAnnotations removeObject:annotation];
    }

    // Remove the layer from the screen
    annotation.layer = nil;
}

- (void)removeAnnotations:(NSArray *)newAnnotations
{
    for (RMAnnotation *annotation in newAnnotations)
    {
        [self removeAnnotation:annotation];
    }
}

- (void)removeAllAnnotations
{
    @synchronized (annotations) {
        for (RMAnnotation *annotation in annotations)
        {
            // Remove the layer from the screen
            annotation.layer = nil;
        }
    }

    [annotations removeAllObjects];
    [visibleAnnotations removeAllObjects];
}

- (CGPoint)screenCoordinatesForAnnotation:(RMAnnotation *)annotation
{
    [self correctScreenPosition:annotation];
    return annotation.position;
}

#pragma mark -
#pragma mark Event handling

- (RMGestureDetails)gestureDetails:(NSSet *)touches
{
    RMGestureDetails gesture;
    gesture.center.x = gesture.center.y = 0;
    gesture.averageDistanceFromCenter = 0;
    gesture.angle = 0.0;

    int interestingTouches = 0;

    for (UITouch *touch in touches)
    {
        if ([touch phase] != UITouchPhaseBegan
            && [touch phase] != UITouchPhaseMoved
            && [touch phase] != UITouchPhaseStationary)
            continue;
        // RMLog(@"phase = %d", [touch phase]);

        interestingTouches++;

        CGPoint location = [touch locationInView: self];

        gesture.center.x += location.x;
        gesture.center.y += location.y;
    }

    if (interestingTouches == 0)
    {
        gesture.center = lastGesture.center;
        gesture.numTouches = 0;
        gesture.averageDistanceFromCenter = 0.0f;
        return gesture;
    }

    //	RMLog(@"interestingTouches = %d", interestingTouches);

    gesture.center.x /= interestingTouches;
    gesture.center.y /= interestingTouches;

    for (UITouch *touch in touches)
    {
        if ([touch phase] != UITouchPhaseBegan
            && [touch phase] != UITouchPhaseMoved
            && [touch phase] != UITouchPhaseStationary)
            continue;

        CGPoint location = [touch locationInView: self];

        //		RMLog(@"For touch at %.0f, %.0f:", location.x, location.y);
        float dx = location.x - gesture.center.x;
        float dy = location.y - gesture.center.y;
        //		RMLog(@"delta = %.0f, %.0f  distance = %f", dx, dy, sqrtf((dx*dx) + (dy*dy)));
        gesture.averageDistanceFromCenter += sqrtf((dx*dx) + (dy*dy));
    }

    gesture.averageDistanceFromCenter /= interestingTouches;
    gesture.numTouches = interestingTouches;

    if ([touches count] == 2)
    {
        CGPoint first = [[[touches allObjects] objectAtIndex:0] locationInView:[self superview]];
        CGPoint second = [[[touches allObjects] objectAtIndex:1] locationInView:[self superview]];
        CGFloat height = second.y - first.y;
        CGFloat width = first.x - second.x;
        gesture.angle = atan2(height,width);
    }

    return gesture;
}

- (void)handleLongPress
{
    if (deceleration && _decelerationTimer != nil)
        return;

    if (_delegateHasLongSingleTapOnMap)
        [delegate longSingleTapOnMap:self at:_longPressPosition];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[touches allObjects] objectAtIndex:0];
    //Check if the touch hit a RMMarker subclass and if so, forward the touch event on
    //so it can be handled there
    id furthestLayerDown = [self.overlay hitTest:[touch locationInView:self]];
    if ([[furthestLayerDown class]isSubclassOfClass: [RMMarker class]]) {
        if ([furthestLayerDown respondsToSelector:@selector(touchesBegan:withEvent:)]) {
            [furthestLayerDown performSelector:@selector(touchesBegan:withEvent:) withObject:touches withObject:event];
            return;
        }
    }

    //	RMLog(@"touchesBegan %d", [[event allTouches] count]);
    lastGesture = [self gestureDetails:[event allTouches]];

    if (deceleration && _decelerationTimer != nil) {
        [self stopDeceleration];
    }

    _longPressPosition = lastGesture.center;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleLongPress) object:nil];

    if (lastGesture.numTouches == 1) {
        CALayer* hit = [self.overlay hitTest:[touch locationInView:self]];
        if (!hit || ![hit isKindOfClass: [RMMarker class]]) {            
            [self performSelector:@selector(handleLongPress) withObject:nil afterDelay:0.5];
        }
    }
}

// \bug touchesCancelled should clean up, not pass event to markers
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[touches allObjects] objectAtIndex:0];

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleLongPress) object:nil];

    // Check if the touch hit a RMMarker subclass and if so, forward the touch event on
    // so it can be handled there
    id furthestLayerDown = [self.overlay hitTest:[touch locationInView:self]];
    if ([[furthestLayerDown class]isSubclassOfClass: [RMMarker class]]) {
        if ([furthestLayerDown respondsToSelector:@selector(touchesCancelled:withEvent:)]) {
            [furthestLayerDown performSelector:@selector(touchesCancelled:withEvent:) withObject:touches withObject:event];
            return;
        }
    }

    // I don't understand what the difference between this and touchesEnded is.
    [self touchesEnded:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[touches allObjects] objectAtIndex:0];

    //Check if the touch hit a RMMarker subclass and if so, forward the touch event on
    //so it can be handled there
    id furthestLayerDown = [self.overlay hitTest:[touch locationInView:self]];
    if ([[furthestLayerDown class]isSubclassOfClass: [RMMarker class]]) {
        if ([furthestLayerDown respondsToSelector:@selector(touchesEnded:withEvent:)]) {
            [furthestLayerDown performSelector:@selector(touchesEnded:withEvent:) withObject:touches withObject:event];
            return;
        }
    }
    NSInteger lastTouches = lastGesture.numTouches;

    // Calculate the gesture.
    lastGesture = [self gestureDetails:[event allTouches]];

    BOOL decelerating = NO;

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleLongPress) object:nil];

    if (touch.tapCount >= 2)
    {
        BOOL twoFingerTap = [touches count] >= 2;
        if (_delegateHasDoubleTapOnMap) {
            if (twoFingerTap) {
                if (_delegateHasDoubleTapTwoFingersOnMap) [delegate doubleTapTwoFingersOnMap:self at:lastGesture.center];
            } else {
                if (_delegateHasDoubleTapOnMap) [delegate doubleTapOnMap: self at:lastGesture.center];
            }
        } else {
            // Default behaviour matches built in maps.app
            float nextZoomFactor = 0;
            if (twoFingerTap) {
                nextZoomFactor = [self previousNativeZoomFactor];
            } else {
                nextZoomFactor = [self nextNativeZoomFactor];
            }
            if (nextZoomFactor != 0)
                [self zoomByFactor:nextZoomFactor near:[touch locationInView:self] animated:YES];
        }
    } else if (lastTouches == 1 && touch.tapCount != 1) {
        // deceleration
        if (deceleration && enableDragging)
        {
            CGPoint prevLocation = [touch previousLocationInView:self];
            CGPoint currLocation = [touch locationInView:self];
            CGSize touchDelta = CGSizeMake(currLocation.x - prevLocation.x, currLocation.y - prevLocation.y);
            [self startDecelerationWithDelta:touchDelta];
            decelerating = YES;
        }
    }

    if (touch.tapCount == 1) 
    {
        if (lastGesture.numTouches == 0)
        {
            CALayer *hit = [self.overlay hitTest:[touch locationInView:self]];
            // RMLog(@"LAYER of type %@",[hit description]);

            if (hit != nil)
            {
                CALayer *superlayer = [hit superlayer];

                // See if tap was on a marker or marker label and send delegate protocol method
                if ([hit isKindOfClass:[RMMarker class]]) {
                    if (_delegateHasTapOnMarker) {
                        [delegate tapOnAnnotation:((RMMarker *)hit).annotation onMap:self];
                    }
                } else if (superlayer != nil && [superlayer isKindOfClass: [RMMarker class]]) {
                    if (_delegateHasTapOnLabelForMarker) {
                        [delegate tapOnLabelForAnnotation:((RMMarker *)superlayer).annotation onMap:self];
                    }
                } else if ([superlayer superlayer] != nil && [[superlayer superlayer] isKindOfClass:[RMMarker class]]) {
                    if (_delegateHasTapOnLabelForMarker) {
                        [delegate tapOnLabelForAnnotation:((RMMarker *)[superlayer superlayer]).annotation onMap:self];
                    }
                } else if (_delegateHasSingleTapOnMap) {
                    [delegate singleTapOnMap:self at:[touch locationInView:self]];
                }
            }
        }
        else if (!enableDragging && (lastGesture.numTouches == 1))
        {
            float prevZoomFactor = [self previousNativeZoomFactor];
            if (prevZoomFactor != 0)
                [self zoomByFactor:prevZoomFactor near:[touch locationInView:self] animated:YES];
        }
    }

    if (_delegateHasAfterMapTouch) [delegate afterMapTouch:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[touches allObjects] objectAtIndex:0];

    //Check if the touch hit a RMMarker subclass and if so, forward the touch event on
    //so it can be handled there
    id furthestLayerDown = [self.overlay hitTest:[touch locationInView:self]];
    if ([[furthestLayerDown class]isSubclassOfClass: [RMMarker class]]) {
        if ([furthestLayerDown respondsToSelector:@selector(touchesMoved:withEvent:)]) {
            [furthestLayerDown performSelector:@selector(touchesMoved:withEvent:) withObject:touches withObject:event];
            return;
        }
    }

    RMGestureDetails newGesture = [self gestureDetails:[event allTouches]];
    CGPoint newLongPressPosition = newGesture.center;
    CGFloat dx = newLongPressPosition.x - _longPressPosition.x;
    CGFloat dy = newLongPressPosition.y - _longPressPosition.y;
    if (sqrt(dx*dx + dy*dy) > 5.0)
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleLongPress) object:nil];

    CALayer *hit = [self.overlay hitTest:[touch locationInView:self]];
//	RMLog(@"LAYER of type %@",[hit description]);

    if (hit != nil)
    {   
        if ([hit isKindOfClass: [RMMarker class]]) {
            if (!_delegateHasShouldDragMarker || (_delegateHasShouldDragMarker && [delegate mapView:self shouldDragAnnotation:((RMMarker *)hit).annotation withEvent:event]))
            {
                if (_delegateHasDidDragMarker) {
                    [delegate mapView:self didDragAnnotation:((RMMarker *)hit).annotation withEvent:event];
                    return;
                }
            }
        }
    }

    if (newGesture.numTouches == lastGesture.numTouches)
    {
        CGSize delta;
        delta.width = newGesture.center.x - lastGesture.center.x;
        delta.height = newGesture.center.y - lastGesture.center.y;

        if (enableZoom && newGesture.numTouches > 1)
        {
            NSAssert (lastGesture.averageDistanceFromCenter > 0.0f && newGesture.averageDistanceFromCenter > 0.0f,
                      @"Distance from center is zero despite >1 touches on the screen");

            double zoomFactor = newGesture.averageDistanceFromCenter / lastGesture.averageDistanceFromCenter;

            [self moveBy:delta];
            [self zoomByFactor:zoomFactor near:newGesture.center];
        }
        else if (enableDragging)
        {
            [self moveBy:delta];
        }
    }

    lastGesture = newGesture;
}

#pragma mark Deceleration

- (void)startDecelerationWithDelta:(CGSize)delta
{
    if (fabsf(delta.width) >= 1.0f && fabsf(delta.height) >= 1.0f)
    {
        _decelerationDelta = delta;
        if ( !_decelerationTimer ) {
            _decelerationTimer = [NSTimer scheduledTimerWithTimeInterval:kDecelerationTimerInterval
                                                                  target:self
                                                                selector:@selector(incrementDeceleration:) 
                                                                userInfo:nil 
                                                                 repeats:YES];
        }
    }
}

- (void)incrementDeceleration:(NSTimer *)timer
{
    if (fabsf(_decelerationDelta.width) < kMinDecelerationDelta && fabsf(_decelerationDelta.height) < kMinDecelerationDelta) {
        [self stopDeceleration];
        return;
    }

    // avoid calling delegate methods? design call here
    [self moveBy:_decelerationDelta isAnimationStep:YES];

    _decelerationDelta.width *= self.decelerationFactor;
    _decelerationDelta.height *= self.decelerationFactor;
}

- (void)stopDeceleration
{
    if (_decelerationTimer != nil) {
        [_decelerationTimer invalidate]; _decelerationTimer = nil;
        _decelerationDelta = CGSizeZero;

        // call delegate methods; design call (see above)
        [self moveBy:CGSizeZero];
    }

    if (_delegateHasAfterMapMoveDeceleration)
        [delegate afterMapMoveDeceleration:self];
}

@end
