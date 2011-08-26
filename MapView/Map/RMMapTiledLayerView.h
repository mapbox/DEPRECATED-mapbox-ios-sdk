//
//  RMMapTiledLayerView.h
//  MapView
//
//  Created by Thomas Rasch on 17.08.11.
//  Copyright (c) 2011 Alpstein. All rights reserved.
//

@class RMMapView, RMMapTiledLayerView;

@protocol RMMapTiledLayerViewDelegate <NSObject>
@optional

- (void)mapTiledLayerView:(RMMapTiledLayerView *)aMapOverlayView doubleTapAtPoint:(CGPoint)aPoint;
- (void)mapTiledLayerView:(RMMapTiledLayerView *)aMapOverlayView twoFingerDoubleTapAtPoint:(CGPoint)aPoint;

@end

@interface RMMapTiledLayerView : UIView {
    id <RMMapTiledLayerViewDelegate> delegate;
    RMMapView *mapView;
}

@property (nonatomic, assign) id <RMMapTiledLayerViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame mapView:(RMMapView *)aMapView;

@end
