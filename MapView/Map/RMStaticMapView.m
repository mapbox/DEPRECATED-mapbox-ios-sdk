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

@implementation RMStaticMapView
{
    __weak RMStaticMapView *_weakSelf;
}

- (id)initWithFrame:(CGRect)frame mapID:(NSString *)mapID
{
    return [self initWithFrame:frame mapID:mapID centerCoordinate:CLLocationCoordinate2DMake(MAXFLOAT, MAXFLOAT) zoomLevel:-1 completionHandler:nil];
}

- (id)initWithFrame:(CGRect)frame mapID:(NSString *)mapID completionHandler:(void (^)(UIImage *))handler
{
    return [self initWithFrame:frame mapID:mapID centerCoordinate:CLLocationCoordinate2DMake(MAXFLOAT, MAXFLOAT) zoomLevel:-1 completionHandler:handler];
}

- (id)initWithFrame:(CGRect)frame mapID:(NSString *)mapID centerCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(CGFloat)zoomLevel
{
    return [self initWithFrame:frame mapID:mapID centerCoordinate:centerCoordinate zoomLevel:zoomLevel completionHandler:nil];
}

- (id)initWithFrame:(CGRect)frame mapID:(NSString *)mapID centerCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(CGFloat)zoomLevel completionHandler:(void (^)(UIImage *))handler
{
    if (!(self = [super initWithFrame:frame]))
        return nil;

    RMMapBoxSource *tileSource = [[[RMMapBoxSource alloc] initWithMapID:mapID enablingDataOnMapView:self] autorelease];

    self.tileSource = tileSource;

    if ( ! CLLocationCoordinate2DIsValid(centerCoordinate))
        centerCoordinate = [tileSource centerCoordinate];

    [self setCenterCoordinate:centerCoordinate animated:NO];

    if (zoomLevel < 0)
        zoomLevel = [tileSource centerZoom];

    [self setZoom:zoomLevel];

    self.backgroundColor = [UIColor colorWithPatternImage:[RMMapView resourceImageNamed:@"LoadingTile.png"]];

    self.hideAttribution = YES;

    self.showsUserLocation = NO;

    self.userInteractionEnabled = NO;

    _weakSelf = self;

    dispatch_async(tileSource.dataQueue, ^(void)
    {
        dispatch_sync(dispatch_get_main_queue(), ^(void)
        {
            UIImage *image = [_weakSelf takeSnapshot];

            handler(image);
        });
    });

    return self;
    
}

- (void)addAnnotation:(RMAnnotation *)annotation
{
    annotation.layer = [[RMMarker alloc] initWithMapBoxMarkerImage:[annotation.userInfo objectForKey:@"marker-symbol"]
                                                      tintColorHex:[annotation.userInfo objectForKey:@"marker-color"]
                                                        sizeString:[annotation.userInfo objectForKey:@"marker-size"]];

    [super addAnnotation:annotation];
}

@end
