//
//  RMMapBaseView.h
//  MapView
//
//  Created by Thomas Rasch on 17.08.11.
//  Copyright (c) 2011 Alpstein. All rights reserved.
//

#import "RMFoundation.h"

@class RMMapTiledLayerView, RMMapView;

@interface RMMapBaseView : UIScrollView <UIScrollViewDelegate> {
    RMMapView *mapView;
}

@property (nonatomic, retain) RMMapTiledLayerView *tiledLayerView;

- (id)initWithFrame:(CGRect)frame mapView:(RMMapView *)aMapView initialProjectedCenter:(RMProjectedPoint)initialCenter;

- (void)setProjectedCenter:(RMProjectedPoint)aPoint;

@end
