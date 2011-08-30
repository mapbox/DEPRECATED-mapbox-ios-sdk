//
//  FlipsideViewController.m
//  MapTestbed : Diagnostic map
//

#import "FlipsideViewController.h"
#import "MapTestbedTwoMapsAppDelegate.h"
#import "MainViewController.h"
#import "RootViewController.h"

@implementation FlipsideViewController

@synthesize centerLatitude;
@synthesize centerLongitude;
@synthesize zoomLevel;
@synthesize minZoom;
@synthesize maxZoom;

- (void)viewDidLoad
{
    [super viewDidLoad];
    mapView = [[[(MapTestbedTwoMapsAppDelegate *)[[UIApplication sharedApplication] delegate] rootViewController] mainViewController] upperMapView];

    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
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
    [mapView setCenterCoordinate:newMapCenter animated:NO];
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
