//
//  CPThinTabBar.h
//  candpiosapp
//
//  Created by Stephen Birarda on 6/14/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPTabBarController.h"

#define BUTTON_WIDTH 55
#define LEFT_AREA_WIDTH 100

typedef enum {
    CPThinTabBarActionButtonStatePlus,
    CPThinTabBarActionButtonStateMinus,
    CPThinTabBarActionButtonStateUpdate,
    CPThinTabBarActionButtonStateQuestion
} CPThinTabBarActionButtonState;

@interface CPThinTabBar : UITabBar

@property (strong, nonatomic) UIButton *actionButton;
@property (weak, nonatomic) UITabBarController *tabBarController;
@property (nonatomic) CPThinTabBarActionButtonState actionButtonState;

- (void)moveGreenLineToSelectedIndex:(NSUInteger)selectedIndex;
- (void)toggleRightSide:(BOOL)shown;
- (void)refreshLastTab:(BOOL)loggedIn;
- (void)setBadgeNumber:(NSNumber *)number atTabIndex:(NSUInteger)index;

+ (UIImage *)backgroundImage;

@end
