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

#pragma mark - UI Elements

+(void)addShadowToView:(UIView *)view
                 color:(UIColor *)color
                offset:(CGSize)offset
                radius:(double)radius
               opacity:(double)opacity
{
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
    [navigationBar setBackgroundImage:[UIImage imageNamed: @"header.png"]
                        forBarMetrics: UIBarMetricsDefault];
}

// apparently it is a bad idea to subclass UIButton
// this method will give you a UIButton with C&P styling
+ (UIButton *)CPButtonWithText:(NSString *)buttonText color:(CPButtonColor)buttonColor frame:(CGRect)buttonFrame
{
    // get a button with the passed frame
    UIButton *cpButton = [[UIButton alloc] initWithFrame:buttonFrame];
    
    // set the background color using the imageForColorString method
    [cpButton setBackgroundImage:[self imageForCPColor:buttonColor] forState:UIControlStateNormal];
    
    [cpButton setTitle:buttonText forState:UIControlStateNormal];
    [cpButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    cpButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    cpButton.titleLabel.layer.shadowOffset = CGSizeMake(0, -1);
    cpButton.titleLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
    cpButton.titleLabel.layer.shadowOpacity = 0.5;
    cpButton.titleLabel.layer.shadowRadius = 0.0;   
    
    return cpButton;
}

// used by the method above to return a UIImage for the button background
+ (UIImage *)imageForCPColor:(CPButtonColor)buttonColor
{
    switch (buttonColor) {
        case CPButtonTurquoise:
            return [[UIImage imageNamed:@"button-turquoise.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 9, 0, 9)];
        case CPButtonGrey:
            return [[UIImage imageNamed:@"button-grey.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 9, 0, 9)];
        default:
            return nil;
    }
}

#pragma mark - Color schemes

+ (UIColor *)colorForCPColor:(CPColor)cpColor
{
    switch (cpColor) {
        case CPColorGreen:
            return [UIColor colorWithRed:0.259f green:0.549f blue:0.588f alpha:1.0f];
        case CPColorGrey:
            return [UIColor colorWithRed:0.47f green:0.47f blue:0.47f alpha:1.0f];
        default:
            return nil;
    }
}

@end
