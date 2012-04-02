//
//  UserTableViewCell.m
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 1/15/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserTableViewCell.h"

@implementation UserTableViewCell

@synthesize nicknameLabel, categoryLabel, statusLabel, distanceLabel, checkInLabel, checkInCountLabel, profilePictureImageView;


- (NSString *) reuseIdentifier {
    return @"UserListCustomCell";
}

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
}

@end
