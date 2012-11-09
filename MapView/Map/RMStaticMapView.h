//
//  RMStaticMapView.h
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

#import <UIKit/UIKit.h>

/** An RMStaticMapView object provides an embeddable, static map image view. You use this class to display map information in your application that does not need to change or provide user interaction. You can center the map on a given coordinate and zoom level, specify the size of the area you want to display, and optionally provide callbacks that can be performed on map image retrieval success or failure.
 *
 *  @warning Please note that you are responsible for getting permission to use the map data, and for ensuring your use adheres to the relevant terms of use. */
@interface RMStaticMapView : UIImageView

/** @name Initializing a Static Map View */

/** Initialize a static map view with a given frame, mapID, center coordinate, and zoom level.
 *  @param frame The frame with which to initialize the map view.
 *  @param mapID The MapBox map ID string, typically in the format `<username>.map-<random characters>`.
 *  @param centerCoordinate The map center coordinate.
 *  @param zoomLevel The map zoom level.
 *  @return An initialized map view, or `nil` if the map view was unable to be initialized. */
- (id)initWithFrame:(CGRect)frame mapID:(NSString *)mapID centerCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(CGFloat)zoomLevel;

/** Initialize a static map view with a given frame, mapID, center coordinate, and zoom level, performing success or failure callbacks based on retrieval of the map image.
 *  @param frame The frame with which to initialize the map view.
 *  @param mapID The MapBox map ID string, typically in the format `<username>.map-<random characters>`.
 *  @param centerCoordinate The map center coordinate.
 *  @param zoomLevel The map zoom level.
 *  @param successBlock A block to be performed upon map image retrieval success. The map image is passed as an argument to the block in the event that you wish to use it elsewhere or modify it.
 *  @param failureBlock A block to be performed upon map image retrieval failure. The retrieval error is passed as an argument to the block. 
 *  @return An initialized map view, or `nil` if the map view was unable to be initialized. */
- (id)initWithFrame:(CGRect)frame mapID:(NSString *)mapID centerCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(CGFloat)zoomLevel success:(void (^)(UIImage *))successBlock failure:(void (^)(NSError *))failureBlock;

/** @name Fine-Tuning the Map Appearance */

/** A Boolean value indicating whether to show a small logo in the corner of the map view. Defaults to `YES`. */
@property (nonatomic, assign) BOOL showLogoBug;

// TODO: markers
// TODO: attribution

@end
