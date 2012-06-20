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
        contentOffset = [self.mapScrollViewDelegate scrollView:self correctedOffsetForContentOffset:contentOffset];

    [super setContentOffset:contentOffset];
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated
{
    if (self.mapScrollViewDelegate)
        contentOffset = [self.mapScrollViewDelegate scrollView:self correctedOffsetForContentOffset:contentOffset];

    [super setContentOffset:contentOffset animated:animated];
}

- (void)setContentSize:(CGSize)contentSize
{
    if (self.mapScrollViewDelegate)
        contentSize = [self.mapScrollViewDelegate scrollView:self correctedSizeForContentSize:contentSize];

    [super setContentSize:contentSize];
}

@end
