//
//  MapViewViewController.m
//
// Copyright (c) 2008, Route-Me Contributors
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

#import "MapViewViewController.h"

#import "RMFoundation.h"
#import "RMMarker.h"
#import "RMAnnotation.h"

@implementation MapViewViewController

@synthesize mapView;
@synthesize locationManager;
@synthesize currentLocation;
@synthesize tap;
@synthesize tapCount;

- (void)testMarkers
{
	NSArray	*annotations = [mapView annotations];

	NSLog(@"Nb markers %d", [annotations count]);

	for (RMAnnotation *annotation in annotations)
    {
        [mapView removeAnnotation:annotation];
    }

	// Put the marker back
    RMAnnotation *annotation = [RMAnnotation annotationWithMapView:mapView coordinate:[mapView centerCoordinate] andTitle:@"Hello"];
    annotation.annotationIcon = [UIImage imageNamed:@"marker-blue.png"];
    [mapView addAnnotation:annotation];
}

- (BOOL)mapView:(RMMapView *)map shouldDragAnnotation:(RMAnnotation *)annotation withEvent:(UIEvent *)event
{
   //If you do not implement this function, then all drags on markers will be sent to the didDragMarker function.
   //If you always return YES you will get the same result
   //If you always return NO you will never get a call to the didDragMarker function
   return YES;
}

- (void)mapView:(RMMapView *)map didDragAnnotation:(RMAnnotation *)annotation withEvent:(UIEvent *)event
{
    if ([[event allTouches] count] == 1) 
    {
        UITouch *touch = [[event allTouches] anyObject];
        if (touch.phase == UITouchPhaseMoved) 
        {
            CGPoint currentPosition = [touch locationInView:mapView];
            CGPoint previousPosition = [touch previousLocationInView:mapView];
            CGPoint screenPosition = annotation.position;
            screenPosition.x += (currentPosition.x - previousPosition.x);
            screenPosition.y += (currentPosition.y - previousPosition.y);
            
            CLLocationCoordinate2D newCoordinate = [mapView pixelToCoordinate:screenPosition];
            NSLog(@"New location latitude:%lf longitude:%lf", newCoordinate.latitude, newCoordinate.longitude);
            annotation.coordinate = newCoordinate;
        }
    }
}

- (void)singleTapOnMap:(RMMapView *)map at:(CGPoint)point
{
	NSLog(@"Clicked on Map - New location: X:%lf Y:%lf", point.x, point.y);
}

- (void)tapOnAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map
{
	NSLog(@"MARKER TAPPED!");
    
	if (!tap)
	{
        annotation.annotationIcon = [UIImage imageNamed:@"marker-red.png"];
        [(RMMarker *)annotation.layer replaceUIImage:annotation.annotationIcon];
		[(RMMarker *)annotation.layer changeLabelUsingText:@"World"];
		tap = YES;
        annotation.coordinate = [mapView pixelToCoordinate:CGPointMake(annotation.position.x,annotation.position.y + 20.0)];
		mapView.decelerationMode = RMMapDecelerationNormal;
	} else
	{
        annotation.annotationIcon = [UIImage imageNamed:@"marker-blue.png"];
        annotation.anchorPoint = CGPointMake(0.5, 1.0);
        [(RMMarker *)annotation.layer replaceUIImage:annotation.annotationIcon anchorPoint:annotation.anchorPoint];
		[(RMMarker *)annotation.layer changeLabelUsingText:@"Hello"];
        annotation.coordinate = [mapView pixelToCoordinate:CGPointMake(annotation.position.x,annotation.position.y - 20.0)];
		tap = NO;
		mapView.decelerationMode = RMMapDecelerationOff;
	}
}

- (void)tapOnLabelForAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map
{
	NSLog(@"Label <%@, RC:%d> tapped for marker <%@, RC:%d>",  ((RMMarker *)annotation.layer).label, [((RMMarker *)annotation.layer).label retainCount], (RMMarker *)annotation.layer, [(RMMarker *)annotation.layer retainCount]);
	[(RMMarker *)annotation.layer changeLabelUsingText:[NSString stringWithFormat:@"Tapped! (%U)", ++tapCount]];
}

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation
{
    RMMarker *marker = [[[RMMarker alloc] initWithUIImage:annotation.annotationIcon anchorPoint:annotation.anchorPoint] autorelease];
    if (annotation.title)
        [marker changeLabelUsingText:annotation.title];
    if ([annotation.userInfo objectForKey:@"foregroundColor"])
        [marker setTextForegroundColor:[annotation.userInfo objectForKey:@"foregroundColor"]];
    return marker;
}

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad 
{
    [super viewDidLoad];

	locationManager	= [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	if (locationManager.locationServicesEnabled == NO)
	{
		NSLog(@"Services not enabled");
		return;
	}

	currentLocation.latitude = 33.413313;
	currentLocation.longitude = -111.907326;

	[locationManager startUpdatingLocation];

	tap = NO;

	mapView.delegate = self;
	mapView.backgroundColor = [UIColor grayColor];  //or clear etc 

	if (locationManager.location != nil)
	{
		currentLocation = locationManager.location.coordinate;
		NSLog(@"Location: Lat: %lf Lon: %lf", currentLocation.latitude, currentLocation.longitude);
	}

	[mapView setCenterCoordinate:currentLocation]; 
	[self.view addSubview:mapView]; 

    RMAnnotation *annotation = [RMAnnotation annotationWithMapView:mapView coordinate:currentLocation andTitle:@"Hello"];
    annotation.annotationIcon = [UIImage imageNamed:@"marker-blue.png"];
    annotation.anchorPoint = CGPointMake(0.5, 1.0);
    annotation.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIColor blueColor],@"foregroundColor",
                           nil];
    [mapView addAnnotation:annotation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

- (void)dealloc 
{
	[mapView release];
	[locationManager stopUpdatingLocation];
	[locationManager release];
    [super dealloc];
}

#pragma mark --
#pragma mark locationManagerDelegate Methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	NSLog(@"Moving from lat: %lf lon: %lf to lat: %lf lon: %lf", 
		  oldLocation.coordinate.latitude, oldLocation.coordinate.longitude,
		  newLocation.coordinate.latitude, newLocation.coordinate.longitude);

	currentLocation = newLocation.coordinate;

	NSArray *annotations = [mapView annotations];
    for (RMAnnotation *annotation in annotations)
	{
		CLLocationCoordinate2D location = annotation.coordinate;
		if (location.latitude == oldLocation.coordinate.latitude &&
			location.longitude == oldLocation.coordinate.longitude)
		{
            annotation.coordinate = location;
			break; // We're done. 
		}
	}

	[mapView setCenterCoordinate:currentLocation]; 
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSLog(@"Location Manager error: %@", [error localizedDescription]);
}

@end
