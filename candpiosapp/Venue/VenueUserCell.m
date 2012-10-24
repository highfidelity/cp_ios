//
//  VenueUserCell.m
//  candpiosapp
//
//  Created by Andrew Hammond on 8/20/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "VenueUserCell.h"

@implementation VenueUserCell
// synthesize required to hide parent properties
@synthesize separatorView;
@synthesize imageView;


- (void)awakeFromNib {
    [super awakeFromNib];
    
    // add a shadow to the imageview
    [CPUIHelper addShadowToView:self.imageView
                          color:[UIColor blackColor]
                         offset:CGSizeMake(1, 1)
                         radius:3 opacity:0.40];
    // spiffy font
    [CPUIHelper changeFontForLabel:self.nameLabel toLeagueGothicOfSize:18];

    // highlight appearance
    self.selectedBackgroundView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"highlight-gradient"]];
}

- (void) setUser:(CPUser *)user {
    _user = user;
    
    [CPUIHelper profileImageView:self.imageView
             withProfileImageUrl:user.photoURL];
    
    // update the labels
    self.nameLabel.text = self.user.nickname;
    self.titleLabel.text = self.user.jobTitle;
    // hours label managed by the controller
}

@end
