//
//  ContactListCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/18/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ContactListCell.h"

@interface ContactListCell ()

- (void)fixCellIsNotFullWidthDueToTableViewSectionIndexes;

@end

@implementation ContactListCell

- (void)awakeFromNib
{
    [super awakeFromNib];

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

- (void)layoutSubviews {
    [super layoutSubviews];
    [self fixCellIsNotFullWidthDueToTableViewSectionIndexes];
}

#pragma mark - UITableViewCell

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.contactListTVC = nil;
    self.acceptContactRequestButton.hidden = YES;
    self.declineContactRequestButton.hidden = YES;
}

- (IBAction)acceptButtonAction {
    [self.contactListTVC clickedAcceptButtonInUserTableViewCell:self];
}

- (IBAction)declineButtonAction {
    [self.contactListTVC clickedDeclineButtonInUserTableViewCell:self];
}

#pragma mark - private

- (void)fixCellIsNotFullWidthDueToTableViewSectionIndexes {
    CGRect frame = self.contentView.frame;
    frame.size.width = self.frame.size.width;
    self.contentView.frame = frame;
    self.hiddenView.frame = frame;
}

@end
