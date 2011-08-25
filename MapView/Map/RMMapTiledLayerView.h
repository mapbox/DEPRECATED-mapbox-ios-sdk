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

- (void)tiledLayerView:(RMMapTiledLayerView *)aTiledLayerView singleTapAtPoint:(CGPoint)aPoint;
- (void)tiledLayerView:(RMMapTiledLayerView *)aTiledLayerView doubleTapAtPoint:(CGPoint)aPoint;
- (void)tiledLayerView:(RMMapTiledLayerView *)aTiledLayerView twoFingerTapAtPoint:(CGPoint)aPoint;

@end

@interface RMMapTiledLayerView : UIView {
    id <RMMapTiledLayerViewDelegate> delegate;

    RMMapView *mapView;
    BOOL twoFingerTapIsPossible, multipleTouches;
    CGPoint tapLocation;
}

@property (nonatomic, assign) id <RMMapTiledLayerViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame mapView:(RMMapView *)aMapView;

@end
