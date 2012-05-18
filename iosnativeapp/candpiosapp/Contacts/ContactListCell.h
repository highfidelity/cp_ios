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

@protocol ContactListCellDelegate <NSObject>

- (void)clickedAcceptButtonInUserTableViewCell:(ContactListCell *)contactListCell;
- (void)clickedDeclineButtonInUserTableViewCell:(ContactListCell *)contactListCell;

@end

@interface ContactListCell : UserTableViewCell

@property (nonatomic, assign) id<ContactListCellDelegate> contactListTVC;
@property (nonatomic, retain) IBOutlet UIButton *acceptContactRequestButton;
@property (nonatomic, retain) IBOutlet UIButton *declineContactRequestButton;

@end
