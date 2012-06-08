//
//  RMCompositeSource.h
//  MapView
//
//  Created by Justin Miller on 4/19/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import "RMTileSource.h"

@interface RMCompositeSource : NSObject <RMTileSource>
{
    RMFractalTileProjection *tileProjection;
}

@property (nonatomic, retain) NSMutableArray *compositeSources;

- (id)initWithTileSource:(id <RMTileSource>)initialTileSource;

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache;
- (void)cancelAllDownloads;

- (RMFractalTileProjection *)mercatorToTileProjection;
- (RMProjection *)projection;

- (float)minZoom;
- (void)setMinZoom:(NSUInteger)aMinZoom;

- (float)maxZoom;
- (void)setMaxZoom:(NSUInteger)aMaxZoom;

- (int)tileSideLength;
- (void)setTileSideLength:(NSUInteger)aTileSideLength;

- (RMSphericalTrapezium)latitudeLongitudeBoundingBox;

- (NSString *)uniqueTilecacheKey;

- (NSString *)shortName;
- (NSString *)longDescription;
- (NSString *)shortAttribution;
- (NSString *)longAttribution;

- (void)didReceiveMemoryWarning;

@end
