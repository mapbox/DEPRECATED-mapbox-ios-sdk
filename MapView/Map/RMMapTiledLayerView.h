//
//  RMMapTiledLayerView.h
//  MapView
//
//  Created by Thomas Rasch on 17.08.11.
//  Copyright (c) 2011 Alpstein. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RMMapView;

@interface RMMapTiledLayerView : UIView {
    RMMapView *mapView;
}

- (id)initWithFrame:(CGRect)frame mapView:(RMMapView *)aMapView;

@end
