//
//  RMMapTiledLayerView.h
//  MapView
//
//  Created by Thomas Rasch on 17.08.11.
//  Copyright (c) 2011 Alpstein. All rights reserved.
//

#import "RMTileSource.h"

@class RMMapView, RMMapTiledLayerView;

@protocol RMMapTiledLayerViewDelegate <NSObject>
@optional

// points are in the mapview coordinate space
- (void)mapTiledLayerView:(RMMapTiledLayerView *)aTiledLayerView singleTapAtPoint:(CGPoint)aPoint;
- (void)mapTiledLayerView:(RMMapTiledLayerView *)aTiledLayerView doubleTapAtPoint:(CGPoint)aPoint;
- (void)mapTiledLayerView:(RMMapTiledLayerView *)aTiledLayerView twoFingerSingleTapAtPoint:(CGPoint)aPoint;
- (void)mapTiledLayerView:(RMMapTiledLayerView *)aTiledLayerView twoFingerDoubleTapAtPoint:(CGPoint)aPoint;
- (void)mapTiledLayerView:(RMMapTiledLayerView *)aTiledLayerView longPressAtPoint:(CGPoint)aPoint;

@end

@interface RMMapTiledLayerView : UIView

@property (nonatomic, assign) id <RMMapTiledLayerViewDelegate> delegate;

@property (nonatomic, assign) BOOL useSnapshotRenderer;

- (id)initWithFrame:(CGRect)frame mapView:(RMMapView *)aMapView forTileSource:(id <RMTileSource>)aTileSource;

@end
