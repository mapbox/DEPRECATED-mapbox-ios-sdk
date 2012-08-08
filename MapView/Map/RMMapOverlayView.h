//
//  RMMapOverlayView.h
//  MapView
//
//  Created by Thomas Rasch on 25.08.11.
//  Copyright (c) 2011 Alpstein. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RMAnnotation;

@interface RMMapOverlayView : UIView

- (unsigned)sublayersCount;

- (void)addSublayer:(CALayer *)aLayer;
- (void)insertSublayer:(CALayer *)aLayer atIndex:(unsigned)index;

- (void)insertSublayer:(CALayer *)aLayer below:(CALayer *)sublayer;
- (void)insertSublayer:(CALayer *)aLayer above:(CALayer *)sublayer;

- (void)moveLayersBy:(CGPoint)delta;

- (CALayer *)overlayHitTest:(CGPoint)point;

@end
