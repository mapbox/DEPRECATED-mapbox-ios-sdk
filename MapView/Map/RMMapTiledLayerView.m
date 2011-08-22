//
//  RMMapTiledLayerView.m
//  MapView
//
//  Created by Thomas Rasch on 17.08.11.
//  Copyright (c) 2011 Alpstein. All rights reserved.
//

#import "RMMapTiledLayerView.h"

#import "RMMapView.h"
#import "RMTileSource.h"

@implementation RMMapTiledLayerView

+ layerClass
{
    return [CATiledLayer class];
}

- (id)initWithFrame:(CGRect)frame mapView:(RMMapView *)aMapView
{
    if (!(self = [super initWithFrame:frame]))
        return nil;

    mapView = aMapView;

    CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
    tiledLayer.tileSize = CGSizeMake([[mapView tileSource] tileSideLength], [[mapView tileSource] tileSideLength]);
    tiledLayer.levelsOfDetail = [[mapView tileSource] maxZoom] - 1;
    tiledLayer.levelsOfDetailBias = [[mapView tileSource] maxZoom] - 1;

    return self;
}

// Implement -drawRect: so that the UIView class works correctly
// Real drawing work is done in -drawLayer:inContext
-(void)drawRect:(CGRect)rect
{
}

-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    CGContextScaleCTM(context, 1.0f, -1.0f);

    CGRect bounds = self.bounds;

    CGRect rect = CGContextGetClipBoundingBox(context);
//    DLog(@"drawRect: {{%.0f,%.0f},{%.2f,%.2f}}", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

    short zoom = log2(bounds.size.width / rect.size.width);
    int x = (rect.origin.x / rect.size.width), y = fabs(rect.origin.y / rect.size.height) - 1;
    NSLog(@"x:%d, y:%d, zoom:%d", x, y, zoom);
    
    UIImage *tileImage = [[mapView tileSource] imageForTile:RMTileMake(x, y, zoom)
                                                    inCache:[mapView tileCache]];

	CGContextDrawImage(context, rect, tileImage.CGImage);
}

@end
