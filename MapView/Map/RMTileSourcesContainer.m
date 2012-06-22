//
//  RMTileSourcesContainer.m
//  MapView
//
//  Created by Thomas Rasch on 21.06.12.
//  Copyright (c) 2012 Alpstein. All rights reserved.
//

#import "RMTileSourcesContainer.h"

@implementation RMTileSourcesContainer
{
    NSMutableArray *_tileSources;

    RMProjection *_projection;
    RMFractalTileProjection *_mercatorToTileProjection;

    RMSphericalTrapezium _latitudeLongitudeBoundingBox;

    float _minZoom, _maxZoom;
    int _tileSideLength;
}

- (id)init
{
    if (!(self = [super init]))
        return nil;

    _tileSources = [NSMutableArray new];

    _projection = nil;
    _mercatorToTileProjection = nil;

    _latitudeLongitudeBoundingBox = ((RMSphericalTrapezium) {
        .northEast = {.latitude = 90.0, .longitude = 180.0},
        .southWest = {.latitude = -90.0, .longitude = -180.0}
    });

    _minZoom = FLT_MIN;
    _maxZoom = FLT_MAX;
    _tileSideLength = 0;

    return self;
}

- (void)dealloc
{
    [_tileSources release]; _tileSources = nil;
    [_projection release]; _projection = nil;
    [_mercatorToTileProjection release]; _mercatorToTileProjection = nil;
    [super dealloc];
}

#pragma mark -

- (NSArray *)tileSources
{
    return [[_tileSources copy] autorelease];
}

- (BOOL)setTileSource:(id <RMTileSource>)tileSource
{
    [self removeAllTileSources];
    return [self addTileSource:tileSource];
}

- (BOOL)addTileSource:(id <RMTileSource>)tileSource
{
    return [self addTileSource:tileSource atIndex:-1];
}

- (BOOL)addTileSource:(id<RMTileSource>)tileSource atIndex:(NSUInteger)index
{
    RMProjection *newProjection = [tileSource projection];
    RMFractalTileProjection *newFractalTileProjection = [tileSource mercatorToTileProjection];

    if ( ! _projection)
    {
        _projection = [newProjection retain];
    }
    else if (_projection != newProjection)
    {
        NSLog(@"The tilesource '%@' has a different projection than the tilesource container", [tileSource shortName]);
        return NO;
    }

    if ( ! _mercatorToTileProjection)
        _mercatorToTileProjection = [newFractalTileProjection retain];

    _minZoom = MAX(_minZoom, [tileSource minZoom]);
    _maxZoom = MIN(_maxZoom, [tileSource maxZoom]);

    if (_tileSideLength == 0)
    {
        _tileSideLength = [tileSource tileSideLength];
    }
    else if (_tileSideLength != [tileSource tileSideLength])
    {
        NSLog(@"The tilesource '%@' has a different tile side length than the tilesource container", [tileSource shortName]);
        return NO;
    }

    RMSphericalTrapezium newLatitudeLongitudeBoundingBox = [tileSource latitudeLongitudeBoundingBox];

    _latitudeLongitudeBoundingBox = ((RMSphericalTrapezium) {
        .northEast = {
            .latitude = MIN(_latitudeLongitudeBoundingBox.northEast.latitude, newLatitudeLongitudeBoundingBox.northEast.latitude),
            .longitude = MIN(_latitudeLongitudeBoundingBox.northEast.longitude, newLatitudeLongitudeBoundingBox.northEast.longitude)},
        .southWest = {
            .latitude = MAX(_latitudeLongitudeBoundingBox.southWest.latitude, newLatitudeLongitudeBoundingBox.southWest.latitude),
            .longitude = MAX(_latitudeLongitudeBoundingBox.southWest.longitude, newLatitudeLongitudeBoundingBox.southWest.longitude)
        }
    });

    if (index >= [_tileSources count])
        [_tileSources addObject:tileSource];
    else
        [_tileSources insertObject:tileSource atIndex:index];

    RMLog(@"Added the tilesource '%@' to the container", [tileSource shortName]);

    return YES;
}

- (void)removeTileSource:(id <RMTileSource>)tileSource
{
    [tileSource cancelAllDownloads];
    [_tileSources removeObject:tileSource];

    RMLog(@"Removed the tilesource '%@' from the container", [tileSource shortName]);

    if ([_tileSources count] == 0)
    {
        [self removeAllTileSources]; // cleanup
    }
}

- (void)removeTileSourceAtIndex:(NSUInteger)index
{
    if (index >= [_tileSources count])
        return;

    id <RMTileSource> tileSource = [_tileSources objectAtIndex:index];
    [tileSource cancelAllDownloads];
    [_tileSources removeObject:tileSource];

    RMLog(@"Removed the tilesource '%@' from the container", [tileSource shortName]);
}

- (void)moveTileSourceAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    if (fromIndex == toIndex)
        return;

    if (fromIndex >= [_tileSources count])
        return;

    id tileSource = [[_tileSources objectAtIndex:fromIndex] retain];
    [_tileSources removeObjectAtIndex:fromIndex];

    if (toIndex >= [_tileSources count])
        [_tileSources addObject:tileSource];
    else
        [_tileSources insertObject:tileSource atIndex:toIndex];

    [tileSource autorelease];
}

- (void)removeAllTileSources
{
    [self cancelAllDownloads];
    [_tileSources removeAllObjects];

    if ([_tileSources count] == 0)
    {
        [_projection release]; _projection = nil;
        [_mercatorToTileProjection release]; _mercatorToTileProjection = nil;

        _latitudeLongitudeBoundingBox = ((RMSphericalTrapezium) {
            .northEast = {.latitude = 90.0, .longitude = 180.0},
            .southWest = {.latitude = -90.0, .longitude = -180.0}
        });

        _minZoom = FLT_MIN;
        _maxZoom = FLT_MAX;
        _tileSideLength = 0;
    }
}

- (void)cancelAllDownloads
{
    for (id <RMTileSource>tileSource in _tileSources)
        [tileSource cancelAllDownloads];
}

- (RMFractalTileProjection *)mercatorToTileProjection
{
    return _mercatorToTileProjection;
}

- (RMProjection *)projection
{
    return _projection;
}

- (float)minZoom
{
    return _minZoom;
}

- (float)maxZoom
{
    return _maxZoom;
}

- (int)tileSideLength
{
    return _tileSideLength;
}

- (RMSphericalTrapezium)latitudeLongitudeBoundingBox
{
    return _latitudeLongitudeBoundingBox;
}

- (void)didReceiveMemoryWarning
{
    for (id <RMTileSource>tileSource in _tileSources)
        [tileSource didReceiveMemoryWarning];
}

@end
