//
//  CPSwipeableTableViewCell.h
//  candpiosapp
//
//  Created by Stephen Birarda on 5/16/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	CPSwipeableTableViewCellDirectionRight = 0,
	CPSwipeableTableViewCellDirectionLeft,
} CPSwipeableTableViewCellDirection;

typedef enum {
	CPSwipeableTableViewCellSwipeStyleFull = 0,
	CPSwipeableTableViewCellSwipeStyleQuickAction,
	CPSwipeableTableViewCellSwipeStyleNone,
} CPSwipeableTableViewCellSwipeStyle;


@class CPSwipeableTableViewCell;

@protocol CPSwipeableTableViewCellDelegate <NSObject>

@optional
- (BOOL)cellShouldReveal:(CPSwipeableTableViewCell *)cell;
- (void)cellDidBeginPan:(CPSwipeableTableViewCell *)cell;
- (void)cellDidReveal:(CPSwipeableTableViewCell *)cell;
- (void)quickActionForDirection:(CPSwipeableTableViewCellDirection)direction cell:(CPSwipeableTableViewCell *)sender;

@end

@interface CPSwipeableTableViewCell : UITableViewCell <UIGestureRecognizerDelegate>

@property (nonatomic, assign) id<CPSwipeableTableViewCellDelegate> delegate;
@property (nonatomic, strong) UIView *hiddenView;
@property (nonatomic, assign, getter = isRevealing) BOOL revealing;
@property (nonatomic, assign) BOOL shouldBounce;
@property (nonatomic, assign) CPSwipeableTableViewCellSwipeStyle leftStyle;
@property (nonatomic, assign) CPSwipeableTableViewCellSwipeStyle rightStyle;
@property (nonatomic, strong) NSArray *secretIconPrefixes;




@end
