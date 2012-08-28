//
//  VenueCategoryCell.m
//  candpiosapp
//
//  Created by Andrew Hammond on 8/24/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "VenueCategoryCell.h"

@implementation VenueCategoryCell
@synthesize visibleView;

- (void)awakeFromNib {
    [super awakeFromNib];
    // gradient on the right side of the scrollview
    CGFloat gradientWidth = 45;
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(self.scrollView.frame.origin.x + self.scrollView.frame.size.width - gradientWidth,
                                self.scrollView.frame.origin.y,
                                gradientWidth,
                                self.scrollView.frame.size.height);
    gradient.colors = [NSArray arrayWithObjects:
                       (id)[[UIColor colorWithRed:(237.0/255.0) green:(237.0/255.0) blue:(237.0/255.0) alpha:0.0] CGColor],
                       (id)[[UIColor colorWithRed:(237.0/255.0) green:(237.0/255.0) blue:(237.0/255.0) alpha:1.0] CGColor],
                       (id)[[UIColor colorWithRed:(237.0/255.0) green:(237.0/255.0) blue:(237.0/255.0) alpha:1.0] CGColor],
                       nil];
    [gradient setStartPoint:CGPointMake(0.0, 0.5)];
    [gradient setEndPoint:CGPointMake(1.0, 0.5)];
    gradient.locations = @[@0.0, @0.65, @1.0];
    [self.visibleView.layer addSublayer:gradient];
}

@end
