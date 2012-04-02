//
//  UserTableViewCell.h
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 1/15/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserTableViewCell : UITableViewCell {
    UILabel *nicknameLabel;
    UILabel *statusLabel;
    UILabel *distanceLabel;
    UILabel *checkInLabel;
    UILabel *checkInCountLabel;
    UIImageView *profilePictureImageView;
}

@property (nonatomic, retain) IBOutlet UILabel *nicknameLabel;
@property (nonatomic, retain) IBOutlet UILabel *categoryLabel;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UILabel *distanceLabel;
@property (nonatomic, retain) IBOutlet UILabel *checkInLabel;
@property (nonatomic, retain) IBOutlet UILabel *checkInCountLabel;
@property (nonatomic, retain) IBOutlet UIImageView *profilePictureImageView;


@end
