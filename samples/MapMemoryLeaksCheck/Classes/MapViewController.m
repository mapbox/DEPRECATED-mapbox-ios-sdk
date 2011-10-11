//
//  ProgrammaticMapViewController.m
//  ProgrammaticMap
//
//  Created by Hal Mueller on 3/25/09.
//  Copyright Route-Me Contributors 2009. All rights reserved.
//

#import "MapViewController.h"
#import "RMMapView.h"

@implementation MapViewController

@synthesize mapView;

- (void)viewDidLoad
{
	NSLog(@" => mapView viewDidLoad");
    [super viewDidLoad];

	CLLocationCoordinate2D firstLocation;
	firstLocation.latitude = 51.2795;
	firstLocation.longitude = 1.082;

	self.mapView = [[[RMMapView alloc] initWithFrame:CGRectMake(10, 20, 300, 340)] autorelease];
	[mapView setBackgroundColor:[UIColor greenColor]];
	[self.view addSubview:mapView];
	[self.view sendSubviewToBack:mapView];
}

- (void)dealloc
{
    NSLog(@" => mapView dealloc");
    [mapView removeFromSuperview];
	self.mapView = nil;
	[super dealloc];
}

@end
