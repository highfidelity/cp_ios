//
//  PostBaseCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "PostBaseCell.h"
#import "FeedViewController.h"

#define GRADIENT_WIDTH 120

@implementation PostBaseCell

- (void)awakeFromNib
{
    // grab a timeLine view using the class method in FeedViewController    
    // add the timeline to our contentView
    [super awakeFromNib];
    [self.contentView insertSubview:[FeedViewController timelineViewWithHeight:self.frame.size.height] atIndex:0];
    
    // gradient on the right side of the scrollview
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.colors = [NSArray arrayWithObjects:
                                 (id)[RGBA(246, 247, 245, 0.0) CGColor],
                                 (id)[RGBA(246, 247, 245, 1.0) CGColor],
                                 (id)[RGBA(246, 247, 245, 1.0) CGColor],
                                 nil];
    [self.gradientLayer setStartPoint:CGPointMake(0.0, 0.5)];
    [self.gradientLayer setEndPoint:CGPointMake(1.0, 0.5)];
    self.gradientLayer.locations = @[@0.0, @0.65, @1.0];
    [self.entryLabel.layer addSublayer:self.gradientLayer];
}

- (void)updateGradientAndSetVisible:(BOOL)visible
{
    self.gradientLayer.opacity = visible ? 1 : 0;
    CGFloat lineHeight = self.entryLabel.font.lineHeight;
    self.gradientLayer.frame = CGRectMake(self.entryLabel.frame.size.width - GRADIENT_WIDTH,
                                          self.entryLabel.frame.size.height - lineHeight,
                                          GRADIENT_WIDTH,
                                          lineHeight);
}

@end