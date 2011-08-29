//
//  RMMapOverlayView.m
//  MapView
//
//  Created by Thomas Rasch on 25.08.11.
//  Copyright (c) 2011 Alpstein. All rights reserved.
//

#import "RMMapOverlayView.h"
#import "RMMarker.h"

@interface RMMapOverlayView ()

- (void)handleSingleTap:(UIGestureRecognizer *)recognizer;

@end

@implementation RMMapOverlayView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;

    self.layer.masksToBounds = YES;

    UITapGestureRecognizer *singleTapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)] autorelease];
    [self addGestureRecognizer:singleTapRecognizer];

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

    return YES;
}

- (void)handleSingleTap:(UIGestureRecognizer *)recognizer
{
    CALayer *hit = [self.layer hitTest:[recognizer locationInView:self]];
    RMLog(@"LAYER of type %@",[hit description]);

    if (hit != nil)
    {
        CALayer *superlayer = [hit superlayer];

        // See if tap was on a marker or marker label and send delegate protocol method
        if ([hit isKindOfClass:[RMMarker class]]) {
            if ([delegate respondsToSelector:@selector(mapOverlayView:tapOnAnnotation:)]) {
                [delegate mapOverlayView:self tapOnAnnotation:[((RMMarker *)hit) annotation]];
            }
        } else if (superlayer != nil && [superlayer isKindOfClass:[RMMarker class]]) {
            if ([delegate respondsToSelector:@selector(mapOverlayView:tapOnLabelForAnnotation:)]) {
                [delegate mapOverlayView:self tapOnLabelForAnnotation:[((RMMarker *)superlayer) annotation]];
            }
        } else if ([superlayer superlayer] != nil && [[superlayer superlayer] isKindOfClass:[RMMarker class]]) {
            if ([delegate respondsToSelector:@selector(mapOverlayView:tapOnLabelForAnnotation:)]) {
                [delegate mapOverlayView:self tapOnLabelForAnnotation:[((RMMarker *)[superlayer superlayer]) annotation]];
            }
        }
    }
}

@end
