//
//  RMTileImageSet.m
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

#import "RMTileImageSet.h"
#import "RMTileImage.h"
#import "RMPixel.h"
#import "RMTileSource.h"
#import "RMTileCache.h"

// For notification strings
#import "RMTileLoader.h"

#import "RMMercatorToTileProjection.h"

@interface RMShuffleContainer : NSObject
{}

@property (nonatomic, assign) RMTile tile;
@property (nonatomic, assign) CGRect screenLocation;

+ (id)containerWithTile:(RMTile)aTile at:(CGRect)aScreenLocation;
- (id)initWithTile:(RMTile)aTile at:(CGRect)aScreenLocation;

@end

@implementation RMShuffleContainer

@synthesize tile, screenLocation;

+ (id)containerWithTile:(RMTile)aTile at:(CGRect)aScreenLocation
{
    return [[[self alloc] initWithTile:aTile at:aScreenLocation] autorelease];
}

- (id)initWithTile:(RMTile)aTile at:(CGRect)aScreenLocation
{
    if (!(self = [super init])) return nil;
    self.tile = RMTileMake(aTile.x, aTile.y, aTile.zoom);
    self.screenLocation = CGRectMake(aScreenLocation.origin.x, aScreenLocation.origin.y, aScreenLocation.size.width, aScreenLocation.size.height);
    return self;
}

@end

#pragma mark -

@implementation RMTileImageSet

@synthesize delegate, tileDepth, zoom;

- (id)initWithDelegate:(id)_delegate
{
    if (!(self = [super init]))
        return nil;

    tileSource = nil;
    tileCache = nil;

    self.delegate = _delegate;
    self.tileDepth = 0;

    images = [[NSMutableSet alloc] init];
    imagesLock = [[NSRecursiveLock alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tileImageLoaded:)
                                                 name:RMMapImageLoadedNotification
                                               object:nil];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeAllTiles];
    [images release]; images = nil;
    [imagesLock release]; imagesLock = nil;
    [super dealloc];
}

- (void)removeTile:(RMTile)tile
{
    NSAssert(!RMTileIsDummy(tile), @"attempted to remove dummy tile");
    if (RMTileIsDummy(tile))
    {
        RMLog(@"attempted to remove dummy tile...??");
        return;
    }

    [imagesLock lock];

    RMTileImage *tileImage = [images member:[RMTileImage tileImageWithTile:tile]];
    if (!tileImage) {
        [imagesLock unlock];
        return;
    }

    if ([delegate respondsToSelector:@selector(tileImageRemoved:)])
        [delegate tileImageRemoved:tileImage];

    [[NSNotificationCenter defaultCenter] postNotificationName:RMMapImageRemovedFromScreenNotification object:tileImage];

    [tileImage cancelLoading];
    [images removeObject:tileImage];

    [imagesLock unlock];
}

- (void)removeAllTiles
{
    [imagesLock lock];

    for (NSInteger i=[images count]; i>0; --i)
    {
        RMTileImage *tileImage = [images anyObject];

        if ([delegate respondsToSelector:@selector(tileImageRemoved:)])
            [delegate tileImageRemoved:tileImage];

        [[NSNotificationCenter defaultCenter] postNotificationName:RMMapImageRemovedFromScreenNotification object:tileImage];

        [tileImage cancelLoading];
        [images removeObject:tileImage];
    }

    [imagesLock unlock];
}

- (void)resetTiles
{
    [imagesLock lock];

    for (RMTileImage *tileImage in images)
    {
        [tileImage setScreenLocation:CGRectZero];
    }

    [imagesLock unlock];
}

- (void)setTileSource:(id <RMTileSource>)newTileSource
{
    [self removeAllTiles];
    tileSource = newTileSource;
}

- (void)setTileCache:(RMTileCache *)newTileCache
{
    tileCache = newTileCache;
}

- (void)setCurrentCacheKey:(NSString *)newCacheKey
{
    [currentCacheKey autorelease];
    [newCacheKey retain];
    currentCacheKey = newCacheKey;
}

- (void)addTileImage:(RMTileImage *)image at:(CGRect)screenLocation
{
    BOOL tileNeeded;

    tileNeeded = YES;

    [imagesLock lock];

    for (RMTileImage *tileImage in images)
    {
        if (![tileImage isLoaded])
            continue;

        if ([self isTile:image.tile worseThanTile:tileImage.tile])
        {
            tileNeeded = NO;
            break;
        }
    }

    [imagesLock unlock];

    if (!tileNeeded)
        return;

    if ([image isLoaded])
        [self removeTilesWorseThan:image];

    image.screenLocation = screenLocation;

    [imagesLock lock];
    [images addObject:image];
    [imagesLock unlock];

    if (!RMTileIsDummy(image.tile)) {
        if ([delegate respondsToSelector:@selector(tileImageAdded:)]) {
            [delegate tileImageAdded:image];
        }
    }
}

- (void)addTile:(RMTile)tile at:(CGRect)screenLocation
{
    // Is there an equivalent tile already in the cache?
    RMTileImage *tileImage = nil;

    [imagesLock lock];
    tileImage = [[[images member:[RMTileImage tileImageWithTile:tile]] retain] autorelease];
    [imagesLock unlock];

    if (tileImage != nil) {
        [tileImage setScreenLocation:screenLocation];

    } else {
        // Create empty RMTileImage
        // Add the tile to the images on screen
        tileImage = [RMTileImage tileImageWithTile:tile];
        if (tileImage != nil)
            [self addTileImage:tileImage at:screenLocation];

        // In a queue:
        //    - check cache
        //    - check tilesource
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [tileCache cachedImage:tile withCacheKey:currentCacheKey];
            if (image) {
                [tileImage updateWithImage:image andNotify:NO];
                [self removeTilesWorseThan:tileImage];
                return;
            }

            // RMTileDump(tile);

            // Return nil if you want to load the image asynchronously or display your own error tile (see [RMTileImage errorTile]
            image = [tileSource imageForTileImage:tileImage addToCache:tileCache withCacheKey:currentCacheKey];
            if (image) {
                [tileImage updateWithImage:image andNotify:YES];
            }
        });
    }
}

// Add tiles inside rect protected to bounds. Return rectangle containing bounds
// extended to full tile loading area
- (CGRect)loadTiles:(RMTileRect)rect toDisplayIn:(CGRect)bounds
{	
    RMTile t;
    float pixelsPerTile = bounds.size.width / rect.size.width;
    RMTileRect roundedRect = RMTileRectRound(rect);

    // The number of tiles we'll load in the vertical and horizontal directions
    int tileRegionWidth = (int)roundedRect.size.width;
    int tileRegionHeight = (int)roundedRect.size.height;
    id <RMMercatorToTileProjection> mercatorToTileProjection = [tileSource mercatorToTileProjection];
    short minimumZoom = [tileSource minZoom], alternateMinimum;

    // Now we translate the loaded region back into screen space for loadedBounds.
    CGRect newLoadedBounds;
    newLoadedBounds.origin.x = bounds.origin.x - (rect.origin.offset.x * pixelsPerTile);
    newLoadedBounds.origin.y = bounds.origin.y - (rect.origin.offset.y * pixelsPerTile);
    newLoadedBounds.size.width = tileRegionWidth * pixelsPerTile;
    newLoadedBounds.size.height = tileRegionHeight * pixelsPerTile;

    alternateMinimum = zoom - tileDepth - 1;
    if (minimumZoom < alternateMinimum)
        minimumZoom = alternateMinimum;

    for (;;)
    {
        CGRect screenLocation;
        screenLocation.size.width = pixelsPerTile;
        screenLocation.size.height = pixelsPerTile;
        t.zoom = rect.origin.tile.zoom;

        NSMutableArray *tilesToLoad = [NSMutableArray array];

        for (t.x = roundedRect.origin.tile.x; t.x < roundedRect.origin.tile.x + tileRegionWidth; t.x++)
        {
            for (t.y = roundedRect.origin.tile.y; t.y < roundedRect.origin.tile.y + tileRegionHeight; t.y++)
            {
                RMTile normalisedTile = [mercatorToTileProjection normaliseTile:t];

                if (RMTileIsDummy(normalisedTile))
                    continue;

                // this regrouping of terms is better for calculation precision (issue 128)
                screenLocation.origin.x = bounds.origin.x + (t.x - rect.origin.tile.x - rect.origin.offset.x) * pixelsPerTile;
                screenLocation.origin.y = bounds.origin.y + (t.y - rect.origin.tile.y - rect.origin.offset.y) * pixelsPerTile;
                [tilesToLoad addObject:[RMShuffleContainer containerWithTile:normalisedTile at:screenLocation]];
            }
        }

        //        RMLog(@"%d tiles to load", [tilesToLoad count]);

        // Load the tiles from the middle to the outside
        for (NSInteger i=[tilesToLoad count]; i>0; --i)
        {
            NSInteger index = i/2;
            RMShuffleContainer *tileToLoad = [tilesToLoad objectAtIndex:index];
            [self addTile:tileToLoad.tile at:tileToLoad.screenLocation];
            [tilesToLoad removeObjectAtIndex:index];
        }

        // adjust rect for next zoom level down until we're at minimum
        if (--rect.origin.tile.zoom <= minimumZoom)
            break;
        if (rect.origin.tile.x & 1)
            rect.origin.offset.x += 1.0;
        if (rect.origin.tile.y & 1)
            rect.origin.offset.y += 1.0;
        rect.origin.tile.x /= 2;
        rect.origin.tile.y /= 2;
        rect.size.width *= 0.5;
        rect.size.height *= 0.5;
        rect.origin.offset.x *= 0.5;
        rect.origin.offset.y *= 0.5;
        pixelsPerTile = bounds.size.width / rect.size.width;
        roundedRect = RMTileRectRound(rect);

        // The number of tiles we'll load in the vertical and horizontal directions
        tileRegionWidth = (int)roundedRect.size.width;
        tileRegionHeight = (int)roundedRect.size.height;
    }

    return newLoadedBounds;
}

- (RMTileImage *)imageWithTile:(RMTile)tile
{
    RMTileImage *tileImage = nil;

    [imagesLock lock];
    tileImage = [[[images member:[RMTileImage tileImageWithTile:tile]] retain] autorelease];
    [imagesLock unlock];

    return tileImage;
}

- (NSUInteger)count
{
    return [images count];
}

- (void)moveBy:(CGSize)delta
{
    [imagesLock lock];

    for (RMTileImage *image in images)
    {
        [image moveBy:delta];
    }

    [imagesLock unlock];
}

- (void)zoomByFactor:(float)zoomFactor near:(CGPoint)center
{
    [imagesLock lock];

    for (RMTileImage *image in images)
    {
        [image zoomByFactor:zoomFactor near:center];
    }

    [imagesLock unlock];
}

- (void)printDebuggingInformation
{
    float biggestSeamRight = 0.0f;
    float biggestSeamDown = 0.0f;

    [imagesLock lock];

    for (RMTileImage *image in images)
    {
        CGRect location = [image screenLocation];
        /*		RMLog(@"Image at %f, %f %f %f",
         location.origin.x,
         location.origin.y,
         location.origin.x + location.size.width,
         location.origin.y + location.size.height);
         */
        float seamRight = INFINITY;
        float seamDown = INFINITY;

        for (RMTileImage *other_image in images)
        {
            CGRect other_location = [other_image screenLocation];
            if (other_location.origin.x > location.origin.x)
                seamRight = MIN(seamRight, other_location.origin.x - (location.origin.x + location.size.width));
            if (other_location.origin.y > location.origin.y)
                seamDown = MIN(seamDown, other_location.origin.y - (location.origin.y + location.size.height));
        }

        if (seamRight != INFINITY)
            biggestSeamRight = MAX(biggestSeamRight, seamRight);

        if (seamDown != INFINITY)
            biggestSeamDown = MAX(biggestSeamDown, seamDown);
    }

    [imagesLock unlock];

    RMLog(@"Biggest seam right: %f  down: %f", biggestSeamRight, biggestSeamDown);
}

- (void)cancelLoading
{
    [imagesLock lock];

    for (RMTileImage *image in images)
    {
        [image cancelLoading];
    }

    [imagesLock unlock];
}

- (RMTileImage *)anyTileImage
{
    RMTileImage *tileImage = nil;

    [imagesLock lock];
    tileImage = [[[images anyObject] retain] autorelease];
    [imagesLock unlock];

    return tileImage;
}

- (short)zoom
{
    return zoom;
}

- (void)setZoom:(short)value
{
    if (zoom == value) {
        // no need to act
        return;
    }

    zoom = value;

    if (tileDepth == 0) {
        [self removeAllTiles];
        return;
    }

    [imagesLock lock];

    for (RMTileImage *image in [images allObjects])
    {
        if (![image isLoaded]) {
            continue;
        }
        [self removeTilesWorseThan:image];
    }

    [imagesLock unlock];
}

- (BOOL)fullyLoaded
{
    BOOL fullyLoaded = YES;

    [imagesLock lock];

    for (RMTileImage *image in images)
    {
        if (![image isLoaded])
        {
            fullyLoaded = NO;
            break;
        }
    }

    [imagesLock unlock];

    return fullyLoaded;
}

- (void)tileImageLoaded:(NSNotification *)notification
{
    RMTileImage *img = (RMTileImage *)[notification object];

    BOOL removeTiles = NO;

    [imagesLock lock];

    if (img && img == [images member:img]) {
        removeTiles = YES;
    }

    [imagesLock unlock];

    if (removeTiles) [self removeTilesWorseThan:img];
}

- (void)removeTilesWorseThan:(RMTileImage *)newImage
{
    RMTile newTile = newImage.tile;

    if (newTile.zoom > zoom) {
        // no tiles are worse since this one is too detailed to keep long-term
        return;
    }

    [imagesLock lock];

    for (RMTileImage *oldImage in [images allObjects])
    {
        RMTile oldTile = oldImage.tile;

        if (oldImage == newImage)
            continue;

        if ([self isTile:oldTile worseThanTile:newTile]) {
            [oldImage cancelLoading];
            [self removeTile:oldTile];
        }
    }

    [imagesLock unlock];
}

- (BOOL)isTile:(RMTile)subject worseThanTile:(RMTile)object
{
    short subjZ, objZ;
    uint32_t sx, sy, ox, oy;

    objZ = object.zoom;
    if (objZ > zoom) {
        // can't be worse than this tile, it's too detailed to keep long-term
        return NO;
    }

    subjZ = subject.zoom;
    if (subjZ + tileDepth >= zoom && subjZ <= zoom)
    {
        // this tile isn't bad, it's within zoom limits
        return NO;
    }

    sx = subject.x;
    sy = subject.y;
    ox = object.x;
    oy = object.y;

    if (subjZ < objZ) {
        // old tile is larger & blurrier
        unsigned int dz = objZ - subjZ;

        ox >>= dz;
        oy >>= dz;
    }
    else if (objZ < subjZ) {
        // old tile is smaller & more detailed
        unsigned int dz = subjZ - objZ;

        sx >>= dz;
        sy >>= dz;
    }

    if (sx != ox || sy != oy) {
        // Tiles don't overlap
        return NO;
    }

    if (abs(zoom - subjZ) < abs(zoom - objZ)) {
        // subject is closer to desired zoom level than object, so it's not worse
        return NO;
    }

    return YES;
}

- (void)removeTilesOutsideOf:(RMTileRect)rect
{
    uint32_t minX, maxX, minY, maxY, span;
    short currentZoom = rect.origin.tile.zoom;
    RMTile wrappedTile;
    id <RMMercatorToTileProjection> mercatorToTileProjection = [tileSource mercatorToTileProjection];

    rect = RMTileRectRound(rect);
    minX = rect.origin.tile.x;
    span = rect.size.width > 1.0f ? (uint32_t)rect.size.width - 1 : 0;
    maxX = rect.origin.tile.x + span;
    minY = rect.origin.tile.y;
    span = rect.size.height > 1.0f ? (uint32_t)rect.size.height - 1 : 0;
    maxY = rect.origin.tile.y + span;

    wrappedTile.x = maxX;
    wrappedTile.y = maxY;
    wrappedTile.zoom = rect.origin.tile.zoom;
    wrappedTile = [mercatorToTileProjection normaliseTile:wrappedTile];

    if (!RMTileIsDummy(wrappedTile))
        maxX = wrappedTile.x;

    [imagesLock lock];

    for (RMTileImage *img in [images allObjects])
    {
        RMTile tile = img.tile;
        short tileZoom = tile.zoom;
        uint32_t x, y, zoomedMinX, zoomedMaxX, zoomedMinY, zoomedMaxY;

        x = tile.x;
        y = tile.y;
        zoomedMinX = minX;
        zoomedMaxX = maxX;
        zoomedMinY = minY;
        zoomedMaxY = maxY;

        if (tileZoom < currentZoom)
        {
            // Tile is too large for current zoom level
            unsigned int dz = currentZoom - tileZoom;

            zoomedMinX >>= dz;
            zoomedMaxX >>= dz;
            zoomedMinY >>= dz;
            zoomedMaxY >>= dz;
        }
        else
        {
            // Tile is too small & detailed for current zoom level
            unsigned int dz = tileZoom - currentZoom;

            x >>= dz;
            y >>= dz;
        }

        if (y >= zoomedMinY && y <= zoomedMaxY)
        {
            if (zoomedMinX <= zoomedMaxX)
            {
                if (x >= zoomedMinX && x <= zoomedMaxX)
                    continue;
            }
            else
            {
                if (x >= zoomedMinX || x <= zoomedMaxX)
                    continue;
            }
        }

        // if haven't continued, tile is outside of rect
        [self removeTile:tile];
    }

    [imagesLock unlock];
}

@end
