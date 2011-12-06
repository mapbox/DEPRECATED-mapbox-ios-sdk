//
//  ProgrammaticMapViewController.m
//  ProgrammaticMap
//
//  Created by Hal Mueller on 3/25/09.
//  Copyright Route-Me Contributors 2009. All rights reserved.
//

#import "ProgrammaticMapViewController.h"
#import "RMMapView.h"
#import "RMOpenSeaMapSource.h"

@implementation ProgrammaticMapViewController

@synthesize mapView;

- (void)viewDidLoad
{
	NSLog(@"viewDidLoad");
    [super viewDidLoad];

	CLLocationCoordinate2D firstLocation;
	firstLocation.latitude = 51.2795;
	firstLocation.longitude = 1.082;

	self.mapView = [[[RMMapView alloc] initWithFrame:CGRectMake(10, 20, 300, 340) andTilesource:[[RMOpenSeaMapSource new] autorelease]] autorelease];
	[mapView setBackgroundColor:[UIColor greenColor]];
	[[self view] addSubview:mapView];
	[[self view] sendSubviewToBack:mapView];
}

- (void)dealloc
{
    [mapView removeFromSuperview];
	self.mapView = nil;
	[super dealloc];
}

- (IBAction)doTheTest:(id)sender
{
	CLLocationCoordinate2D secondLocation;
	secondLocation.latitude = 54.185;
	secondLocation.longitude = 12.09;
	[self.mapView setCenterCoordinate:secondLocation];
}

@end
