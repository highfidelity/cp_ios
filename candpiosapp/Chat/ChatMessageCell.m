//
//  ChatMessageCell.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/29.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ChatMessageCell.h"

@implementation ChatMessageCell

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style
                reuseIdentifier:reuseIdentifier];
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
