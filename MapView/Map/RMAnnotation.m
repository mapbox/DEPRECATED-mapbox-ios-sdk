//
//  RMAnnotation.m
//  MapView
//
// Copyright (c) 2008-2009, Route-Me Contributors
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

#import "RMAnnotation.h"
#import "RMMapView.h"
#import "RMMercatorToScreenProjection.h"

@interface RMAnnotation ()

@property (nonatomic, assign) RMMapView *mapView;

/// expressed in projected meters. The anchorPoint of the image is plotted here.
@property (nonatomic, assign) CGPoint position;

@end

#pragma mark -

@implementation RMAnnotation

@synthesize annotationType;
@synthesize coordinate;
@synthesize title;
@synthesize userInfo;

@synthesize mapView;
@synthesize position;

- (id)initForAnnotationType:(NSString *)anAnnotationType atCoordinate:(CLLocationCoordinate2D)aCoordinate andTitle:(NSString *)aTitle
{
    if (!(self = [super init]))
        return nil;

    self.annotationType = annotationType;
    self.coordinate     = aCoordinate;
    self.title          = aTitle;
    self.userInfo       = nil;

    return self;
}

- (void)setCoordinate:(CLLocationCoordinate2D)aCoordinate
{
    coordinate = aCoordinate;

    // Callback
}

@end
