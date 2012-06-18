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

@interface CPThinTabBar : UIView

@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIView *greenLine;
@property (nonatomic, assign) UITabBarController *tabBarController;
@property (nonatomic, strong) UIButton *barButton1;
@property (nonatomic, strong) UIButton *barButton2;
@property (nonatomic, strong) UIButton *barButton3;
@property (nonatomic, strong) UIButton *barButton4;

- (id)initWithFrame:(CGRect)frame backgroundImage:(UIImage *)backgroundImage;
- (void)moveGreenLineToSelectedIndex:(NSUInteger)selectedIndex;
- (void)toggleRightSide:(BOOL)shown;

@end
