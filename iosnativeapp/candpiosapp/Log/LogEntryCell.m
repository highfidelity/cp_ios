//
//  LogEntryCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LogEntryCell.h"

@implementation LogEntryCell

@synthesize typeImageView = _typeImage;
@synthesize entryLabel = _entryLabel;
@synthesize timeLabel = _timeLabel;
@synthesize dateLabel = _dateLabel;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
