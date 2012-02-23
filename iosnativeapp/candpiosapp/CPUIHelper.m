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
    // style the navigaiton bar... add a drop shadow below.
    UINavigationBar *navigationBar = viewController.navigationController.navigationBar;
    navigationBar.barStyle = UIBarStyleBlack;
    [navigationBar setBackgroundImage:[UIImage imageNamed: @"header.png"] forBarMetrics: UIBarMetricsDefault];
    // Drop shadow
    UIImageView *shadowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"header-shadow.png"]];
    shadowView.frame = CGRectMake(0,
                                  navigationBar.frame.origin.y + navigationBar.frame.size.height, 
                                  navigationBar.frame.size.width, 
                                  shadowView.frame.size.height);
    shadowView.tag = navbarShadowTag;
    [viewController.navigationController.view addSubview:shadowView];    
}

@end
