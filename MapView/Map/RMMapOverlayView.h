//
//  RMMapOverlayView.h
//  MapView
//
//  Created by Thomas Rasch on 25.08.11.
//  Copyright (c) 2011 Alpstein. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RMMapOverlayView;

@protocol RMMapOverlayViewDelegate <NSObject>
@optional

- (void)mapOverlayView:(RMMapOverlayView *)aMapOverlayView singleTapAtPoint:(CGPoint)aPoint;
- (void)mapOverlayView:(RMMapOverlayView *)aMapOverlayView doubleTapAtPoint:(CGPoint)aPoint;
- (void)mapOverlayView:(RMMapOverlayView *)aMapOverlayView twoFingerTapAtPoint:(CGPoint)aPoint;
- (void)mapOverlayView:(RMMapOverlayView *)aMapOverlayView twoFingerDoubleTapAtPoint:(CGPoint)aPoint;

@end

@interface RMMapOverlayView : UIView {
    id <RMMapOverlayViewDelegate> delegate;
}

@property (nonatomic, assign) id <RMMapOverlayViewDelegate> delegate;

- (unsigned)sublayersCount;

- (void)addSublayer:(CALayer *)aLayer;
- (void)insertSublayer:(CALayer *)aLayer atIndex:(unsigned)index;

- (void)insertSublayer:(CALayer *)aLayer below:(CALayer *)sublayer;
- (void)insertSublayer:(CALayer *)aLayer above:(CALayer *)sublayer;

@end
