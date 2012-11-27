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
@synthesize user = _user;


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

    UIView *clippingContainerView = [[UIView alloc] initWithFrame:CGRectInset(self.hiddenView.frame, 11, 0)];
    self.hiddenView.frame = clippingContainerView.bounds;
    clippingContainerView.clipsToBounds = YES;
    clippingContainerView.opaque = NO;
    clippingContainerView.backgroundColor = [UIColor clearColor];

    [self addSubview:clippingContainerView];
    [clippingContainerView addSubview:self.hiddenView];
    [clippingContainerView addSubview:self.contentView];
    self.visibleView.frame = CGRectOffset(self.visibleView.frame, -10, 0);

    [self addSubview:[self verticalLineViewAtX:10
                                        height:self.frame.size.height]];
    [self addSubview:[self verticalLineViewAtX:self.frame.size.width - 11
                                        height:self.frame.size.height]];

    self.inactiveColor = [UIColor colorWithWhite:237./255 alpha:1];
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

#pragma mark - CPUserActionCell

- (UIView *)viewToHighlight {
    return self.visibleView;
}

#pragma mark - private

- (UIView *)verticalLineViewAtX:(CGFloat)x height:(CGFloat)height
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(x, 0, 1, height)];
    view.backgroundColor = [UIColor colorWithWhite:198./255 alpha:1];
    return view;
}

@end
