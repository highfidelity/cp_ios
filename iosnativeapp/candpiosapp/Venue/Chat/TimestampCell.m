//
//  TimestampCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 4/27/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "TimestampCell.h"

@implementation TimestampCell

@synthesize timestampLabel = _timestampLabel;

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

    // Configure the view for the selected state
}

@end
