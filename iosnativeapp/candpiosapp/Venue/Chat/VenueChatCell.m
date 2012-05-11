//
//  VenueChatCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 4/18/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "VenueChatCell.h"

@implementation VenueChatCell

@synthesize userThumbnail = _userThumbnail;
@synthesize chatEntry = _chatEntry;

+ (CGRect)chatEntryFrame
{
    return CGRectMake(46, 9, 266, 16);
}

+ (UIFont *)chatEntryFont
{
    return [UIFont fontWithName:@"HelveticaNeue" size:15.0];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // add the chatEntry Label
        self.chatEntry = [[UILabel alloc] initWithFrame:[VenueChatCell chatEntryFrame]];
        self.chatEntry.font = [VenueChatCell chatEntryFont];
        self.chatEntry.numberOfLines = 0;
        self.chatEntry.lineBreakMode = UILineBreakModeWordWrap;
        self.chatEntry.textColor = [UIColor colorWithRed:(51.0/255.0) green:(51.0/255.0) blue:(51.0/255.0) alpha:1.0];
        [self addSubview:self.chatEntry];
        
        // add the button for the user image
        self.userThumbnail = [[UIButton alloc] initWithFrame:CGRectMake(8, 6, 30, 30)];
        [self.userThumbnail setBackgroundImage:[CPUIHelper defaultProfileImage] forState:UIControlStateNormal];
        [self addSubview:self.userThumbnail];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
