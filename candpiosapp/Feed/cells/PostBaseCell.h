//
//  PostBaseCell.h
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPUserActionCell.h"
#import "CPPost.h"

@interface PostBaseCell : CPUserActionCell

@property (weak, nonatomic) IBOutlet UIButton *senderProfileButton;
@property (weak, nonatomic) IBOutlet UILabel *entryLabel;
@property (strong, nonatomic) CPPost* post;
@property (strong, nonatomic) UIButton *plusButton;
@property (strong, nonatomic) UILabel *likeCountLabel;
@property (strong, nonatomic) UIImageView *likeCountBubble;

- (void) addPlusWidget;
- (void) changeLikeCountToValue:(int)value animated:(BOOL)animated;

@end
