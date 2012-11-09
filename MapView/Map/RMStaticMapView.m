//
//  RMStaticMapView.m
//
// Copyright (c) 2008-2012, Route-Me Contributors
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import "RMStaticMapView.h"

#define RMStaticMapViewMaxWidth  640.0f
#define RMStaticMapViewMaxHeight 640.0f
#define RMStaticMapViewMinZoom     0.0f
#define RMStaticMapViewMaxZoom    17.0f

@implementation RMStaticMapView

- (id)initWithFrame:(CGRect)frame mapID:(NSString *)mapID centerCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(CGFloat)initialZoomLevel
{
    if (!(self = [super initWithFrame:frame]))
        return nil;

    CGRect requestFrame = CGRectMake(frame.origin.x, frame.origin.y, fminf(frame.size.width, RMStaticMapViewMaxWidth), fminf(frame.size.height, RMStaticMapViewMaxHeight));

    if ( ! CLLocationCoordinate2DIsValid(centerCoordinate))
        centerCoordinate = CLLocationCoordinate2DMake(0, 0);

    initialZoomLevel = fmaxf(initialZoomLevel, RMStaticMapViewMinZoom);
    initialZoomLevel = fminf(initialZoomLevel, RMStaticMapViewMaxZoom);

    self.backgroundColor = [UIColor colorWithPatternImage:[RMMapView resourceImageNamed:@"LoadingTile.png"]];

    self.contentMode = UIViewContentModeCenter;

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];

    [spinner startAnimating];

    spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

    spinner.center = self.center;

    [self addSubview:spinner];

    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.tiles.mapbox.com/v3/%@/%f,%f,%i/%ix%i.png", mapID, centerCoordinate.longitude, centerCoordinate.latitude, (int)roundf(initialZoomLevel), (int)roundf(requestFrame.size.width), (int)roundf(requestFrame.size.height)]];

    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:imageURL]
                                       queue:[NSOperationQueue new]
                           completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *error)
                           {
                               [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

                               if (responseData)
                               {
                                   dispatch_async(dispatch_get_main_queue(), ^(void)
                                   {
                                       self.image = [UIImage imageWithData:responseData];
                                   });
                               }

                               else
                                   return; // TODO: notify delegate of error & display something
                           }];

    return self;
}

@end
