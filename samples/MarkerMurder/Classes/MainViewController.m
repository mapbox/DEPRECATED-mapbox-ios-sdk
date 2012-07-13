//
//  MainViewController.m
//  SampleMap : Diagnostic map
//

#import "MainViewController.h"
#import "MarkerMurderAppDelegate.h"

#import "MainView.h"

#import "RMOpenStreetMapSource.h"
#import "RMOpenSeaMapLayer.h"
#import "RMMapView.h"
#import "RMMarker.h"
#import "RMCircle.h"
#import "RMProjection.h"
#import "RMAnnotation.h"
#import "RMQuadTree.h"
#import "RMCoordinateGridSource.h"
#import "RMOpenCycleMapSource.h"

@implementation MainViewController
{
    CLLocationCoordinate2D center;

    BOOL tapped;
    NSUInteger tapCount;
}

@synthesize mapView;
@synthesize infoTextView;
@synthesize mppLabel, mppImage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (!(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
        return nil;

    //Notifications for tile requests.  This code allows for a class to know when a tile is requested and retrieved
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tileRequested:) name:@"RMTileRequested" object:nil ];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tileRetrieved:) name:@"RMTileRetrieved" object:nil ];

    tapped = NO;
    tapCount = 0;

    return self;
}

- (void)tileRequested:(NSNotification *)notification
{
	NSLog(@"Tile request started.");
}

- (void)tileRetrieved:(NSNotification *)notification
{
	NSLog(@"Tile request ended.");
}

#define kNumberRows 2
#define kNumberColumns 9
#define kSpacing 0.1

#define kCircleAnnotationType @"circleAnnotation"
#define kDraggableAnnotationType @"draggableAnnotation"

- (void)addMarkers
{
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

    RMAnnotation *draggableAnnotation = [RMAnnotation annotationWithMapView:mapView coordinate:CLLocationCoordinate2DMake(47.72, 10.2) andTitle:@"Drag me! Tap me!"];
    draggableAnnotation.annotationType = kDraggableAnnotationType;
    draggableAnnotation.annotationIcon = [UIImage imageNamed:@"marker-blue.png"];
    draggableAnnotation.anchorPoint = CGPointMake(0.5, 1.0);
    draggableAnnotation.clusteringEnabled = NO;
    draggableAnnotation.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [UIColor blueColor],@"foregroundColor",
                                    nil];
    [mapView addAnnotation:draggableAnnotation];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    mapView.delegate = self;
    mapView.enableClustering = YES;
    mapView.positionClusterMarkersAtTheGravityCenter = YES;

//    mapView.adjustTilesForRetinaDisplay = YES;
//    mapView.decelerationMode = RMMapDecelerationOff;
//    mapView.enableBouncing = NO;
//    mapView.enableDragging = YES;
//    mapView.debugTiles = YES;
//    [mapView setConstraintsSouthWest:CLLocationCoordinate2DMake(47.0, 10.0) northEast:CLLocationCoordinate2DMake(48.0, 11.0)];
//    [mapView addTileSource:[[[RMCoordinateGridSource alloc] init] autorelease]];

    UIImage *clusterMarkerImage = [UIImage imageNamed:@"marker-blue.png"];
    mapView.clusterMarkerSize = clusterMarkerImage.size;
    mapView.clusterAreaSize = CGSizeMake(clusterMarkerImage.size.width * 1.25, clusterMarkerImage.size.height * 1.25);

	center.latitude = 47.5635;
	center.longitude = 10.20981;

//    int zoneNumber;
//    BOOL isNorthernHemisphere;
//    NSString *utmZone;
//    double easting, northing;
//
//    [RMProjection convertCoordinate:center
//                    toUTMZoneNumber:&zoneNumber
//                      utmZoneLetter:&utmZone
//               isNorthernHemisphere:&isNorthernHemisphere
//                            easting:&easting
//                           northing:&northing];
//
//    NSLog(@"{%f,%f} -> %d%@ %.0f %.0f (north: %@)", center.latitude, center.longitude, zoneNumber, utmZone, easting, northing, isNorthernHemisphere ? @"YES" : @"NO");
//
//    CLLocationCoordinate2D coordinate;
//    [RMProjection convertUTMZoneNumber:zoneNumber
//                         utmZoneLetter:utmZone
//                  isNorthernHemisphere:isNorthernHemisphere
//                               easting:easting
//                              northing:northing
//                          toCoordinate:&coordinate];
//
//    NSLog(@"-> {%f,%f}", coordinate.latitude, coordinate.longitude);

//    [mapView zoomWithLatitudeLongitudeBoundsSouthWest:CLLocationCoordinate2DMake(47.5, 10.15) northEast:CLLocationCoordinate2DMake(47.6, 10.25) animated:NO];

	[mapView setZoom:10.0];
	[mapView setCenterCoordinate:center animated:NO];

	[self updateInfo];
	[self performSelector:@selector(addMarkers) withObject:nil afterDelay:0.5];

//    // Tile bounding box
//    RMSphericalTrapezium tileBoundingBox = [mapView latitudeLongitudeBoundingBoxForTile:RMTileMake(541, 357, 10)];
//
//    RMAnnotation *annotation = [RMAnnotation annotationWithMapView:mapView coordinate:tileBoundingBox.southWest andTitle:@"bbox SouthWest"];
//    annotation.annotationIcon = [UIImage imageNamed:@"marker-red.png"];
//    annotation.anchorPoint = CGPointMake(0.5, 1.0);
//    annotation.clusteringEnabled = NO;
//    [mapView addAnnotation:annotation];
//
//    annotation = [RMAnnotation annotationWithMapView:mapView coordinate:tileBoundingBox.northEast andTitle:@"bbox NorthEast"];
//    annotation.annotationIcon = [UIImage imageNamed:@"marker-red.png"];
//    annotation.anchorPoint = CGPointMake(0.5, 1.0);
//    annotation.clusteringEnabled = NO;
//    [mapView addAnnotation:annotation];

    // Tile sources
//    [mapView setTileSources:@[
//     [[[RMOpenStreetMapSource alloc] init] autorelease],
//     [[[RMOpenSeaMapLayer alloc] init] autorelease]
//     ]];

//    double delayInSeconds = 5.0;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
//        [mapView addTileSource:[[[RMCoordinateGridSource alloc] init] autorelease]];
//
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
//            [mapView setHidden:YES forTileSourceAtIndex:1];
//
//            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
//                [mapView setHidden:NO forTileSourceAtIndex:1];
//
//                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
//                    [mapView removeTileSourceAtIndex:1];
//                });
//            });
//        });
//    });
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

    [infoTextView setText:[NSString stringWithFormat:@"Longitude : %f\nLatitude : %f\nZoom level : %.2f\nScale : 1:%.0f\n%@",
                           mapCenter.longitude,
                           mapCenter.latitude,
                           mapView.zoom,
                           mapView.scaleDenominator,
						   [[mapView tileSource] shortAttribution]
						   ]];

    [mppLabel setText:[NSString stringWithFormat:@"%.0f m", mapView.metersPerPixel * mppImage.bounds.size.width]];
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

- (BOOL)mapView:(RMMapView *)map shouldDragAnnotation:(RMAnnotation *)annotation
{
    if ([annotation.annotationType isEqualToString:kDraggableAnnotationType])
    {
        NSLog(@"Start dragging marker");
        return YES;
    }

    return NO;
}

- (void)mapView:(RMMapView *)map didDragAnnotation:(RMAnnotation *)annotation withDelta:(CGPoint)delta
{
    CGPoint screenPosition = CGPointMake(annotation.position.x - delta.x, annotation.position.y - delta.y);

    annotation.coordinate = [mapView pixelToCoordinate:screenPosition];
    annotation.position = screenPosition;
}

- (void)mapView:(RMMapView *)map didEndDragAnnotation:(RMAnnotation *)annotation
{
    RMProjectedPoint projectedPoint = annotation.projectedLocation;
    CGPoint screenPoint = annotation.position;

    NSLog(@"Did end dragging marker, screen: {%.0f,%.0f}, projected: {%f,%f}, coordinate: {%f,%f}", screenPoint.x, screenPoint.y, projectedPoint.x, projectedPoint.y, annotation.coordinate.latitude, annotation.coordinate.longitude);
}

- (void)tapOnLabelForAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map
{
    if ([annotation.annotationType isEqualToString:kDraggableAnnotationType])
    {
        NSLog(@"Label <%@> tapped for marker <%@>",  ((RMMarker *)annotation.layer).label, (RMMarker *)annotation.layer);
        [(RMMarker *)annotation.layer changeLabelUsingText:[NSString stringWithFormat:@"Drag me! Tap me! (%d)", ++tapCount]];
    }
}

- (void)singleTapOnMap:(RMMapView *)map at:(CGPoint)point
{
    RMProjectedPoint projectedPoint = [map pixelToProjectedPoint:point];
    CLLocationCoordinate2D coordinates =  [map pixelToCoordinate:point];

	NSLog(@"Clicked on Map - Location: x:%lf y:%lf, Projected east:%f north:%f, Coordinate lat:%f lon:%f", point.x, point.y, projectedPoint.x, projectedPoint.y, coordinates.latitude, coordinates.longitude);
}

- (void)tapOnAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map
{
    if ([annotation.annotationType isEqualToString:kRMClusterAnnotationTypeName])
    {
        [map zoomInToNextNativeZoomAt:[map coordinateToPixel:annotation.coordinate] animated:YES];
    }
    else if ([annotation.annotationType isEqualToString:kDraggableAnnotationType])
    {
        NSLog(@"MARKER TAPPED!");

        if (!tapped)
        {
            annotation.annotationIcon = [UIImage imageNamed:@"marker-red.png"];
            [(RMMarker *)annotation.layer replaceUIImage:annotation.annotationIcon anchorPoint:annotation.anchorPoint];
            [(RMMarker *)annotation.layer changeLabelUsingText:@"Hello"];
            tapped = YES;
        }
        else
        {
            annotation.annotationIcon = [UIImage imageNamed:@"marker-blue.png"];
            [(RMMarker *)annotation.layer replaceUIImage:annotation.annotationIcon anchorPoint:annotation.anchorPoint];
            [(RMMarker *)annotation.layer changeLabelUsingText:@"World"];
            tapped = NO;
        }
    }
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

        if ([annotation.userInfo objectForKey:@"foregroundColor"])
            [(RMMarker *)marker setTextForegroundColor:[annotation.userInfo objectForKey:@"foregroundColor"]];

        if ([annotation.annotationType isEqualToString:kDraggableAnnotationType])
            marker.enableDragging = YES;
    }

    return marker;
}

@end
