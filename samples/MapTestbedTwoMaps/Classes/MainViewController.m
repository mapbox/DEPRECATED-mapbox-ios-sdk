//
//  MainViewController.m
//  MapTestbed : Diagnostic map
//

#import "MainViewController.h"
#import "MapTestbedTwoMapsAppDelegate.h"
#import "RMOpenStreetMapSource.h"
#import "RMOpenCycleMapSource.h"

#import "MainView.h"

@implementation MainViewController

@synthesize upperMapView;
@synthesize lowerMapView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (!(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
        return nil;

    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	LogMethod();
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tileNotification:) name:RMTileRequested object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tileNotification:) name:RMTileRetrieved object:nil];

	CLLocationCoordinate2D center;
	center.latitude = 47.592;
	center.longitude = -122.333;

    [upperMapView setDelegate:self];
    upperMapView.tileSource = [[[RMOpenStreetMapSource alloc] init] autorelease];
	[upperMapView setCenterCoordinate:center animated:NO];

    [lowerMapView setDelegate:self];
    lowerMapView.tileSource = [[[RMOpenCycleMapSource alloc] init] autorelease];
	[lowerMapView setCenterCoordinate:center animated:NO];

	NSLog(@"%@ %@", upperMapView, lowerMapView);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)viewDidAppear:(BOOL)animated
{
}

- (void)dealloc
{
    self.upperMapView = nil; 
    self.lowerMapView = nil; 
    [super dealloc];
}

#pragma mark -
#pragma mark Delegate methods

- (void)afterMapMove:(RMMapView *)map
{
    if (map == upperMapView)
        [lowerMapView setCenterCoordinate:upperMapView.centerCoordinate animated:NO];
}

- (void)afterMapZoom:(RMMapView *)map
{
    if (map == upperMapView) {
        lowerMapView.zoom = upperMapView.zoom;
        [lowerMapView setCenterCoordinate:upperMapView.centerCoordinate animated:NO];
    }
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
