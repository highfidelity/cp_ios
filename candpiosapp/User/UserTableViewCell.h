//
//  UserTableViewCell.h
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 1/15/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPUserActionCell.h"

@class UserTableViewCell;

@interface UserTableViewCell : CPUserActionCell

@property (weak, nonatomic) IBOutlet UILabel *nicknameLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *checkInLabel;
@property (weak, nonatomic) IBOutlet UILabel *checkInCountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureImageView;
@property (weak, nonatomic) IBOutlet UILabel *endorseCountLabel;
@property (weak, nonatomic) IBOutlet UIView *endorseCountUnderlineView;
@property (weak, nonatomic) IBOutlet UILabel *hoursWorkedLabel;
@property (weak, nonatomic) IBOutlet UILabel *hoursWorkedUnitLabel;
@property (weak, nonatomic) IBOutlet UIView *hoursWorkedUnderlineView;

@end
