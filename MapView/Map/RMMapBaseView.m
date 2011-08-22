//
//  RMMapBaseView.m
//  MapView
//
//  Created by Thomas Rasch on 17.08.11.
//  Copyright (c) 2011 Alpstein. All rights reserved.
//

#import "RMMapBaseView.h"

#import "RMMapView.h"
#import "RMProjection.h"
#import "RMMapTiledLayerView.h"
#import "RMTileSource.h"

static CGPoint mapContentOffset;

@implementation RMMapBaseView

@synthesize tiledLayerView;

- (id)initWithFrame:(CGRect)frame mapView:(RMMapView *)aMapView initialProjectedCenter:(RMProjectedPoint)initialCenter
{
    if (!(self = [super initWithFrame:frame]))
        return nil;

    mapView = aMapView;

    int tileSideLength = [[mapView tileSource] tileSideLength];
    CGSize contentSize = CGSizeMake(2.0*tileSideLength, 2.0*tileSideLength);

    self.delegate = self;
    self.backgroundColor = [UIColor clearColor];
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.minimumZoomScale = [[mapView tileSource] minZoom];
    self.maximumZoomScale = 1 << (int)[[mapView tileSource] maxZoom];
    self.zoomScale = [mapView zoom];
    self.contentSize = contentSize;
    self.contentOffset = CGPointMake(0.0, 0.0);

    self.tiledLayerView = [[[RMMapTiledLayerView alloc] initWithFrame:CGRectMake(0.0, 0.0, contentSize.width, contentSize.height) mapView:aMapView] autorelease];
	self.tiledLayerView.contentScaleFactor = 1.0;
    [self addSubview:self.tiledLayerView];

    return self;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.tiledLayerView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    NSLog(@"scale: %f", floor(log2(scale) + 2.0));
}

- (void)setProjectedCenter:(RMProjectedPoint)aPoint
{
    self.contentOffset = CGPointMake(aPoint.x + mapContentOffset.x, aPoint.y + mapContentOffset.y);
    NSLog(@"setProjectedCenter: {%.0f,%.0f}", self.contentOffset.x, self.contentOffset.y);
}

@end
