//
//  MainViewController.m
//  MapTestbed : Diagnostic map
//

#import "MainViewController.h"
#import "MapTestbedAppDelegate.h"
#import "RMMarker.h"
#import "RMAnnotation.h"

#import "MainView.h"
#import "RMTileSource.h"

#import "RMOpenCycleMapSource.h"
#import "RMOpenStreetMapSource.h"
#import "RMOpenSeaMapSource.h"
#import "RMMapQuestOSMSource.h"
#import "RMMapQuestOpenAerialSource.h"

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
    mapView.decelerationMode = RMMapDecelerationFast;
    [self updateInfo];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tileNotification:) name:RMTileRequested object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tileNotification:) name:RMTileRetrieved object:nil];

	[mapView setMinZoom:1.0];
	[mapView setMaxZoom:20.0];

    RMAnnotation *annotation = [RMAnnotation annotationWithMapView:mapView coordinate:[mapView centerCoordinate] andTitle:@"Hello"];
    annotation.annotationIcon = [UIImage imageNamed:@"marker-blue.png"];
    annotation.anchorPoint = CGPointMake(0.5, 1.0);
    annotation.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIColor blueColor],@"foregroundColor",
                           nil];
    [mapView addAnnotation:annotation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)viewDidAppear:(BOOL)animated
{
    [self updateInfo];
}

- (void)dealloc
{
    self.infoTextView = nil; 
    self.mapView = nil; 
    [super dealloc];
}

- (void)updateInfo
{
    CLLocationCoordinate2D mapCenter = [mapView centerCoordinate];
    
    float routemeMetersPerPixel = [mapView metersPerPixel]; // really meters/pixel
	double truescaleDenominator =  [mapView scaleDenominator];

    [infoTextView setText:[NSString stringWithFormat:@"Latitude : %f\nLongitude : %f\nZoom level : %.2f\nMeter per pixel : %.1f\nTrue scale : 1:%.0f", 
                           mapCenter.latitude, 
                           mapCenter.longitude, 
                           mapView.zoom, 
                           routemeMetersPerPixel,
                           truescaleDenominator]];
}

- (IBAction)mapSelectChange
{
    switch (mapSelectControl.selectedSegmentIndex)
    {
        case 1:
            [mapView setTileSource:[[[RMOpenCycleMapSource alloc] init] autorelease]];
            break;

        case 2:
            [mapView setTileSource:[[[RMOpenSeaMapSource alloc] init] autorelease]];
            break;

        case 3:
            [mapView setTileSource:[[[RMMapQuestOSMSource alloc] init] autorelease]];
            break;

        case 4:
            [mapView setTileSource:[[[RMMapQuestOpenAerialSource alloc] init] autorelease]];
            break;

        default:
            [mapView setTileSource:[[[RMOpenStreetMapSource alloc] init] autorelease]];
            break;
    }
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

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation
{
    RMMarker *marker = [[[RMMarker alloc] initWithUIImage:annotation.annotationIcon anchorPoint:annotation.anchorPoint] autorelease];
    [marker setTextForegroundColor:[annotation.userInfo objectForKey:@"foregroundColor"]];
	[marker changeLabelUsingText:annotation.title];
    return marker;
}

#pragma mark -
#pragma mark Notification methods

- (void)tileNotification:(NSNotification *)notification
{
	static int outstandingTiles = 0;

	if (notification.name == RMTileRequested)
		outstandingTiles++;
	else if(notification.name == RMTileRetrieved)
		outstandingTiles--;

	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(outstandingTiles > 0)];
}

@end
