//
//  RMMapOverlayView.h
//  MapView
//
//  Created by Thomas Rasch on 25.08.11.
//  Copyright (c) 2011 Alpstein. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RMMapOverlayView, RMAnnotation;

@protocol RMMapOverlayViewDelegate <NSObject>
@optional

- (void)mapOverlayView:(RMMapOverlayView *)aMapOverlayView tapOnAnnotation:(RMAnnotation *)anAnnotation atPoint:(CGPoint)aPoint;
- (void)mapOverlayView:(RMMapOverlayView *)aMapOverlayView doubleTapOnAnnotation:(RMAnnotation *)anAnnotation atPoint:(CGPoint)aPoint;
- (void)mapOverlayView:(RMMapOverlayView *)aMapOverlayView tapOnLabelForAnnotation:(RMAnnotation *)anAnnotation atPoint:(CGPoint)aPoint;
- (void)mapOverlayView:(RMMapOverlayView *)aMapOverlayView doubleTapOnLabelForAnnotation:(RMAnnotation *)anAnnotation atPoint:(CGPoint)aPoint;

- (BOOL)mapOverlayView:(RMMapOverlayView *)aMapOverlayView shouldDragAnnotation:(RMAnnotation *)anAnnotation;
- (void)mapOverlayView:(RMMapOverlayView *)aMapOverlayView didDragAnnotation:(RMAnnotation *)anAnnotation withDelta:(CGPoint)delta;
- (void)mapOverlayView:(RMMapOverlayView *)aMapOverlayView didEndDragAnnotation:(RMAnnotation *)anAnnotation;

@end

@interface RMMapOverlayView : UIView
{
    id <RMMapOverlayViewDelegate> delegate;
}

@property (nonatomic, assign) id <RMMapOverlayViewDelegate> delegate;

- (unsigned)sublayersCount;

- (void)addSublayer:(CALayer *)aLayer;
- (void)insertSublayer:(CALayer *)aLayer atIndex:(unsigned)index;

- (void)insertSublayer:(CALayer *)aLayer below:(CALayer *)sublayer;
- (void)insertSublayer:(CALayer *)aLayer above:(CALayer *)sublayer;

- (void)moveLayersBy:(CGPoint)delta;

@end
