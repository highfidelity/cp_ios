//
//  LoveChatCell.h
//  candpiosapp
//
//  Created by Stephen Birarda on 5/9/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VenueChatCell.h"

@interface LoveChatCell : VenueChatCell

@property (nonatomic, strong) UIButton *recipientThumbnail;
@property (nonatomic, strong) UIButton *plusOneButton;
@property (nonatomic, strong) UIActivityIndicatorView *plusOneSpinner;
@property (nonatomic, strong) UIImageView *loveCountBubble;
@property (nonatomic, strong) UILabel *loveCountLabel;
@property (nonatomic, assign) int loveCount;

+ (CGRect)chatEntryFrame;
+ (UIFont *)chatEntryFont;
- (void)togglePlusOneButton:(BOOL)enabled;

@end
