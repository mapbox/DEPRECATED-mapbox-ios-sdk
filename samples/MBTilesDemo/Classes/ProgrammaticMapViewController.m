//
//  ProgrammaticMapViewController.m
//  ProgrammaticMap
//
//  Created by Hal Mueller on 3/25/09.
//  Copyright Route-Me Contributors 2009. All rights reserved.
//

#import "ProgrammaticMapViewController.h"
#import "RMMapView.h"
#import "RMMBTilesTileSource.h"
#import "RMTileStreamSource.h"

@implementation ProgrammaticMapViewController
{
    BOOL showsLocalTileSource;
}

@synthesize mapView;

- (void)viewDidLoad
{
	NSLog(@"viewDidLoad");
    [super viewDidLoad];

	CLLocationCoordinate2D firstLocation;
	firstLocation.latitude = 30.0;
	firstLocation.longitude = -10.0;

    showsLocalTileSource = YES;

    NSURL *tilesURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"control-room-0.2.0" ofType:@"mbtiles"]];
    RMMBTilesTileSource *tileSource = [[[RMMBTilesTileSource alloc] initWithTileSetURL:tilesURL] autorelease];

	self.mapView = [[[RMMapView alloc] initWithFrame:CGRectMake(10, 20, 300, 340)
                                       andTilesource:tileSource
                                    centerCoordinate:firstLocation
                                           zoomLevel:1.5
                                        maxZoomLevel:[tileSource maxZoom]
                                        minZoomLevel:[tileSource minZoom]
                                     backgroundImage:nil] autorelease];

    self.mapView.backgroundColor = [UIColor blackColor];

	[self.view addSubview:mapView];
	[self.view sendSubviewToBack:mapView];
}

- (void)dealloc
{
    [self.mapView removeFromSuperview];
	self.mapView = nil;
	[super dealloc];
}

- (IBAction)swtichTilesource:(id)sender
{
    id <RMTileSource> newTileSource = nil;

    if (showsLocalTileSource)
    {
        showsLocalTileSource = NO;

        NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"geography-class" ofType:@"plist"]];
        newTileSource = [[[RMTileStreamSource alloc] initWithInfo:info] autorelease];
    }
    else
    {
        showsLocalTileSource = YES;

        NSURL *tilesURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"control-room-0.2.0" ofType:@"mbtiles"]];
        newTileSource = [[[RMMBTilesTileSource alloc] initWithTileSetURL:tilesURL] autorelease];
    }

    self.mapView.tileSource = newTileSource;
}

@end
