//
//  RMMapBoxSource.m
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2012 MapBox.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//  
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//  
//      * Neither the name of MapBox, nor the names of its contributors may be
//        used to endorse or promote products derived from this software
//        without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "RMMapBoxSource.h"

@interface RMMapBoxSource ()

@property (nonatomic, retain) NSDictionary *infoDictionary;

@end

#pragma mark -

@implementation RMMapBoxSource

@synthesize infoDictionary;

- (id)init
{
    return [self initWithReferenceURL:[NSURL URLWithString:@"http://api.tiles.mapbox.com/v2/mapbox.mapbox-streets.json"]];
}

- (id)initWithTileJSON:(NSString *)tileJSON
{
    if (self = [super init])
    {
        NSAssert([NSJSONSerialization class], @"JSON serialization not supported by SDK");

        infoDictionary = (NSDictionary *)[[NSJSONSerialization JSONObjectWithData:[tileJSON dataUsingEncoding:NSUTF8StringEncoding]
                                                                          options:0
                                                                            error:nil] retain];
    }

    return self;
}

- (id)initWithInfo:(NSDictionary *)info
{
    WarnDeprecated();

    if ( ! (self = [super init]))
        return nil;

    infoDictionary = [[NSDictionary dictionaryWithDictionary:info] retain];

	return self;
}

- (id)initWithReferenceURL:(NSURL *)referenceURL
{
    id dataObject;

    if ((dataObject = [NSString stringWithContentsOfURL:referenceURL encoding:NSUTF8StringEncoding error:nil]) && dataObject)
        return [self initWithTileJSON:dataObject];

    else if ((dataObject = [[[NSDictionary alloc] initWithContentsOfURL:referenceURL] autorelease]) && dataObject)
        return [self initWithInfo:dataObject];

    return nil;
}

- (void)dealloc
{
    [infoDictionary release];
    [super dealloc];
}

#pragma mark 

- (NSURL *)URLForTile:(RMTile)tile
{
    // flip y value per OSM-style
    //
    NSInteger zoom = tile.zoom;
    NSInteger x    = tile.x;
    NSInteger y    = tile.y;

    if ([self.infoDictionary objectForKey:@"scheme"] && [[self.infoDictionary objectForKey:@"scheme"] isEqual:@"tms"])
        y = pow(2, zoom) - tile.y - 1;

    NSString *tileURLString;

    if ([self.infoDictionary objectForKey:@"tiles"])
        tileURLString = [[self.infoDictionary objectForKey:@"tiles"] objectAtIndex:0];

    else
        tileURLString = [self.infoDictionary objectForKey:@"tileURL"];

    tileURLString = [tileURLString stringByReplacingOccurrencesOfString:@"{z}" withString:[[NSNumber numberWithInteger:zoom] stringValue]];
    tileURLString = [tileURLString stringByReplacingOccurrencesOfString:@"{x}" withString:[[NSNumber numberWithInteger:x]    stringValue]];
    tileURLString = [tileURLString stringByReplacingOccurrencesOfString:@"{y}" withString:[[NSNumber numberWithInteger:y]    stringValue]];

	return [NSURL URLWithString:tileURLString];
}

- (float)minZoom
{
    return [[self.infoDictionary objectForKey:@"minzoom"] floatValue];
}

- (float)maxZoom
{
    return [[self.infoDictionary objectForKey:@"maxzoom"] floatValue];
}

- (RMSphericalTrapezium)latitudeLongitudeBoundingBox
{
    id bounds = [self.infoDictionary objectForKey:@"bounds"];

    NSArray *parts;

    if ([bounds isKindOfClass:[NSArray class]])
        parts = bounds;

    else
        parts = [bounds componentsSeparatedByString:@","];

    if ([parts count] == 4)
    {
        RMSphericalTrapezium bounds = {
            .southWest = {
                .longitude = [[parts objectAtIndex:0] doubleValue],
                .latitude  = [[parts objectAtIndex:1] doubleValue],
            },
            .northEast = {
                .longitude = [[parts objectAtIndex:2] doubleValue],
                .latitude  = [[parts objectAtIndex:3] doubleValue],
            },
        };

        return bounds;
    }

    return kMapBoxDefaultLatLonBoundingBox;
}

- (BOOL)coversFullWorld
{
    RMSphericalTrapezium ownBounds     = [self latitudeLongitudeBoundingBox];
    RMSphericalTrapezium defaultBounds = kMapBoxDefaultLatLonBoundingBox;

    if (ownBounds.southWest.longitude <= defaultBounds.southWest.longitude + 10 && 
        ownBounds.northEast.longitude >= defaultBounds.northEast.longitude - 10)
        return YES;

    return NO;
}

- (NSString *)legend
{
    return [self.infoDictionary objectForKey:@"legend"];
}

- (NSString *)uniqueTilecacheKey
{
    return [NSString stringWithFormat:@"MapBox-%@-%@", [self.infoDictionary objectForKey:@"id"], [self.infoDictionary objectForKey:@"version"]];
}

- (NSString *)shortName
{
	return [self.infoDictionary objectForKey:@"name"];
}

- (NSString *)longDescription
{
	return [self.infoDictionary objectForKey:@"description"];
}

- (NSString *)shortAttribution
{
	return [self.infoDictionary objectForKey:@"attribution"];
}

- (NSString *)longAttribution
{
	return [self shortAttribution];
}

@end
