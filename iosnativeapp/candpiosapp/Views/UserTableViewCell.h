//
//  UserTableViewCell.h
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 1/15/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserTableViewCell : UITableViewCell {
    UILabel *nickameLabel;
    UILabel *skillsLabel;
    UILabel *distanceLabel;
}

@property (nonatomic, retain) UILabel *nicknameLabel;
@property (nonatomic, retain) UILabel *skillsLabel;
@property (nonatomic, retain) UILabel *distanceLabel;

@end
