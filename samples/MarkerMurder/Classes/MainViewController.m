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
#import "RMCircle.h"
#import "RMProjection.h"
#import "RMAnnotation.h"
#import "RMQuadTree.h"

@implementation MainViewController
{
    CLLocationCoordinate2D center;
}

@synthesize mapView;
@synthesize infoTextView;
@synthesize mppLabel;

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
#define kSpacing 0.1

#define kCircleAnnotationType @"circleAnnotation"

	CLLocationCoordinate2D markerPosition;

	UIImage *redMarkerImage = [UIImage imageNamed:@"marker-red.png"];
	UIImage *blueMarkerImage = [UIImage imageNamed:@"marker-blue.png"];

	markerPosition.latitude = center.latitude - ((kNumberRows - 1)/2.0 * kSpacing);

	for (int i = 0; i < kNumberRows; i++)
    {
		markerPosition.longitude = center.longitude - ((kNumberColumns - 1)/2.0 * kSpacing);

		for (int j = 0; j < kNumberColumns; j++)
        {
			markerPosition.longitude += kSpacing;

			NSLog(@"Add marker @ {%f,%f} = {%f,%f}", markerPosition.longitude, markerPosition.latitude, [mapView coordinateToProjectedPoint:markerPosition].x, [mapView coordinateToProjectedPoint:markerPosition].y);

            RMAnnotation *annotation = [RMAnnotation annotationWithMapView:mapView coordinate:markerPosition andTitle:[NSString stringWithFormat:@"%4.1f", markerPosition.longitude]];

            if ((markerPosition.longitude < -180) || (markerPosition.longitude > 0))
            {
                annotation.annotationIcon = redMarkerImage;
                annotation.anchorPoint = CGPointMake(0.5, 1.0);
            }
            else
            {
                annotation.annotationIcon = blueMarkerImage;
                annotation.anchorPoint = CGPointMake(0.5, 1.0);
            }
 
            [mapView addAnnotation:annotation];
		}

		markerPosition.latitude += kSpacing;
	}

    RMAnnotation *circleAnnotation = [RMAnnotation annotationWithMapView:mapView coordinate:CLLocationCoordinate2DMake(47.4, 10.0) andTitle:@"A Circle"];
    circleAnnotation.annotationType = kCircleAnnotationType;
    [mapView addAnnotation:circleAnnotation];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    [mapView setDelegate:self];
	mapView.tileSource = [[[RMOpenStreetMapSource alloc] init] autorelease];
    mapView.enableClustering = YES;
    mapView.positionClusterMarkersAtTheGravityCenter = YES;

    UIImage *clusterMarkerImage = [UIImage imageNamed:@"marker-blue.png"];
    mapView.clusterMarkerSize = clusterMarkerImage.size;
    mapView.clusterAreaSize = CGSizeMake(clusterMarkerImage.size.width * 1.25, clusterMarkerImage.size.height * 1.25);

	center.latitude = 47.5635;
	center.longitude = 10.20981;

//    [mapView zoomWithLatitudeLongitudeBoundsSouthWest:CLLocationCoordinate2DMake(47.5, 10.15) northEast:CLLocationCoordinate2DMake(47.6, 10.25) animated:NO];

	[mapView setZoom:10.0];
	[mapView setCenterCoordinate:center animated:NO];

	[self updateInfo];
	[self performSelector:@selector(addMarkers) withObject:nil afterDelay:0.5];

//    [mapView setConstraintsSouthWest:CLLocationCoordinate2DMake(47.0, 10.0) northEeast:CLLocationCoordinate2DMake(48.0, 11.0)];
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

- (void)viewDidUnload
{
    [self setMppLabel:nil];
    [super viewDidUnload];
}

- (void)dealloc
{
    self.infoTextView = nil; 
    self.mapView = nil; 
    self.mppLabel = nil;
    [super dealloc];
}

- (void)updateInfo
{
    CLLocationCoordinate2D mapCenter = [mapView centerCoordinate];

    [infoTextView setText:[NSString stringWithFormat:@"Longitude : %f\nLatitude : %f\nZoom level : %.2f\n%@", 
                           mapCenter.longitude,
                           mapCenter.latitude,
                           mapView.zoom,
						   [[mapView tileSource] shortAttribution]
						   ]];

    [mppLabel setText:[NSString stringWithFormat:@"%.0f m", self.mapView.metersPerPixel * 55.0]];
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

- (void)tapOnAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map
{
    if ([annotation.annotationType isEqualToString:kRMClusterAnnotationTypeName])
        [map zoomInToNextNativeZoomAt:[map coordinateToPixel:annotation.coordinate] animated:YES];
}

- (RMMapLayer *)mapView:(RMMapView *)aMapView layerForAnnotation:(RMAnnotation *)annotation
{
    RMMapLayer *marker = nil;

    if ([annotation.annotationType isEqualToString:kRMClusterAnnotationTypeName])
    {
        marker = [[[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"marker-blue.png"] anchorPoint:CGPointMake(0.5, 1.0)] autorelease];
        if (annotation.title)
            [(RMMarker *)marker changeLabelUsingText:annotation.title];
    }
    else if ([annotation.annotationType isEqualToString:kCircleAnnotationType])
    {
        marker = [[[RMCircle alloc] initWithView:aMapView radiusInMeters:10000.0] autorelease];
        [(RMCircle *)marker setLineWidthInPixels:5.0];
    }
    else
    {
        marker = [[[RMMarker alloc] initWithUIImage:annotation.annotationIcon anchorPoint:annotation.anchorPoint] autorelease];
        if (annotation.title)
            [(RMMarker *)marker changeLabelUsingText:annotation.title];
    }

    return marker;
}

@end
