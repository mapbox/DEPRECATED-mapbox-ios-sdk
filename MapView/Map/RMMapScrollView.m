//
//  RMMapScrollView.m
//  MapView
//
//  Created by Thomas Rasch on 11.06.12.
//  Copyright (c) 2012 Alpstein. All rights reserved.
//

#import "RMMapScrollView.h"

@implementation RMMapScrollView

@synthesize mapScrollViewDelegate;

- (void)setContentOffset:(CGPoint)contentOffset
{
    if (self.mapScrollViewDelegate)
        [self.mapScrollViewDelegate scrollView:self correctedContentOffset:&contentOffset];

    [super setContentOffset:contentOffset];
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated
{
    if (self.mapScrollViewDelegate)
        [self.mapScrollViewDelegate scrollView:self correctedContentOffset:&contentOffset];

    [super setContentOffset:contentOffset animated:animated];
}

- (void)setContentSize:(CGSize)contentSize
{
    CGFloat factor = 1.0;

    if (self.mapScrollViewDelegate)
    {
        CGSize previousContentSize = contentSize;

        [self.mapScrollViewDelegate scrollView:self correctedContentSize:&contentSize];

        factor = contentSize.width / previousContentSize.width;
    }

    [super setContentSize:contentSize];

    if (factor != 1.0)
        self.zoomScale *= factor;
}

@end
