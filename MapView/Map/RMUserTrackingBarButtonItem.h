//
//  RMUserTrackingBarButtonItem.h
//  MapView
//
//  Created by Justin Miller on 5/10/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RMMapView;

@interface RMUserTrackingBarButtonItem : UIBarButtonItem

- (id)initWithMapView:(RMMapView *)mapView;

@property (nonatomic, retain) RMMapView *mapView;

@end
