//
//  CPThinTabBar.h
//  candpiosapp
//
//  Created by Stephen Birarda on 6/14/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPTabBarController.h"

#define BUTTON_WIDTH 72
#define LEFT_AREA_WIDTH 104

@interface CPThinTabBar : UITabBar

@property (weak, nonatomic) UITabBarController *tabBarController;

- (CGFloat)actionButtonRadius;
- (void)moveGreenLineToSelectedIndex:(NSUInteger)selectedIndex;
- (void)refreshLastTab:(BOOL)loggedIn;
- (void)setBadgeNumber:(NSNumber *)number atTabIndex:(NSUInteger)index;

+ (UIImage *)backgroundImage;


@end
