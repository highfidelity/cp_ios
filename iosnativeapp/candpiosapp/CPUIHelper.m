//
//  CPUIHelper.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPUIHelper.h"
#define navbarShadowTag 991

@implementation CPUIHelper

+(void)addShadowToView:(UIView *)view color:(UIColor *)color offset:(CGSize)offset radius:(double)radius opacity:(double)opacity {
        view.layer.shadowColor = [color CGColor];
        view.layer.shadowOffset = offset;
        view.layer.shadowRadius = radius;
        view.layer.shadowOpacity = opacity;
        view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
}

+ (void)addDarkNavigationBarStyleToViewController:(UIViewController *)viewController
{
    // style the navigation bar
    UINavigationBar *navigationBar = viewController.navigationController.navigationBar;
    navigationBar.barStyle = UIBarStyleBlack;
    [navigationBar setBackgroundImage:[UIImage imageNamed: @"header.png"] forBarMetrics: UIBarMetricsDefault];
}

@end
