//
//  CPThinTabBar.h
//  .
//
//  Created by Stephen Birarda on 6/14/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPTabBarController.h"

#define BUTTON_WIDTH 55
#define LEFT_AREA_WIDTH 100

@interface CPThinTabBar : UITabBar

@property (nonatomic, strong) UIView *thinBarBackground;
@property (nonatomic, assign) UITabBarController *tabBarController;
@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIView *actionMenu;

@property (nonatomic, strong) UIButton *barButton1;
@property (nonatomic, strong) UIButton *barButton2;
@property (nonatomic, strong) UIButton *barButton3;
@property (nonatomic, strong) UIButton *barButton4;

- (void)actionMenuSetup;
- (void)toggleActionMenu:(BOOL)showMenu;
- (void)toggleActionButtonState:(BOOL)showMenu;
- (void)moveGreenLineToSelectedIndex:(NSUInteger)selectedIndex;
- (void)toggleRightSide:(BOOL)shown;
- (void)refreshLastTab:(BOOL)loggedIn;

+ (UIImage *)backgroundImage;

@end
