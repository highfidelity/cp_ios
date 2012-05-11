//
//  CheckinChatCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CheckinChatCell.h"

@implementation CheckinChatCell

+ (UIFont *)chatEntryFont
{
    return [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // bold the entry font and change the color
        self.chatEntry.font = [[self class] chatEntryFont];
        self.chatEntry.textColor = [UIColor colorWithRed:(100.0/255.0) green:(100.0/255.0) blue:(100.0/255.0) alpha:1.0];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
