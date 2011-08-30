//
//  RMMapOverlayView.m
//  MapView
//
//  Created by Thomas Rasch on 25.08.11.
//  Copyright (c) 2011 Alpstein. All rights reserved.
//

#import "RMMapOverlayView.h"
#import "RMMarker.h"
#import "RMAnnotation.h"
#import "RMPixel.h"

@interface RMMapOverlayView ()

- (void)handleSingleTap:(UIGestureRecognizer *)recognizer;
- (void)handleDoubleTap:(UIGestureRecognizer *)recognizer;

@end

@implementation RMMapOverlayView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;

    self.layer.masksToBounds = YES;

    UITapGestureRecognizer *doubleTapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)] autorelease];
    doubleTapRecognizer.numberOfTapsRequired = 2;

    UITapGestureRecognizer *singleTapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)] autorelease];
    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];

    [self addGestureRecognizer:singleTapRecognizer];
    [self addGestureRecognizer:doubleTapRecognizer];

    return self;
}

- (unsigned)sublayersCount
{
    return [self.layer.sublayers count];
}

- (void)addSublayer:(CALayer *)aLayer
{
    [self.layer addSublayer:aLayer];
}

- (void)insertSublayer:(CALayer *)aLayer atIndex:(unsigned)index
{
    [self.layer insertSublayer:aLayer atIndex:index];
}

- (void)insertSublayer:(CALayer *)aLayer below:(CALayer *)sublayer
{
    [self.layer insertSublayer:aLayer below:sublayer];
}

- (void)insertSublayer:(CALayer *)aLayer above:(CALayer *)sublayer
{
    [self.layer insertSublayer:aLayer above:sublayer];
}

- (void)moveLayersBy:(CGSize)delta
{
    for (CALayer *currentLayer in self.layer.sublayers)
    {
        currentLayer.position = RMTranslateCGPointBy(currentLayer.position, delta);
    }
}

#pragma mark -
#pragma mark Event handling

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if ([[event touchesForView:self] count] > 1)
        return NO;

    CALayer *hit = [self.layer hitTest:point];
    if (!hit || ![hit isKindOfClass:[RMMarker class]]) {
        return NO;
    }

    return ((RMMarker *)hit).annotation.enabled;
}

- (void)handleSingleTap:(UIGestureRecognizer *)recognizer
{
    CALayer *hit = [self.layer hitTest:[recognizer locationInView:self]];

    if (hit != nil)
    {
        CALayer *superlayer = [hit superlayer];

        // See if tap was on a marker or marker label and send delegate protocol method
        if ([hit isKindOfClass:[RMMarker class]]) {
            if ([delegate respondsToSelector:@selector(mapOverlayView:tapOnAnnotation:atPoint:)]) {
                [delegate mapOverlayView:self tapOnAnnotation:[((RMMarker *)hit) annotation] atPoint:[recognizer locationInView:self]];
            }
        } else if (superlayer != nil && [superlayer isKindOfClass:[RMMarker class]]) {
            if ([delegate respondsToSelector:@selector(mapOverlayView:tapOnLabelForAnnotation:atPoint:)]) {
                [delegate mapOverlayView:self tapOnLabelForAnnotation:[((RMMarker *)superlayer) annotation] atPoint:[recognizer locationInView:self]];
            }
        } else if ([superlayer superlayer] != nil && [[superlayer superlayer] isKindOfClass:[RMMarker class]]) {
            if ([delegate respondsToSelector:@selector(mapOverlayView:tapOnLabelForAnnotation:atPoint:)]) {
                [delegate mapOverlayView:self tapOnLabelForAnnotation:[((RMMarker *)[superlayer superlayer]) annotation] atPoint:[recognizer locationInView:self]];
            }
        }
    }
}

- (void)handleDoubleTap:(UIGestureRecognizer *)recognizer
{
    CALayer *hit = [self.layer hitTest:[recognizer locationInView:self]];

    if (hit != nil)
    {
        CALayer *superlayer = [hit superlayer];

        // See if tap was on a marker or marker label and send delegate protocol method
        if ([hit isKindOfClass:[RMMarker class]]) {
            if ([delegate respondsToSelector:@selector(mapOverlayView:doubleTapOnAnnotation:atPoint:)]) {
                [delegate mapOverlayView:self doubleTapOnAnnotation:[((RMMarker *)hit) annotation] atPoint:[recognizer locationInView:self]];
            }
        } else if (superlayer != nil && [superlayer isKindOfClass:[RMMarker class]]) {
            if ([delegate respondsToSelector:@selector(mapOverlayView:doubleTapOnLabelForAnnotation:atPoint:)]) {
                [delegate mapOverlayView:self doubleTapOnLabelForAnnotation:[((RMMarker *)superlayer) annotation] atPoint:[recognizer locationInView:self]];
            }
        } else if ([superlayer superlayer] != nil && [[superlayer superlayer] isKindOfClass:[RMMarker class]]) {
            if ([delegate respondsToSelector:@selector(mapOverlayView:doubleTapOnLabelForAnnotation:atPoint:)]) {
                [delegate mapOverlayView:self doubleTapOnLabelForAnnotation:[((RMMarker *)[superlayer superlayer]) annotation] atPoint:[recognizer locationInView:self]];
            }
        }
    }
}

@end
