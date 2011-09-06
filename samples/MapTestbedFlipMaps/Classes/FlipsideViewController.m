//
//  FlipsideViewController.m
//  MapTestbed : Diagnostic map
//

#import "FlipsideViewController.h"
#import "MapTestbedAppDelegate.h"
#import "RMAnnotation.h"
#import "RMMarker.h"

@implementation FlipsideViewController

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
    [self updateInfo];

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

    float routemeMetersPerPixel = [mapView metersPerPixel]; 
	double truescaleDenominator =  [mapView scaleDenominator];

    [infoTextView setText:[NSString stringWithFormat:@"Latitude : %f\nLongitude : %f\nZoom level : %.2f\nMeter per pixel : %.1f\nTrue scale : 1:%.0f", 
                           mapCenter.latitude, 
                           mapCenter.longitude, 
                           mapView.zoom, 
                           routemeMetersPerPixel,
                           truescaleDenominator]];
}

#pragma mark -
#pragma mark Delegate methods

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation
{
    RMMarker *marker = [[[RMMarker alloc] initWithUIImage:annotation.annotationIcon anchorPoint:annotation.anchorPoint] autorelease];
    [marker setTextForegroundColor:[annotation.userInfo objectForKey:@"foregroundColor"]];
	[marker changeLabelUsingText:annotation.title];
    return marker;
}

- (void)mapView:(RMMapView *)map didDragAnnotation:(RMAnnotation *)annotation withEvent:(UIEvent *)event 
{
    if ([[event allTouches] count] == 1) 
    {
        UITouch *touch = [[event allTouches] anyObject];
        if (touch.phase == UITouchPhaseMoved) 
        {
            CGPoint currentPosition = [touch locationInView:mapView];
            CGPoint previousPosition = [touch previousLocationInView:mapView];
            CGPoint screenPosition = annotation.position;
            screenPosition.x += (currentPosition.x - previousPosition.x);
            screenPosition.y += (currentPosition.y - previousPosition.y);

            CLLocationCoordinate2D newCoordinate = [mapView pixelToCoordinate:screenPosition];
            NSLog(@"New location latitude:%lf longitude:%lf", newCoordinate.latitude, newCoordinate.longitude);
            annotation.coordinate = newCoordinate;
        }
    }
}

- (void)afterMapMove:(RMMapView *)map
{
    [self updateInfo];
}

- (void)afterMapZoom:(RMMapView *)map
{
    [self updateInfo];
}

@end
