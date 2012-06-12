//
//  RMMapScrollView.h
//  MapView
//
//  Created by Thomas Rasch on 11.06.12.
//  Copyright (c) 2012 Alpstein. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RMMapScrollView;

@protocol UIScrollViewConstraintsDelegate <NSObject>

- (CGPoint)scrollView:(RMMapScrollView *)aScrollView correctedOffsetForContentOffset:(CGPoint)aContentOffset;
- (CGSize)scrollView:(RMMapScrollView *)aScrollView correctedSizeForContentSize:(CGSize)aContentSize;

@end

@interface RMMapScrollView : UIScrollView

@property (nonatomic, assign) id <UIScrollViewConstraintsDelegate> constraintsDelegate;

@end
