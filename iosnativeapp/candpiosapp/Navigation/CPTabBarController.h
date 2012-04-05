//
//  CPTabBarController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 4/2/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CPTabBarController : UITabBarController

@property (nonatomic, strong) UIButton *centerButton;

- (void)addCenterButtonWithImage:(UIImage *)buttonImage;

@end
