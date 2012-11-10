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

- (id)initWithFrame:(CGRect)frame mapID:(NSString *)mapID centerCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(CGFloat)zoomLevel
{
    return [self initWithFrame:frame mapID:mapID centerCoordinate:centerCoordinate zoomLevel:zoomLevel completionHandler:nil];
}

- (id)initWithFrame:(CGRect)frame mapID:(NSString *)mapID centerCoordinate:(CLLocationCoordinate2D)centerCoordinate zoomLevel:(CGFloat)zoomLevel completionHandler:(void (^)(UIImage *))handler
{
    if (!(self = [super initWithFrame:frame andTilesource:[[[RMMapBoxSource alloc] initWithMapID:mapID] autorelease] centerCoordinate:centerCoordinate zoomLevel:zoomLevel maxZoomLevel:zoomLevel minZoomLevel:zoomLevel backgroundImage:nil]))
        return nil;

    self.backgroundColor = [UIColor colorWithPatternImage:[RMMapView resourceImageNamed:@"LoadingTile.png"]];

    self.hideAttribution = YES;

    self.showsUserLocation = NO;

    self.userInteractionEnabled = NO;

    __unsafe_unretained RMStaticMapView *weakSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^(void)
    {
        if (weakSelf)
        {
            UIImage *image = [weakSelf takeSnapshot];

            if (image)
                handler(image);
        }
    });

    return self;
    
}

@end
