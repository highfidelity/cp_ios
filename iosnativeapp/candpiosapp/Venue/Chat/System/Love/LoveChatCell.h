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

+ (CGRect)chatEntryFrame;
+ (UIFont *)chatEntryFont;

@end
