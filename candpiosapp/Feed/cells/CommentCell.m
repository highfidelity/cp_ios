//
//  CommentCell.m
//  candpiosapp
//
//  Created by Andrew Hammond on 7/26/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CommentCell.h"
#import "FeedViewController.h"
#import "CPVenue.h"
#import "CPAlertView.h"

#define kLeftCap 28
#define kRightCap 32
#define kPillFontSize 10

@implementation CommentCell

- (void) updatePillButtonAnimated:(BOOL)animated {
    // update pill button to the count specified in the post.. adding if needed
    [self addPillButton];
    NSTimeInterval animationDuration = 0.0;
    if (animated) {
        animationDuration = 0.5;
        CATransition *animation = [CATransition animation];
        animation.duration = 1.0;
        animation.type = kCATransitionFade;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [self.pillLabel.layer addAnimation:animation forKey:@"changeTextTransition"];
    } else {
        [self.pillLabel.layer removeAllAnimations];
    }
    
    [UIView animateWithDuration:animationDuration animations:^{
        UIImage *buttonImage = [UIImage imageNamed:@"pill-button-plus1-comment"];
        self.pillLabel.text = @"";
        if (self.post.likeCount > 0) {
            self.pillLabel.text = [NSString stringWithFormat:@"%i", self.post.likeCount];
        }
        // calculate the horizontal size of the button as buttonImage size + label size.. and center label vertically
        CGSize sizeConstraint = CGSizeMake(self.contentView.frame.size.width - self.pillLabel.frame.origin.x, buttonImage.size.height);
        CGSize labelSize = [self.pillLabel.text sizeWithFont:self.pillLabel.font
                                           constrainedToSize:sizeConstraint
                                               lineBreakMode:self.pillLabel.lineBreakMode];
        self.pillLabel.frame = CGRectMake(self.pillLabel.frame.origin.x,
                                          self.pillButton.frame.origin.y + (buttonImage.size.height - labelSize.height)/2,
                                          labelSize.width,
                                          labelSize.height);
        self.pillButton.frame = CGRectMake(self.pillButton.frame.origin.x,
                                           self.pillButton.frame.origin.y,
                                           buttonImage.size.width + labelSize.width,
                                           buttonImage.size.height);
    }];
    
}

- (void) addPillButton 
{
    // add the pill button if needed.. using a placeholder button from the storyboard for layout
    if (!self.pillButton) { 
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        UIImage *buttonImage = [UIImage imageNamed:@"pill-button-plus1-comment"];
        UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0, kLeftCap, 0, kRightCap);
        UIImage *stretchableImage = [buttonImage resizableImageWithCapInsets:edgeInsets];
        UIImage *buttonSelectedImage = [UIImage imageNamed:@"pill-button-plus1-comment-selected"];
        UIImage *stretchableSelectedImage = [buttonSelectedImage resizableImageWithCapInsets:edgeInsets];
        [button setBackgroundImage:stretchableImage forState:UIControlStateNormal];
        [button setBackgroundImage:stretchableSelectedImage forState:UIControlStateHighlighted];
        button.contentMode = UIViewContentModeCenter;
        button.frame = self.placeholderPillButton.frame;
        [self.placeholderPillButton removeFromSuperview];
        [button addTarget:self action:@selector(pillButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        self.pillButton = button;
        [self.contentView addSubview:button];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectOffset(button.frame, kLeftCap + 1, 0)];
        label.font = [UIFont boldSystemFontOfSize:kPillFontSize];
        label.textColor = [UIColor colorWithR:158 G:158 B:158 A:1.0];
        label.textAlignment = UITextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        self.pillLabel = label;
        [self.contentView insertSubview:label belowSubview:button];
    }        
}

- (void) pillButtonPressed:(id)sender 
{
    [self.delegate showPillPopoverFromCell:self];
}

@end
