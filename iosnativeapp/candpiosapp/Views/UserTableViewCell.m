//
//  UserTableViewCell.m
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 1/15/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserTableViewCell.h"

@implementation UserTableViewCell

@synthesize nicknameLabel, statusLabel, distanceLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        // List entry should show profile image, nickname, skills and distance from end user.

        nicknameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [nicknameLabel setFont:[UIFont boldSystemFontOfSize:14.0]];
        [nicknameLabel setTextColor:[UIColor blackColor]];
        [nicknameLabel setHighlightedTextColor:[UIColor whiteColor]];
        nicknameLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:nicknameLabel];

        statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [statusLabel setFont:[UIFont systemFontOfSize:12.0]];
        [statusLabel setTextColor:[UIColor darkGrayColor]];
        [statusLabel setHighlightedTextColor:[UIColor whiteColor]];
        statusLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:statusLabel];

        distanceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [distanceLabel setFont:[UIFont systemFontOfSize:12.0]];
        [distanceLabel setTextColor:[UIColor darkGrayColor]];
        [distanceLabel setHighlightedTextColor:[UIColor whiteColor]];
        distanceLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:distanceLabel];
        
    }
    
    return self;
}

- (NSString *) reuseIdentifier {
    return @"myIdentifier";
}

- (void)layoutSubviews {
    [super layoutSubviews];
	
    [nicknameLabel setFrame:CGRectMake(65, 0, 230, 20)];
    [statusLabel setFrame:CGRectMake(65, 20, 230, 20)];
    [distanceLabel setFrame:CGRectMake(65, 40, 230, 20)];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
