//
//  ContactListCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/18/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ContactListCell.h"

@implementation ContactListCell

@synthesize contactListTVC = _contactListTVC;
@synthesize acceptContactRequestButton;
@synthesize declineContactRequestButton;

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // we aren't swipeable (for now!)
    self.leftStyle = CPSwipeableTableViewCellSwipeStyleNone;
    self.rightStyle = CPSwipeableTableViewCellSwipeStyleNone;
    self.secretIcons = nil;
    
    // do anything here we need to do that differentiates us from the UserTableViewCell
    
    if (self.acceptContactRequestButton) {
        [self.acceptContactRequestButton addTarget:self
                                            action:@selector(acceptButtonAction)
                                  forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (self.declineContactRequestButton) {
        [self.declineContactRequestButton addTarget:self
                                             action:@selector(declineButtonAction)
                                   forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.contactListTVC = nil;
    self.acceptContactRequestButton.hidden = YES;
    self.declineContactRequestButton.hidden = YES;
}

- (void)acceptButtonAction {
    [self.contactListTVC clickedAcceptButtonInUserTableViewCell:self];
}

- (void)declineButtonAction {
    [self.contactListTVC clickedDeclineButtonInUserTableViewCell:self];
}

@end
