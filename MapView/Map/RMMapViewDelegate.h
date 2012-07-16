//
//  RMMapViewDelegate.h
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

@class RMMapView;
@class RMMapLayer;
@class RMMarker;
@class RMAnnotation;
@class RMUserLocation;

typedef enum {
    RMUserTrackingModeNone              = 0,
    RMUserTrackingModeFollow            = 1,
    RMUserTrackingModeFollowWithHeading = 2
} RMUserTrackingMode;

// Use this for notifications of map panning, zooming, and taps on the RMMapView.
@protocol RMMapViewDelegate <NSObject>
@optional

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation;
- (void)mapView:(RMMapView *)mapView willHideLayerForAnnotation:(RMAnnotation *)annotation;
- (void)mapView:(RMMapView *)mapView didHideLayerForAnnotation:(RMAnnotation *)annotation;

- (void)beforeMapMove:(RMMapView *)map;
- (void)afterMapMove:(RMMapView *)map;

- (void)beforeMapZoom:(RMMapView *)map;
- (void)afterMapZoom:(RMMapView *)map;

/*
 \brief Tells the delegate that the region displayed by the map view just changed.
 \details This method is called whenever the currently displayed map region changes.
 During scrolling and zooming, this method may be called many times to report updates to the map position.
 Therefore, your implementation of this method should be as lightweight as possible to avoid affecting scrolling and zooming performance.
 */
- (void)mapViewRegionDidChange:(RMMapView *)mapView;

- (void)doubleTapOnMap:(RMMapView *)map at:(CGPoint)point;
- (void)doubleTapTwoFingersOnMap:(RMMapView *)map at:(CGPoint)point;
- (void)singleTapOnMap:(RMMapView *)map at:(CGPoint)point;
- (void)singleTapTwoFingersOnMap:(RMMapView *)map at:(CGPoint)point;
- (void)longSingleTapOnMap:(RMMapView *)map at:(CGPoint)point;

- (void)tapOnAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map;
- (void)doubleTapOnAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map;
- (void)tapOnLabelForAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map;
- (void)doubleTapOnLabelForAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map;

- (BOOL)mapView:(RMMapView *)map shouldDragAnnotation:(RMAnnotation *)annotation;
- (void)mapView:(RMMapView *)map didDragAnnotation:(RMAnnotation *)annotation withDelta:(CGPoint)delta;
- (void)mapView:(RMMapView *)map didEndDragAnnotation:(RMAnnotation *)annotation;

- (void)mapViewWillStartLocatingUser:(RMMapView *)mapView;
- (void)mapViewDidStopLocatingUser:(RMMapView *)mapView;
- (void)mapView:(RMMapView *)mapView didUpdateUserLocation:(RMUserLocation *)userLocation;
- (void)mapView:(RMMapView *)mapView didFailToLocateUserWithError:(NSError *)error;
- (void)mapView:(RMMapView *)mapView didChangeUserTrackingMode:(RMUserTrackingMode)mode animated:(BOOL)animated;

@end
