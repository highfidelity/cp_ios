//
//  UserTableViewCell.m
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 1/15/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserTableViewCell.h"
#import "CPUIHelper.h"

@implementation UserTableViewCell

@synthesize delegate, nicknameLabel, categoryLabel, statusLabel, distanceLabel, checkInLabel, checkInCountLabel, profilePictureImageView, acceptContactRequestButton, declineContactRequestButton;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)awakeFromNib
{
    [self profilePictureImageView].layer.shadowColor = [UIColor blackColor].CGColor;
    [self profilePictureImageView].layer.shadowOffset = CGSizeMake(1, 1);
    [self profilePictureImageView].layer.shadowOpacity = 0.5;
    [self profilePictureImageView].layer.shadowRadius = 1.0;
    
    [CPUIHelper changeFontForLabel:self.nicknameLabel toLeagueGothicOfSize:24];
    
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

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.delegate = nil;
    self.acceptContactRequestButton.hidden = YES;
    self.declineContactRequestButton.hidden = YES;
}

#pragma mark - actions

- (void)acceptButtonAction {
    [self.delegate clickedAcceptButtonInUserTableViewCell:self];
}

- (void)declineButtonAction {
    [self.delegate clickedDeclineButtonInUserTableViewCell:self];
}

@end
