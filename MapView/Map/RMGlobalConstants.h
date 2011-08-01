/*
 *  RMGlobalConstants.h
 *  MapView
 *
 *  Created by My Home on 4/29/09.
 *  Copyright 2009 Brandon "Quazie" Kwaselow. All rights reserved.
 *
 */

#import <CoreLocation/CoreLocation.h>

#ifndef _GLOBAL_CONSTANTS_H_
#define _GLOBAL_CONSTANTS_H_

#define kMaxLong 180 
#define kMaxLat 90

typedef struct {
	CLLocationCoordinate2D southWest;
	CLLocationCoordinate2D northEast;
} RMSphericalTrapezium;

static const double kRMMinLatitude = -kMaxLat;
static const double kRMMaxLatitude = kMaxLat;
static const double kRMMinLongitude = -kMaxLong;
static const double kRMMaxLongitude = kMaxLong;

#endif
