//
//  UserTableViewCell.m
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 1/15/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserTableViewCell.h"

@implementation UserTableViewCell

@synthesize nicknameLabel, statusLabel, distanceLabel, checkInLabel, checkInCountLabel, profilePictureImageView;


- (NSString *) reuseIdentifier {
    return @"UserListCustomCell";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
