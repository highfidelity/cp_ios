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

@property (nonatomic) id<ContactListCellDelegate> contactListTVC;
@property (nonatomic, weak) IBOutlet UIImageView *profilePicture;
@property (nonatomic, weak) IBOutlet UILabel *nicknameLabel;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UIButton *acceptContactRequestButton;
@property (nonatomic, weak) IBOutlet UIButton *declineContactRequestButton;

- (IBAction)acceptButtonAction;
- (IBAction)declineButtonAction;

@end
