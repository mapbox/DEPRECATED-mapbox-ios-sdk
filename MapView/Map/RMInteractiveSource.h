//
//  RMInteractiveSource.h
//
//  Created by Justin R. Miller on 6/22/11.
//  Copyright 2012 MapBox.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//  
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//  
//      * Neither the name of MapBox, nor the names of its contributors may be
//        used to endorse or promote products derived from this software
//        without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  Based on the UTFGrid specification: https://github.com/mapbox/utfgrid-spec
//

#import "RMMapView.h"
#import "RMMBTilesSource.h"
#import "RMMapBoxSource.h"

// Interactivity currently supports two types of output: 'teaser'
// and 'full'. Ideal for master/detail interfaces or for showing
// a MapKit-style detail-toggling point callout. 

typedef enum {
    RMInteractiveSourceOutputTypeTeaser = 0,
    RMInteractiveSourceOutputTypeFull   = 1,
} RMInteractiveSourceOutputType;

@protocol RMInteractiveMapView 

@required

// Query if a map view supports interactivity features.
//
- (BOOL)supportsInteractivity;

// Get the HTML-formatted output for a given point on a given map view.
//
- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point;

@end

#pragma mark -

@interface RMMapView (RMInteractiveSource) <RMInteractiveMapView>

- (BOOL)supportsInteractivity;
- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point;

@end

#pragma mark -

@protocol RMInteractiveSource

@required

// Query if a tile source supports interactivity features.
//
- (BOOL)supportsInteractivity;

// Get the HTML-formatted output for a given point on a given map view.
//
- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point inMapView:(RMMapView *)mapView;

@end

#pragma mark -

@interface RMMBTilesSource (RMInteractiveSource) <RMInteractiveSource>

- (BOOL)supportsInteractivity;
- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point inMapView:(RMMapView *)mapView;

@end

#pragma mark -

@interface RMMapBoxSource (RMInteractiveSource) <RMInteractiveSource>

- (BOOL)supportsInteractivity;
- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point inMapView:(RMMapView *)mapView;

@end
