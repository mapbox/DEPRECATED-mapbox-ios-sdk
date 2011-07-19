//
//  RMMapView.h
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

/*! \mainpage Route-Me Map Framework 

\section intro_sec Introduction

Route-Me is an open source Objective-C framework for displaying maps on Cocoa Touch devices 
(the iPhone, and the iPod Touch). It was written in 2008 by Joseph Gentle as the basis for a transit
routing app. The transit app was not completed, because the government agencies involved chose not to release
the necessary data under reasonable licensing terms. The project was released as open source under the New BSD license (http://www.opensource.org/licenses/bsd-license.php) 
in September, 2008, and
is hosted on Google Code (http://code.google.com/p/route-me/).

 Route-Me provides a UIView subclass with a panning, zooming map. Zoom level, source of map data, map center,
 marker overlays, and path overlays are all supported.
 \section license_sec License
 Route-Me is licensed under the New BSD license.
 
 In any app that uses the Route-Me library, include the following text on your "preferences" or "about" screen: "Uses Route-Me map library, (c) 2008-2009 Route-Me Contributors". 
 
\section install_sec Installation
 
Because Route-Me is under rapid development as of early 2009, the best way to install Route-Me is use
Subversion and check out a copy of the repository:
\verbatim
svn checkout http://route-me.googlecode.com/svn/trunk/ route-me-read-only
\endverbatim

 There are numerous sample applications in the Subversion repository.
 
 To embed Route-Me maps in your Xcode project, follow the example given in samples/SampleMap or samples/ProgrammaticMap. The instructions in 
 the Embedding Guide at 
 http://code.google.com/p/route-me/wiki/EmbeddingGuide are out of date as of April 20, 2009. To create a static version of Route-Me, follow these 
 instructions instead: http://code.google.com/p/route-me/source/browse/trunk/MapView/README-library-build.rtf
 
\section maps_sec Map Data
 
 Route-Me supports map data served from many different sources:
 - the Open Street Map project's server.
 - CloudMade, which provides commercial servers delivering Open Street Map data.
 - Microsoft Virtual Earth.
 - Open Aerial Map.
 - Yahoo! Maps.
 
 Each of these data sources has different license restrictions and fees. In particular, Yahoo! Maps are 
 effectively unusable in Route-Me due to their license terms; the Yahoo! access code is provided for demonstration
 purposes only.
 
 You must contact the data vendor directly and arrange licensing if necessary, including obtaining your own
 access key. Follow their rules.
 
 If you have your own data you'd like to use with Route-Me, serving it through your own Mapnik installation
 looks like the best bet. Mapnik is an open source web-based map delivery platform. For more information on
 Mapnik, see http://www.mapnik.org/ .
 
 \section news_sec Project News and Updates
 For the most current information on Route-Me, see these sources:
 - wiki: http://code.google.com/p/route-me/w/list
 - project email reflector: http://groups.google.com/group/route-me-map
 - list of all project RSS feeds: http://code.google.com/p/route-me/feeds
 - applications using Route-Me: http://code.google.com/p/route-me/wiki/RoutemeApplications
 
 */

#import <UIKit/UIKit.h>
#import <CoreGraphics/CGGeometry.h>

#import "RMGlobalConstants.h"
#import "RMNotifications.h"
#import "RMFoundation.h"
#import "RMMapViewDelegate.h"
#import "RMTile.h"

// iPhone-specific mapview stuff. Handles event handling, whatnot.
typedef struct {
    CGPoint center;
    CGFloat angle;
    float averageDistanceFromCenter;
    int numTouches;
} RMGestureDetails;

// constants for boundingMask
enum {
    RMMapNoMinBound		= 0, // Map can be zoomed out past view limits
    RMMapMinHeightBound	= 1, // Minimum map height when zooming out restricted to view height
    RMMapMinWidthBound	= 2  // Minimum map width when zooming out restricted to view width (default)
};

@class RMMarkerManager;
@class RMProjection;
@class RMMercatorToScreenProjection;
@class RMTileCache;
@class RMTileImageSet;
@class RMTileLoader;
@class RMCoreAnimationRenderer;
@class RMMapLayer;
@class RMMarkerLayer;
@class RMMarker;
@protocol RMMercatorToTileProjection;
@protocol RMTileSource;

@interface RMMapView : UIView
{
    id <RMMapViewDelegate> delegate;

    BOOL enableDragging;
    BOOL enableZoom;
    BOOL deceleration;
    float decelerationFactor;

    RMGestureDetails lastGesture;

    /// projection objects to convert from latitude/longitude to meters,
    /// from projected meters to tiles and screen coordinates
    RMProjection *projection;
    id <RMMercatorToTileProjection> mercatorToTileProjection;
    RMMercatorToScreenProjection *mercatorToScreenProjection;

    RMMarkerManager *markerManager;
    RMMarkerLayer *overlay; /// subview for markers and paths
    RMCoreAnimationRenderer *renderer;
    RMTileImageSet *imagesOnScreen;
    RMTileLoader *tileLoader;

    id <RMTileSource> tileSource;
    RMTileCache *tileCache; // Generic tile cache

    /// subview for the image displayed while tiles are loading. Set its contents by providing your own "loading.png".
    CALayer *background;

    /// minimum and maximum zoom number allowed for the view. #minZoom and #maxZoom must be within the limits of #tileSource but can be stricter; they are clamped to tilesource limits if needed.
    float minZoom;
    float maxZoom;
    float screenScale;

    NSUInteger boundingMask;
    RMProjectedRect tileSourceProjectedBounds;

@private
    BOOL _delegateHasBeforeMapMove;
    BOOL _delegateHasAfterMapMove;
    BOOL _delegateHasAfterMapMoveDeceleration;
    BOOL _delegateHasBeforeMapZoomByFactor;
    BOOL _delegateHasAfterMapZoomByFactor;
    BOOL _delegateHasMapViewRegionDidChange;
    BOOL _delegateHasBeforeMapRotate;
    BOOL _delegateHasAfterMapRotate;
    BOOL _delegateHasDoubleTapOnMap;
    BOOL _delegateHasDoubleTapTwoFingersOnMap;
    BOOL _delegateHasSingleTapOnMap;
    BOOL _delegateHasLongSingleTapOnMap;
    BOOL _delegateHasTapOnMarker;
    BOOL _delegateHasTapOnLabelForMarker;
    BOOL _delegateHasAfterMapTouch;
    BOOL _delegateHasShouldDragMarker;
    BOOL _delegateHasDidDragMarker;

    NSTimer *_decelerationTimer;
    CGSize _decelerationDelta;
    CGPoint _longPressPosition;

    BOOL _constrainMovement;
    RMProjectedPoint _northEastConstraint, _southWestConstraint;
}

@property (nonatomic, assign) id <RMMapViewDelegate> delegate;

// View properties
@property (nonatomic, assign) BOOL enableDragging;
@property (nonatomic, assign) BOOL enableZoom;
@property (nonatomic, assign) BOOL deceleration;
@property (nonatomic, assign) float decelerationFactor;
@property (nonatomic, readonly) RMGestureDetails lastGesture;

@property (nonatomic, assign) CLLocationCoordinate2D mapCenterCoordinate;
@property (nonatomic, assign) RMProjectedPoint mapCenterProjectedPoint;
@property (nonatomic, assign) RMProjectedRect projectedBounds;
@property (nonatomic, readonly) RMTileRect tileBounds;
@property (nonatomic, readonly) CGRect screenBounds;
@property (nonatomic, assign) float metersPerPixel;
@property (nonatomic, readonly) float scaledMetersPerPixel;
@property (nonatomic, readonly) double scaleDenominator; /// The denominator in a cartographic scale like 1/24000, 1/50000, 1/2000000.
@property (nonatomic, readonly) float screenScale;

@property (nonatomic, assign) float zoom; /// zoom level is clamped to range (minZoom, maxZoom)
@property (nonatomic, assign) float minZoom;
@property (nonatomic, assign) float maxZoom;

@property (nonatomic, readonly) RMMarkerManager *markerManager;
@property (nonatomic, readonly) RMMarkerLayer *overlay;

@property (nonatomic, readonly) RMTileImageSet *imagesOnScreen;
@property (nonatomic, readonly) RMTileLoader *tileLoader;

@property (nonatomic, readonly) RMProjection *projection;
@property (nonatomic, readonly) id <RMMercatorToTileProjection> mercatorToTileProjection;
@property (nonatomic, readonly) RMMercatorToScreenProjection *mercatorToScreenProjection;

@property (nonatomic, retain) id <RMTileSource> tileSource;
@property (nonatomic, retain) RMTileCache *tileCache;
@property (nonatomic, retain) RMCoreAnimationRenderer *renderer;

@property (nonatomic, retain) CALayer *background;

@property (nonatomic, assign) NSUInteger boundingMask;

// tileDepth defaults to zero. if tiles have no alpha, set this higher, 3 or so, to make zooming smoother
@property (nonatomic, assign) short tileDepth;
@property (nonatomic, readonly) BOOL fullyLoaded;

#pragma mark -
#pragma mark Initializers

- (id)initWithFrame:(CGRect)frame andTilesource:(id <RMTileSource>)newTilesource;

/// designated initializer
- (id)initWithFrame:(CGRect)frame
      andTilesource:(id <RMTileSource>)newTilesource
   centerCoordinate:(CLLocationCoordinate2D)initialCenterCoordinate
          zoomLevel:(float)initialZoomLevel
       maxZoomLevel:(float)maxZoomLevel
       minZoomLevel:(float)minZoomLevel
    backgroundImage:(UIImage *)backgroundImage;

- (void)setFrame:(CGRect)frame;

#pragma mark -
#pragma mark Movement

/// recenter the map on #coordinate, expressed as CLLocationCoordinate2D (latitude/longitude)
- (void)moveToCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)moveToCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated;

/// recenter the map on #aPoint, expressed in projected meters
- (void)moveToProjectedPoint:(RMProjectedPoint)aPoint;

- (void)moveBy:(CGSize)delta;

- (void)setConstraintsSouthWest:(CLLocationCoordinate2D)sw northEeast:(CLLocationCoordinate2D)ne;
- (void)setProjectedConstraintsSouthWest:(RMProjectedPoint)sw northEast:(RMProjectedPoint)ne;

#pragma mark -
#pragma mark Zoom

- (void)zoomByFactor:(float)zoomFactor near:(CGPoint)aPoint;
- (void)zoomByFactor:(float)zoomFactor near:(CGPoint)center animated:(BOOL)animated;

- (void)zoomInToNextNativeZoomAt:(CGPoint)pivot;
- (void)zoomInToNextNativeZoomAt:(CGPoint)pivot animated:(BOOL)animated;
- (void)zoomOutToNextNativeZoomAt:(CGPoint)pivot;
- (void)zoomOutToNextNativeZoomAt:(CGPoint)pivot animated:(BOOL)animated;

- (void)zoomWithLatitudeLongitudeBoundsSouthWest:(CLLocationCoordinate2D)sw northEast:(CLLocationCoordinate2D)ne;
- (void)zoomWithProjectedBounds:(RMProjectedRect)bounds;

- (float)nextNativeZoomFactor;
- (float)previousNativeZoomFactor;
- (float)adjustedZoomForCurrentBoundingMask:(float)zoomFactor;

#pragma mark -
#pragma mark Conversions

- (CGPoint)coordinateToPixel:(CLLocationCoordinate2D)coordinate;
- (CGPoint)coordinateToPixel:(CLLocationCoordinate2D)coordinate withMetersPerPixel:(float)aScale;
- (RMTilePoint)coordinateToTilePoint:(CLLocationCoordinate2D)coordinate withMetersPerPixel:(float)aScale;
- (CLLocationCoordinate2D)pixelToCoordinate:(CGPoint)aPixel;
- (CLLocationCoordinate2D)pixelToCoordinate:(CGPoint)aPixel withMetersPerPixel:(float)aScale;

/// returns the smallest bounding box containing the entire screen
- (RMSphericalTrapezium)latitudeLongitudeBoundingBoxForScreen;
/// returns the smallest bounding box containing a rectangular region of the screen
- (RMSphericalTrapezium)latitudeLongitudeBoundingBoxFor:(CGRect) rect;

- (BOOL)projectedBounds:(RMProjectedRect)bounds containsPoint:(RMProjectedPoint)point;
- (BOOL)tileSourceBoundsContainProjectedPoint:(RMProjectedPoint)point;

#pragma mark -
#pragma mark Cache

///  Clear all images from the #tileSource's caching system.
-(void)removeAllCachedImages;

@end
