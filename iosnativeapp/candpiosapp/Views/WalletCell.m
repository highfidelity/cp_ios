//
//  WalletCell.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 05.3.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "WalletCell.h"

@implementation WalletCell
@synthesize profileImage = _profileImage;
@synthesize dateLabel = _dateLabel;
@synthesize stateImage = _stateImage;
@synthesize amountLabel = _amountLabel;
@synthesize descriptionLabel = _descriptionLabel;
@synthesize nicknameLabel = _nicknameLabel;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
}


@end
