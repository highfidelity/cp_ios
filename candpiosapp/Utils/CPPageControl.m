//
//  CPPageControl.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 10/24/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPPageControl.h"

@interface CPPageControl ()

@property (nonatomic, retain) UIImage *imageNormal;
@property (nonatomic, retain) UIImage *imageCurrent;

@end


@implementation CPPageControl

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.imageNormal = [UIImage imageNamed:@"page-normal.png"];
        self.imageCurrent = [UIImage imageNamed:@"page-current.png"];
    }
    return self;
}

- (void)setCurrentPage:(NSInteger)currentPage
{
    [super setCurrentPage:currentPage];

    [self updateDots];
}

- (void)setNumberOfPages:(NSInteger)numberOfPages
{
    [super setNumberOfPages:numberOfPages];

    [self updateDots];
}

- (void)updateCurrentPageDisplay
{
    [super updateCurrentPageDisplay];

    [self updateDots];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super endTrackingWithTouch:touch withEvent:event];

    [self updateDots];
}

#pragma makr - private

- (void)updateDots
{
    for (NSUInteger i = 0; i < self.subviews.count; i++) {
        UIImageView *dot = self.subviews[i];
        CGPoint center = dot.center;
        dot.image = (self.currentPage == i) ? self.imageCurrent : self.imageNormal;
        dot.bounds = CGRectMake(0, 0, dot.image.size.width, dot.image.size.height);
        dot.center = center;
    }
}

@end
