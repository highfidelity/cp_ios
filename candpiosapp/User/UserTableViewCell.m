//
//  UserTableViewCell.m
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 1/15/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserTableViewCell.h"
#import "CPUIHelper.h"

@implementation UserTableViewCell 

- (void)awakeFromNib
{
    // call super's awakeFromNib so that this cell can be swipeable
    [super awakeFromNib];
    
    self.contentView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    
    [CPUIHelper addShadowToView:self.profilePictureImageView color:[UIColor blackColor] offset:CGSizeMake(1, 1) radius:0.5 opacity:1.0];
    
    [CPUIHelper changeFontForLabel:self.nicknameLabel toLeagueGothicOfSize:24];   
}

#pragma mark - CPUserActionCell

- (void)additionalHighlightAnimations:(BOOL)highlight
{
    self.endorseCountLabel.highlighted = highlight;
    self.hoursWorkedLabel.highlighted = highlight;
    self.hoursWorkedUnitLabel.highlighted = highlight;
    self.categoryLabel.highlighted = highlight;
    self.checkInLabel.highlighted = highlight;

    CGFloat newAlpha = highlight ? 0.1 : 1;
    self.endorseCountUnderlineView.alpha = newAlpha;
    self.hoursWorkedUnderlineView.alpha = newAlpha;
}

@end
