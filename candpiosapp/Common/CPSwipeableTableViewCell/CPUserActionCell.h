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

typedef enum {
	CPUserActionCellDirectionRight = 0,
	CPUserActionCellDirectionLeft,
} CPUserActionCellDirection;

typedef enum {
	CPUserActionCellSwipeStyleFull = 0,
    CPUserActionCellSwipeStyleQuickAction,
    CPUserActionCellSwipeStyleReducedAction,
	CPUserActionCellSwipeStyleNone,
} CPUserActionCellSwipeStyle;

// toggle switch state
// 0 - nothing activated
// 1 - send love active
// 2 - send message active
// 3 - exchange contacts active
typedef enum {
	CPUserActionCellSwitchStateOff = 0,
	CPUserActionCellSwitchStateSendLoveOn,
	CPUserActionCellSwitchStateSendMessageOn,
    CPUserActionCellSwitchStateExchangeContactsOn,
} CPUserActionCellSwitchState;


@class CPUserActionCell;

@protocol CPUserActionCellDelegate <NSObject>

@optional
- (void)cell:(CPUserActionCell*)cell didSelectSendLoveToUser:(User*)user;
- (void)cell:(CPUserActionCell*)cell didSelectSendMessageToUser:(User*)user;
- (void)cell:(CPUserActionCell*)cell didSelectExchangeContactsWithUser:(User*)user;
- (void)cell:(CPUserActionCell*)cell didSelectRowWithUser:(User*)user;

@end

@interface CPUserActionCell : UITableViewCell <UIGestureRecognizerDelegate, UIActionSheetDelegate>

@property (nonatomic) id<CPUserActionCellDelegate> delegate;
@property (strong, nonatomic) User *user;
@property (strong, nonatomic) UIView *hiddenView;
@property (nonatomic, getter = isRevealing) BOOL revealing;
@property (strong, nonatomic) UIButton *sendLoveButton;
@property (strong, nonatomic) UIButton *sendMessageButton;
@property (strong, nonatomic) UIButton *exchangeContactsButton;
@property (strong, nonatomic) UIColor *activeColor;
@property (strong, nonatomic) UIColor *inactiveColor;
@property (nonatomic) BOOL shouldBounce;
@property (nonatomic) CPUserActionCellSwipeStyle leftStyle;
@property (nonatomic) CPUserActionCellSwipeStyle rightStyle;
@property (nonatomic) CPUserActionCellSwitchState toggleState;

@end
