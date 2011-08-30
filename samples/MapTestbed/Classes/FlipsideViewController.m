//
//  FlipsideViewController.m
//  MapTestbed : Diagnostic map
//

#import "FlipsideViewController.h"
#import "MapTestbedAppDelegate.h"
#import "RootViewController.h"
#import "MainViewController.h"

@implementation FlipsideViewController

@synthesize centerLatitude;
@synthesize centerLongitude;
@synthesize zoomLevel;
@synthesize minZoom;
@synthesize maxZoom;

- (void)viewDidLoad
{
    [super viewDidLoad];
    mapView = [[[(MapTestbedAppDelegate *)[[UIApplication sharedApplication] delegate] rootViewController] mainViewController] mapView];

    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)viewDidAppear:(BOOL)animated
{
    CLLocationCoordinate2D mapCenter = [mapView centerCoordinate];

    [centerLatitude setText:[NSString stringWithFormat:@"%f", mapCenter.latitude]];
    [centerLongitude setText:[NSString stringWithFormat:@"%f", mapCenter.longitude]];
    [zoomLevel setText:[NSString stringWithFormat:@"%f", mapView.zoom]];
    [maxZoom setText:[NSString stringWithFormat:@"%f", mapView.maxZoom]];
    [minZoom setText:[NSString stringWithFormat:@"%f", mapView.minZoom]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    CLLocationCoordinate2D newMapCenter;
    
    newMapCenter.latitude = [[centerLatitude text] doubleValue];
    newMapCenter.longitude = [[centerLongitude text] doubleValue];
    [mapView setCenterCoordinate:newMapCenter];
    [mapView setZoom:[[zoomLevel text] floatValue]];
    [mapView setMaxZoom:[[maxZoom text] floatValue]];
    [mapView setMinZoom:[[minZoom text] floatValue]];
}

- (void)dealloc
{
    self.centerLatitude = nil;
    self.centerLongitude = nil;
    self.zoomLevel = nil;
    self.minZoom = nil;
    self.maxZoom = nil;    
    [super dealloc];
}

@end
