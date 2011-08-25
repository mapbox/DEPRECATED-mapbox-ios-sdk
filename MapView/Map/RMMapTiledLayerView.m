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

CGPoint midpointBetweenPoints(CGPoint a, CGPoint b) {
    CGFloat x = (a.x + b.x) / 2.0;
    CGFloat y = (a.y + b.y) / 2.0;
    return CGPointMake(x, y);
}

@interface RMMapTiledLayerView ()

- (void)handleSingleTap;
- (void)handleDoubleTap;
- (void)handleTwoFingerTap;

@end

@implementation RMMapTiledLayerView

@synthesize delegate;

+ layerClass
{
    return [CATiledLayer class];
}

- (CATiledLayer *)tiledLayer
{  
    return (CATiledLayer *)self.layer;
}

- (id)initWithFrame:(CGRect)frame mapView:(RMMapView *)aMapView
{
    if (!(self = [super initWithFrame:frame]))
        return nil;

    mapView = aMapView;

    self.userInteractionEnabled = YES;
    self.multipleTouchEnabled = YES;
    twoFingerTapIsPossible = YES;
    multipleTouches = NO;

    CATiledLayer *tiledLayer = [self tiledLayer];
    tiledLayer.levelsOfDetailBias = [[mapView tileSource] maxZoom] - 1;
    tiledLayer.levelsOfDetail = [[mapView tileSource] maxZoom] - 1;
    
    return self;
}

- (void)layoutSubviews
{
    self.contentScaleFactor = 1.0f;
}

// Implement -drawRect: so that the UIView class works correctly
// Real drawing work is done in -drawLayer:inContext
-(void)drawRect:(CGRect)rect
{
    CGRect bounds = self.bounds;

    NSLog(@"drawRect: {{%.0f,%.0f},{%.2f,%.2f}}", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

    short zoom = log2(bounds.size.width / rect.size.width);
    int x = floor(rect.origin.x / rect.size.width), y = floor(fabs(rect.origin.y / rect.size.height));
    NSLog(@"Tile @ x:%d, y:%d, zoom:%d", x, y, zoom);

    UIImage *tileImage = [[mapView tileSource] imageForTile:RMTileMake(x, y, zoom) inCache:[mapView tileCache]];
    [tileImage drawInRect:rect];
}

#pragma mark -
#pragma mark Event handling

#define DOUBLE_TAP_DELAY 0.35

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Cancel any pending handleSingleTap messages.
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleSingleTap) object:nil];

    // Update the touch state.
    if ([[event touchesForView:self] count] > 1)
        multipleTouches = YES;
    if ([[event touchesForView:self] count] > 2)
        twoFingerTapIsPossible = NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    BOOL allTouchesEnded = ([touches count] == [[event touchesForView:self] count]);

    // first check for plain single/double tap, which is only possible if we haven't seen multiple touches
    if (!multipleTouches)
    {
        UITouch *touch = [touches anyObject];
        tapLocation = [touch locationInView:self];

        if ([touch tapCount] == 1) {
            [self performSelector:@selector(handleSingleTap) withObject:nil afterDelay:DOUBLE_TAP_DELAY];
        } else if([touch tapCount] == 2) {
            [self handleDoubleTap];
        }
    }
    
    // Check for a 2-finger tap if there have been multiple touches
    // and haven't that situation has not been ruled out
    else if (multipleTouches && twoFingerTapIsPossible)
    {
        // case 1: this is the end of both touches at once
        if ([touches count] == 2 && allTouchesEnded)
        {
            int i = 0;
            int tapCounts[2];
            CGPoint tapLocations[2];
            for (UITouch *touch in touches) {
                tapCounts[i] = [touch tapCount];
                tapLocations[i] = [touch locationInView:self];
                i++;
            }
            if (tapCounts[0] == 1 && tapCounts[1] == 1) {
                // it's a two-finger tap if they're both single taps
                tapLocation = midpointBetweenPoints(tapLocations[0], tapLocations[1]);
                [self handleTwoFingerTap];
            }
        }
        
        // Case 2: this is the end of one touch, and the other hasn't ended yet
        else if ([touches count] == 1 && !allTouchesEnded)
        {
            UITouch *touch = [touches anyObject];
            if ([touch tapCount] == 1) {
                // If touch is a single tap, store its location
                // so it can be averaged with the second touch location
                tapLocation = [touch locationInView:self];
            } else {
                twoFingerTapIsPossible = NO;
            }
        }
        
        // Case 3: this is the end of the second of the two touches
        else if ([touches count] == 1 && allTouchesEnded)
        {
            UITouch *touch = [touches anyObject];
            if ([touch tapCount] == 1) {
                // if the last touch up is a single tap, this was a 2-finger tap
                tapLocation = midpointBetweenPoints(tapLocation, [touch locationInView:self]);
                [self handleTwoFingerTap];
            }
        }
    }
    
    // if all touches are up, reset touch monitoring state
    if (allTouchesEnded) {
        twoFingerTapIsPossible = YES;
        multipleTouches = NO;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    twoFingerTapIsPossible = YES;
    multipleTouches = NO;
}

- (void)handleSingleTap
{
    if ([delegate respondsToSelector:@selector(tiledLayerView:gotSingleTapAtPoint:)])
        [delegate tiledLayerView:self singleTapAtPoint:tapLocation];
}

- (void)handleDoubleTap
{
    if ([delegate respondsToSelector:@selector(tiledLayerView:gotDoubleTapAtPoint:)])
        [delegate tiledLayerView:self doubleTapAtPoint:tapLocation];
}

- (void)handleTwoFingerTap
{
    if ([delegate respondsToSelector:@selector(tiledLayerView:gotTwoFingerTapAtPoint:)])
        [delegate tiledLayerView:self twoFingerTapAtPoint:tapLocation];
}

@end
