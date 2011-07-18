//
//  RMCoreAnimationRenderer.m
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

#import <QuartzCore/QuartzCore.h>

#import "RMGlobalConstants.h"
#import "RMCoreAnimationRenderer.h"
#import "RMTile.h"
#import "RMTileLoader.h"
#import "RMPixel.h"
#import "RMTileImage.h"
#import "RMMapView.h"

@implementation RMCoreAnimationRenderer

- (id)initWithView:(RMMapView *)aMapView
{
	if (!(self = [super init]))
		return nil;

	mapView = aMapView;

	// NOTE: RMMapContents may still be initialising when this function
	//       is called. Be careful using any of the methods - they might return
	//       strange data.

	layer = [[CAScrollLayer layer] retain];
	layer.anchorPoint = CGPointZero;
	layer.masksToBounds = YES;

	// If the frame is set incorrectly here, it will be fixed when setRenderer is called in RMMapContents
	layer.frame = [mapView screenBounds];

	NSMutableDictionary *customActions = [NSMutableDictionary dictionaryWithDictionary:[layer actions]];
	[customActions setObject:[NSNull null] forKey:@"sublayers"];
	layer.actions = customActions;
	layer.delegate = self;

	tiles = [[NSMutableArray alloc] init];

	return self;
}

- (void)dealloc
{
	[tiles release]; tiles = nil;
	[layer release]; layer = nil;
	[super dealloc];
}

- (void)tileImageAdded:(RMTileImage *)image
{
//	RMLog(@"tileAdded: %d %d %d at %f %f %f %f", tile.x, tile.y, tile.zoom, image.screenLocation.origin.x, image.screenLocation.origin.y,
//		  image.screenLocation.size.width, image.screenLocation.size.height);
	
//	RMLog(@"tileAdded");

    @synchronized (tiles) {
        RMTile tile = image.tile;
        NSUInteger min = 0, max = [tiles count];
        CALayer *sublayer = [image layer];
        sublayer.delegate = self;

        while (min < max) {
            // Binary search for insertion point
            NSUInteger pivot = (min + max) / 2;
            RMTileImage *other = [tiles objectAtIndex:pivot];
            RMTile otherTile = other.tile;

            if (otherTile.zoom <= tile.zoom) {
                min = pivot + 1;
            }
            if (otherTile.zoom > tile.zoom) {
                max = pivot;
            }
        }

        [tiles insertObject:image atIndex:min];
        [layer insertSublayer:sublayer atIndex:min];
    }
}

- (void)tileImageRemoved:(RMTileImage *)tileImage
{
    @synchronized (tiles) {
        RMTileImage *image = nil;
        RMTile tile = tileImage.tile;

        for (NSInteger i = [tiles count]-1; i>=0; --i)
        {
            RMTileImage *potential = [tiles objectAtIndex:i];

            if (RMTilesEqual(tile, potential.tile))
            {
                image = [[potential retain] autorelease];
                [tiles removeObjectAtIndex:i];
                break;
            }
        }

//	RMLog(@"tileRemoved: %d %d %d at %f %f %f %f", tile.x, tile.y, tile.zoom, image.screenLocation.origin.x, image.screenLocation.origin.y,
//		  image.screenLocation.size.width, image.screenLocation.size.height);

        [[image layer] removeFromSuperlayer];
    }
}

- (CGRect)frame
{
    return layer.frame;
}

// \bug ??? frame is always set to the screen bounds?
- (void)setFrame:(CGRect)frame
{
	layer.frame = [mapView screenBounds];
}

- (CALayer *)layer
{
	return layer;
}

@end
