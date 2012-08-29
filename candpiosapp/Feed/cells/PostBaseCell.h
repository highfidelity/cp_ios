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
#import "WEPopoverController.h"

@interface PostBaseCell : CPUserActionCell

@property (weak, nonatomic) IBOutlet UIButton *senderProfileButton;
@property (weak, nonatomic) IBOutlet UILabel *entryLabel;
@property (nonatomic, strong) CPPost* post;
@property (strong, nonatomic) CAGradientLayer *gradientLayer;

- (void)updateGradientAndSetVisible:(BOOL)visible;
@end
