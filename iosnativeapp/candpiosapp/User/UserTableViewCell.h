//
//  UserTableViewCell.h
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 1/15/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserTableViewCell;

@protocol UserTableViewCellDelegate <NSObject>

-(void)clickedAcceptButtonInUserTableViewCell:(UserTableViewCell *)userTableViewCell;
-(void)clickedRejectButtonInUserTableViewCell:(UserTableViewCell *)userTableViewCell;

@end


@interface UserTableViewCell : UITableViewCell {
    NSIndexPath *cellIndexPath;
    id<UserTableViewCellDelegate> delegate;
    
    UILabel *nicknameLabel;
    UILabel *statusLabel;
    UILabel *distanceLabel;
    UILabel *checkInLabel;
    UILabel *checkInCountLabel;
    UIImageView *profilePictureImageView;
    
    UIButton *acceptContactRequestButton;
    UIButton *rejectContactRequestButton;
}

@property (nonatomic, retain) NSIndexPath *cellIndexPath;
@property (nonatomic, retain) id<UserTableViewCellDelegate> delegate;
@property (nonatomic, retain) IBOutlet UILabel *nicknameLabel;
@property (nonatomic, retain) IBOutlet UILabel *categoryLabel;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UILabel *distanceLabel;
@property (nonatomic, retain) IBOutlet UILabel *checkInLabel;
@property (nonatomic, retain) IBOutlet UILabel *checkInCountLabel;
@property (nonatomic, retain) IBOutlet UIImageView *profilePictureImageView;
@property (nonatomic, retain) IBOutlet UIButton *acceptContactRequestButton;
@property (nonatomic, retain) IBOutlet UIButton *rejectContactRequestButton;

@end
