//
//  LoveSkillTableViewCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/25/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LoveSkillTableViewCell.h"
#import "UserLoveViewController.h"

@implementation LoveSkillTableViewCell

- (void)setActive:(BOOL)active
{    
    UIImageView *leftIconIV = (UIImageView *)[self viewWithTag:ICON_IMAGE_VIEW_TAG];
    
    if (active || self.forceActive) {
        self.contentView.layer.backgroundColor = [CPUIHelper CPTealColor].CGColor;
        leftIconIV.alpha = 1.0;
    } else {
        self.contentView.layer.backgroundColor = [UIColor clearColor].CGColor;
        leftIconIV.alpha = 0.3;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self setActive:selected];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    [self setActive:highlighted];
}

@end
