//
//  MainViewController.m
//  SampleMap : Diagnostic map
//

#import "MainViewController.h"
#import "MarkerMurderAppDelegate.h"

#import "MainView.h"

#import "RMOpenStreetMapSource.h"
#import "RMMapView.h"
#import "RMMarker.h"
#import "RMMercatorToScreenProjection.h"
#import "RMProjection.h"
#import "RMAnnotation.h"

@implementation MainViewController

@synthesize mapView;
@synthesize infoTextView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (!(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
        return nil;

    return self;
}

- (void)addMarkers
{
#define kNumberRows 1
#define kNumberColumns 9
#define kSpacing 2.0

	CLLocationCoordinate2D markerPosition;

	UIImage *redMarkerImage = [UIImage imageNamed:@"marker-red.png"];
	UIImage *blueMarkerImage = [UIImage imageNamed:@"marker-blue.png"];
	UIImage *xMarkerImage = [UIImage imageNamed:@"marker-X.png"];

	markerPosition.latitude = center.latitude - ((kNumberRows - 1)/2.0 * kSpacing);
	int i, j;
	for (i = 0; i < kNumberRows; i++)
    {
		markerPosition.longitude = center.longitude - ((kNumberColumns - 1)/2.0 * kSpacing);
		for (j = 0; j < kNumberColumns; j++)
        {
			markerPosition.longitude += kSpacing;
			NSLog(@"%f %f", markerPosition.latitude, markerPosition.longitude);

            RMAnnotation *annotation = [RMAnnotation annotationWithMapView:mapView coordinate:markerPosition andTitle:[NSString stringWithFormat:@"%4.1f", markerPosition.longitude]];
            if ((markerPosition.longitude < -180) ||(markerPosition.longitude > 0)) {
                annotation.annotationIcon = redMarkerImage;
                annotation.anchorPoint = CGPointMake(0.5, 1.0);
            } else {
                annotation.annotationIcon = blueMarkerImage;
                annotation.anchorPoint = CGPointMake(0.5, 1.0);
            }
            [mapView addAnnotation:annotation];

            annotation = [RMAnnotation annotationWithMapView:mapView coordinate:markerPosition andTitle:nil];
            annotation.annotationIcon = xMarkerImage;
            annotation.anchorPoint = CGPointMake(0.5, 0.5);
            [mapView addAnnotation:annotation];
		}
		markerPosition.latitude += kSpacing;
	}
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    [mapView setDelegate:self];
	mapView.tileSource = [[[RMOpenStreetMapSource alloc] init] autorelease];

	center.latitude = 66.44;
	center.longitude = -179.0;

	[mapView moveToCoordinate:center];
	[mapView setZoom:6.0];
	[mapView moveBy:CGSizeMake(-5.0, 0.0)];
	[self updateInfo];
	[self performSelector:@selector(addMarkers) withObject:nil afterDelay:1.0];
}

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
    CLLocationCoordinate2D mapCenter = [mapView mapCenterCoordinate];

    [infoTextView setText:[NSString stringWithFormat:@"Latitude : %f\nLongitude : %f\nZoom level : %.2f\n%@", 
                           mapCenter.latitude, 
                           mapCenter.longitude, 
                           mapView.zoom, 
						   [[mapView tileSource] shortAttribution]
						   ]];
}

#pragma mark -
#pragma mark Delegate methods

- (void)afterMapMove:(RMMapView *)map
{
    [self updateInfo];
}

- (void)afterMapZoom:(RMMapView *)map byFactor:(float)zoomFactor near:(CGPoint)center
{
	[self updateInfo];
}

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation
{
    RMMarker *marker = [[[RMMarker alloc] initWithUIImage:annotation.annotationIcon anchorPoint:annotation.anchorPoint] autorelease];
    if (annotation.title)
        [marker changeLabelUsingText:annotation.title];
    return marker;
}

@end
