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

- (void)testMarkers
{
	NSArray *annotations = [mapView annotations];
	
	NSLog(@"Nb annotations %d", [annotations count]);
	
    for (RMAnnotation *annotation in annotations)
	{
		RMProjectedPoint point = annotation.projectedLocation;
		NSLog(@"Marker projected location: east:%lf, north:%lf", point.x, point.y);
    
		CGPoint screenPoint = annotation.position;
		NSLog(@"Marker screen location: X:%lf, Y:%lf", screenPoint.x, screenPoint.y);

		CLLocationCoordinate2D coordinates =  annotation.coordinate;
		NSLog(@"Marker Lat/Lon location: Lat:%lf, Lon:%lf", coordinates.latitude, coordinates.longitude);

        [mapView removeAnnotation:annotation];
	}
	
	// Put the marker back
    RMAnnotation *annotation = [RMAnnotation annotationWithMapView:mapView coordinate:[mapView centerCoordinate] andTitle:@"Hello"];
    annotation.annotationIcon = [UIImage imageNamed:@"marker-blue.png"];
    annotation.anchorPoint = CGPointMake(0.5, 1.0);
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

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad
{
	NSLog(@"%@ viewDidLoad", self);
    [super viewDidLoad];

	tap = NO;
	mapView.delegate = self;

	CLLocationCoordinate2D coolPlace;
	coolPlace.latitude = -33.9464;
	coolPlace.longitude = 151.2381;
    [mapView setCenterCoordinate:coolPlace animated:NO];

    RMAnnotation *annotation = [RMAnnotation annotationWithMapView:mapView coordinate:coolPlace andTitle:@"Hello"];
    annotation.annotationIcon = [UIImage imageNamed:@"marker-blue.png"];
    annotation.anchorPoint = CGPointMake(0.5, 1.0);
    annotation.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIColor blueColor],@"foregroundColor",
                           nil];
    [mapView addAnnotation:annotation];

	NSLog(@"Center: Lat: %lf Lon: %lf", mapView.centerCoordinate.latitude, mapView.centerCoordinate.longitude);
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}

- (void)dealloc
{
	[mapView release];
    [super dealloc];
}

@end
