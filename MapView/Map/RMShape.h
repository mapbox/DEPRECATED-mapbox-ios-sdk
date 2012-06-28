//
//  RMShape.h
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

#import "RMFoundation.h"
#import "RMMapLayer.h"

@class RMMapView;

@interface RMShape : RMMapLayer
{
    CGRect pathBoundingBox;

    /// Width of the line, in pixels
    float lineWidth;

    // Line dash style
    NSArray *lineDashLengths;
    CGFloat lineDashPhase;

    BOOL scaleLineWidth;
    BOOL scaleLineDash; // if YES line dashes will be scaled to keep a constant size if the layer is zoomed
}

- (id)initWithView:(RMMapView *)aMapView;

@property (nonatomic, retain) NSString *fillRule;
@property (nonatomic, retain) NSString *lineCap;
@property (nonatomic, retain) NSString *lineJoin;
@property (nonatomic, retain) UIColor *lineColor;
@property (nonatomic, retain) UIColor *fillColor;

@property (nonatomic, assign) NSArray *lineDashLengths;
@property (nonatomic, assign) CGFloat lineDashPhase;
@property (nonatomic, assign) BOOL scaleLineDash;
@property (nonatomic, assign) float lineWidth;
@property (nonatomic, assign) BOOL	scaleLineWidth;
@property (nonatomic, assign) CGFloat shadowBlur;
@property (nonatomic, assign) CGSize shadowOffset;
@property (nonatomic, assign) BOOL enableShadow;

@property (nonatomic, readonly) CGRect pathBoundingBox;

- (void)moveToProjectedPoint:(RMProjectedPoint)projectedPoint;
- (void)moveToScreenPoint:(CGPoint)point;
- (void)moveToCoordinate:(CLLocationCoordinate2D)coordinate;

- (void)addLineToProjectedPoint:(RMProjectedPoint)projectedPoint;
- (void)addLineToScreenPoint:(CGPoint)point;
- (void)addLineToCoordinate:(CLLocationCoordinate2D)coordinate;

// Change the path without recalculating the geometry (performance!)
- (void)performBatchOperations:(void (^)(RMShape *aPath))block;

/// This closes the path, connecting the last point to the first.
/// After this action, no further points can be added to the path.
/// There is no requirement that a path be closed.
- (void)closePath;

@end
