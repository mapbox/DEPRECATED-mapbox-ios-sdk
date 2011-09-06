//
//  MainViewController.m
//  SampleMap : Diagnostic map
//

#import "MainViewController.h"
#import "SampleMapAppDelegate.h"

#import "MainView.h"

#import "RMOpenStreetMapSource.h"

@implementation MainViewController

@synthesize mapView;
@synthesize infoTextView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (!(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
        return nil;

    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    mapView.delegate = self;

    /* -- Uncomment to constrain view
    [mapView setConstraintsSW:((CLLocationCoordinate2D){-33.942221,150.996094}) 
                           NE:((CLLocationCoordinate2D){-33.771157,151.32019})]; */

    [self updateInfo];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning
{
	RMLog(@"didReceiveMemoryWarning %@", self);
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)viewDidAppear:(BOOL)animated
{
    [self updateInfo];
}

- (void)dealloc
{
	LogMethod();
    self.infoTextView = nil; 
    self.mapView = nil; 
    [super dealloc];
}

- (void)updateInfo
{
    CLLocationCoordinate2D mapCenter = [self.mapView centerCoordinate];
    
	double truescaleDenominator = [self.mapView scaleDenominator];
    double routemeMetersPerPixel = [self.mapView metersPerPixel]; 
    [infoTextView setText:[NSString stringWithFormat:@"Latitude : %f\nLongitude : %f\nZoom: %.2f Meter per pixel : %.1f\nTrue scale : 1:%.0f\n%@\n%@", 
                           mapCenter.latitude, 
                           mapCenter.longitude, 
                           self.mapView.zoom, 
                           routemeMetersPerPixel,
                           truescaleDenominator,
						   [[self.mapView tileSource] shortName],
						   [[self.mapView tileSource] shortAttribution]
						   ]];
}

#pragma mark -
#pragma mark Delegate methods

- (void)afterMapMove:(RMMapView *)map
{
    [self updateInfo];
}

- (void)afterMapZoom:(RMMapView *)map
{
    [self updateInfo];
}

@end
