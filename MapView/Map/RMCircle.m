///
//  RMCircle.m
//
// Copyright (c) 2008-2010, Route-Me Contributors
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

#import "RMCircle.h"
#import "RMProjection.h"
#import "RMMapView.h"

#define kDefaultLineWidth 10.0
#define kDefaultLineColor [UIColor blackColor]
#define kDefaultFillColor [UIColor blueColor]

@interface RMCircle ()

- (void)updateCirclePath;

@end

#pragma mark -

@implementation RMCircle

@synthesize shapeLayer;
@synthesize lineColor;
@synthesize fillColor;
@synthesize radiusInMeters;
@synthesize lineWidthInPixels;

- (id)initWithView:(RMMapView *)aMapView radiusInMeters:(CGFloat)newRadiusInMeters
{
    if (!(self = [super init]))
        return nil;

    shapeLayer = [[CAShapeLayer alloc] init];
    [self addSublayer:shapeLayer];

    [self addAnimation:[CABasicAnimation animationWithKeyPath:@"sublayers"] forKey:@"sublayers"];
    
    mapView = aMapView;
    radiusInMeters = newRadiusInMeters;

    lineWidthInPixels = kDefaultLineWidth;
    lineColor = kDefaultLineColor;
    fillColor = kDefaultFillColor;

    scaleLineWidth = NO;
    enableDragging = YES;

    circlePath = NULL;
    [self updateCirclePath];

    return self;
}

- (void)dealloc
{
    mapView = nil;
    [shapeLayer release]; shapeLayer = nil;
    CGPathRelease(circlePath); circlePath = NULL;
    [lineColor release]; lineColor = nil;
    [fillColor release]; fillColor = nil;
    [super dealloc];
}

#pragma mark -

- (void)updateCirclePath
{
    CGPathRelease(circlePath); circlePath = NULL;

    CGMutablePathRef newPath = CGPathCreateMutable();

    CGFloat latRadians = [[mapView projection] projectedPointToCoordinate:projectedLocation].latitude * M_PI / 180.0f;
    CGFloat pixelRadius = radiusInMeters / cos(latRadians) / [mapView metersPerPixel];
    //	DLog(@"Pixel Radius: %f", pixelRadius);

    CGRect rectangle = CGRectMake(self.position.x - pixelRadius,
                                  self.position.y - pixelRadius,
                                  (pixelRadius * 2),
                                  (pixelRadius * 2));

    CGFloat offset = floorf(-lineWidthInPixels / 2.0f) - 2;
    CGRect newBoundsRect = CGRectInset(rectangle, offset, offset);
    
    BOOL sizeChanged = ( ! isnan(newBoundsRect.size.width) && ! isnan(newBoundsRect.size.height) && ! CGSizeEqualToSize(self.bounds.size, newBoundsRect.size));
        
    [self setBounds:newBoundsRect];

    //	DLog(@"Circle Rectangle: %f, %f, %f, %f", rectangle.origin.x, rectangle.origin.y, rectangle.size.width, rectangle.size.height);
    //	DLog(@"Bounds Rectangle: %f, %f, %f, %f", self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);

    CGPathAddEllipseInRect(newPath, NULL, rectangle);
    circlePath = newPath;

    if (sizeChanged)
    {
        CAShapeLayer *newShapeLayer = [[[CAShapeLayer alloc] init] autorelease];
        
        [newShapeLayer setPath:newPath];
        [newShapeLayer setFillColor:[fillColor CGColor]];
        [newShapeLayer setStrokeColor:[lineColor CGColor]];
        [newShapeLayer setLineWidth:lineWidthInPixels];
        
        [self addSublayer:newShapeLayer];
        [self.shapeLayer removeFromSuperlayer];
        self.shapeLayer = newShapeLayer;
    }
    else
    {
        [self.shapeLayer setPath:newPath];
        [self.shapeLayer setFillColor:[fillColor CGColor]];
        [self.shapeLayer setStrokeColor:[lineColor CGColor]];
        [self.shapeLayer setLineWidth:lineWidthInPixels];
    }
}

#pragma mark - Accessors

- (void)setLineColor:(UIColor *)newLineColor
{
    if (lineColor != newLineColor)
    {
        [lineColor release];
        lineColor = [newLineColor retain];
        [self updateCirclePath];
    }
}

- (void)setFillColor:(UIColor *)newFillColor
{
    if (fillColor != newFillColor)
    {
        [fillColor release];
        fillColor = [newFillColor retain];
        [self updateCirclePath];
    }
}

- (void)setRadiusInMeters:(CGFloat)newRadiusInMeters
{
    radiusInMeters = newRadiusInMeters;
    [self updateCirclePath];
}

- (void)setLineWidthInPixels:(CGFloat)newLineWidthInPixels
{
    lineWidthInPixels = newLineWidthInPixels;
    [self updateCirclePath];
}

- (void)setPosition:(CGPoint)position
{
    [super setPosition:position];

    [self updateCirclePath];
}

@end
