//
//  RMUserLocation.h
//  MapView
//
//  Created by Justin Miller on 5/8/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import "RMAnnotation.h"

@interface RMUserLocation : RMAnnotation

@property (nonatomic, readonly, getter=isUpdating) BOOL updating;
@property (nonatomic, readonly, retain) CLLocation *location;
@property (nonatomic, readonly, retain) CLHeading *heading;

@end
