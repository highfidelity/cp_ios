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
#import "CPSwipeableQuickActionSwitch.h"
#import "User.h"

typedef enum {
	CPUserActionCellDirectionRight = 0,
	CPUserActionCellDirectionLeft,
} CPUserActionCellDirection;

typedef enum {
	CPUserActionCellSwipeStyleFull = 0,
	CPUserActionCellSwipeStyleQuickAction,
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
@property (nonatomic) CPUserActionCellSwitchState toggleState;

@end
