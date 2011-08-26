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
- (void)handleDoubleTap:(UIGestureRecognizer *)recognizer;

@end

@implementation RMMapOverlayView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;

    self.layer.masksToBounds = YES;

    UITapGestureRecognizer *singleTapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)] autorelease];
    UITapGestureRecognizer *doubleTapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)] autorelease];
    doubleTapRecognizer.numberOfTapsRequired = 2;
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
    if ([delegate respondsToSelector:@selector(mapOverlayView:singleTapAtPoint:)])
        [delegate mapOverlayView:self singleTapAtPoint:[recognizer locationInView:self]];
}

- (void)handleDoubleTap:(UIGestureRecognizer *)recognizer
{
    if ([delegate respondsToSelector:@selector(mapOverlayView:doubleTapAtPoint:)])
        [delegate mapOverlayView:self doubleTapAtPoint:[recognizer locationInView:self]];
}


@end
