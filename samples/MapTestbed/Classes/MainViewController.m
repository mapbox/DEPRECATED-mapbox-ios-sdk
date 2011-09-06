//
//  MainViewController.m
//  MapTestbed : Diagnostic map
//

#import "MainViewController.h"
#import "MapTestbedAppDelegate.h"

#import "MainView.h"
#import "RMPath.h"
#import "RMMarker.h"
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

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    mapView.delegate = self;
	mapView.decelerationMode = RMMapDecelerationFast;
    [self updateInfo];
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
    CLLocationCoordinate2D mapCenter = [self.mapView centerCoordinate];

    float routemeMetersPerPixel = [self.mapView metersPerPixel];
	double truescaleDenominator =  [self.mapView scaleDenominator];

    [infoTextView setText:[NSString stringWithFormat:@"Latitude : %f\nLongitude : %f\nZoom level : %.2f\nMeter per pixel : %.1f\nTrue scale : 1:%.0f", 
                           mapCenter.latitude,
                           mapCenter.longitude,
                           self.mapView.zoom,
                           routemeMetersPerPixel,
                           truescaleDenominator]];
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

- (RMMapLayer *)mapView:(RMMapView *)aMapView layerForAnnotation:(RMAnnotation *)annotation
{
    if ([annotation.annotationType isEqualToString:@"path"]) {
        RMPath *testPath = [[[RMPath alloc] initWithView:aMapView] autorelease];
        [testPath setLineColor:[annotation.userInfo objectForKey:@"lineColor"]];
        [testPath setFillColor:[annotation.userInfo objectForKey:@"fillColor"]];
        [testPath setLineWidth:[[annotation.userInfo objectForKey:@"lineWidth"] floatValue]];

        CGPathDrawingMode drawingMode = kCGPathStroke;
        if ([annotation.userInfo containsObject:@"pathDrawingMode"])
            drawingMode = [[annotation.userInfo objectForKey:@"pathDrawingMode"] intValue];
        [testPath setDrawingMode:drawingMode];

        if ([[annotation.userInfo objectForKey:@"closePath"] boolValue])
            [testPath closePath];

        for (CLLocation *location in [annotation.userInfo objectForKey:@"linePoints"])
        {
            [testPath addLineToCoordinate:location.coordinate];
        }

        return testPath;
    }
    if ([annotation.annotationType isEqualToString:@"marker"]) {
        return [[[RMMarker alloc] initWithUIImage:annotation.annotationIcon anchorPoint:annotation.anchorPoint] autorelease];
    }

    return nil;
}

@end
