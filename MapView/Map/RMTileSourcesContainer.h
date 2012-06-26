//
//  RMTileSourcesContainer.h
//  MapView
//
//  Created by Thomas Rasch on 21.06.12.
//  Copyright (c) 2012 Alpstein. All rights reserved.
//

#import "RMTileSource.h"

@interface RMTileSourcesContainer : NSObject

- (NSArray *)tileSources;

- (BOOL)setTileSource:(id <RMTileSource>)tileSource;

- (BOOL)addTileSource:(id <RMTileSource>)tileSource;
- (BOOL)addTileSource:(id<RMTileSource>)tileSource atIndex:(NSUInteger)index;

- (void)removeTileSource:(id <RMTileSource>)tileSource;
- (void)removeTileSourceAtIndex:(NSUInteger)index;

- (void)moveTileSourceAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

- (void)removeAllTileSources;
- (void)cancelAllDownloads;

- (RMFractalTileProjection *)mercatorToTileProjection;
- (RMProjection *)projection;

- (float)minZoom;
- (float)maxZoom;
- (int)tileSideLength;

- (RMSphericalTrapezium)latitudeLongitudeBoundingBox;

- (void)didReceiveMemoryWarning;

@end
