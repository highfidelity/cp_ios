//
//  VenueChatCell.h
//  candpiosapp
//
//  Created by Stephen Birarda on 4/18/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VenueChatCell : UITableViewCell

@property (nonatomic, strong) UIButton *userThumbnail;
@property (nonatomic, strong) UILabel *chatEntry;

+ (CGRect)chatEntryFrame;
+ (UIFont *)chatEntryFont;

@end
