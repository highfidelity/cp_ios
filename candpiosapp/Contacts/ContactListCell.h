//
//  ContactListCell.h
//  candpiosapp
//
//  Created by Stephen Birarda on 5/18/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserTableViewCell.h"

@class ContactListCell;

@protocol ContactListCellDelegate

- (void)clickedAcceptButtonInUserTableViewCell:(ContactListCell *)contactListCell;
- (void)clickedDeclineButtonInUserTableViewCell:(ContactListCell *)contactListCell;

@end

@interface ContactListCell : CPUserActionCell

@property (weak, nonatomic) id<ContactListCellDelegate> contactListTVC;
@property (weak, nonatomic) IBOutlet UIImageView *profilePicture;
@property (weak, nonatomic) IBOutlet UILabel *nicknameLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *acceptContactRequestButton;
@property (weak, nonatomic) IBOutlet UIButton *declineContactRequestButton;

- (IBAction)acceptButtonAction;
- (IBAction)declineButtonAction;

@end
