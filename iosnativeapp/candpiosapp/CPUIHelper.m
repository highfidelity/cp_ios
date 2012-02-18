//
//  CPUIHelper.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPUIHelper.h"

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
    // style the navigaiton bar... add a drop shadow below.
    UINavigationBar *navigationBar = viewController.navigationController.navigationBar;
    navigationBar.barStyle = UIBarStyleBlack;
    [navigationBar setBackgroundImage:[UIImage imageNamed: @"header.png"] forBarMetrics: UIBarMetricsDefault];
    // The dark underside of the nav bar, visible when the settings menu slides open
    UIImageView *underBarImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"header.png"]];
    underBarImageView.frame = navigationBar.frame;
    underBarImageView.alpha = 0.75;
    [viewController.navigationController.view insertSubview:underBarImageView atIndex:0];
    // Drop shadow
    UIImageView *shadowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"header-shadow.png"]];
    shadowView.frame = CGRectMake(0,
                                  navigationBar.frame.origin.y + navigationBar.frame.size.height, 
                                  navigationBar.frame.size.width, 
                                  shadowView.frame.size.height);
    [viewController.navigationController.view addSubview:shadowView];    
}

@end
