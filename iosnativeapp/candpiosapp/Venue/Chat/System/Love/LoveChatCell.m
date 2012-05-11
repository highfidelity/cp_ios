//
//  LoveChatCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/9/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LoveChatCell.h"

@implementation LoveChatCell
@synthesize recipientThumbnail = _recipientThumbnail;

+ (CGRect)chatEntryFrame
{
    return CGRectMake(111, 6, 125, 16);
}

+ (UIFont *)chatEntryFont
{
    return [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        // thumbnail button for sender is taken care of by VenueChatCell superclass
        
        // icon for love
        UIImageView *sentLoveIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"love-sent"]];
        
        // change the frame for the love icon
        CGRect loveIconFrame = sentLoveIcon.frame;
        loveIconFrame.origin.x = self.userThumbnail.frame.origin.x + self.userThumbnail.frame.size.width + 5;
        loveIconFrame.origin.y = self.userThumbnail.frame.origin.y + ((self.userThumbnail.frame.size.height / 2) - (loveIconFrame.size.height / 2));
        sentLoveIcon.frame = loveIconFrame;
        
        // add it to the cell
        [self addSubview:sentLoveIcon];
        
        // thumbnail button for lovee
        double rcpOriginY = sentLoveIcon.frame.origin.x + sentLoveIcon.frame.size.width + 3;
        self.recipientThumbnail = [[UIButton alloc] initWithFrame:CGRectMake(rcpOriginY, 6, 30, 30)];
        
        // background is default profile image
        [self.recipientThumbnail setBackgroundImage:[CPUIHelper defaultProfileImage] forState:UIControlStateNormal];
        
        // add it to the cell
        [self addSubview:self.recipientThumbnail];
        
        // change some properties on chatEntry property (inherited from superclass VenueChatCell)
        self.chatEntry.font = [[self class] chatEntryFont];
        self.chatEntry.frame = [[self class] chatEntryFrame];
    
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
