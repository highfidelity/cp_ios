//
//  CPUserActionCell.h
//  candpiosapp
//
//  Created by Andrew Hammond on 7/7/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIKit.h>
#import "CPSoundEffectsManager.h"
#import "User.h"

#define kCancelOpenSlideActionButtonsNotification @"kCancelOpenSlideActionButtonsNotification"

typedef enum {
	CPUserActionCellDirectionRight = 0,
	CPUserActionCellDirectionLeft,
} CPUserActionCellDirection;

typedef enum {
    CPUserActionCellSwipeStyleNone = 0,
    CPUserActionCellSwipeStyleQuickAction,
    CPUserActionCellSwipeStyleReducedAction,
} CPUserActionCellSwipeStyle;

@class CPUserActionCell;

@protocol CPUserActionCellDelegate <NSObject>

@optional
- (void)cell:(CPUserActionCell*)cell didSelectSendLoveToUser:(User*)user;
- (void)cell:(CPUserActionCell*)cell didSelectSendMessageToUser:(User*)user;
- (void)cell:(CPUserActionCell*)cell didSelectExchangeContactsWithUser:(User*)user;
- (void)cell:(CPUserActionCell*)cell didSelectRowWithUser:(User*)user;

@end

@interface CPUserActionCell : UITableViewCell <UIGestureRecognizerDelegate, UIActionSheetDelegate>

@property (nonatomic, assign) id<CPUserActionCellDelegate> delegate;
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) UIView *hiddenView;
@property (nonatomic, assign, getter = isRevealing) BOOL revealing;
@property (nonatomic, assign) BOOL shouldBounce;
@property (nonatomic, assign) CPUserActionCellSwipeStyle leftStyle;
@property (nonatomic, assign) CPUserActionCellSwipeStyle rightStyle;
@property (nonatomic, strong) UIButton *sendLoveButton;
@property (nonatomic, strong) UIButton *sendMessageButton;
@property (nonatomic, strong) UIButton *exchangeContactsButton;
@property (nonatomic, strong) UIColor *activeColor;
@property (nonatomic, strong) UIColor *inactiveColor;
@property (nonatomic, readonly) CGFloat originalCenter;

+ (void)cancelOpenSlideActionButtonsNotification:(CPUserActionCell *)cell;
- (void)animateSlideButtonsWithNewCenter:(CGFloat)newCenter delay:(NSTimeInterval)delay duration:(NSTimeInterval)duration animated:(BOOL)animated;

@end
