//
//  CommentCell.m
//  candpiosapp
//
//  Created by Andrew Hammond on 7/26/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CommentCell.h"

@implementation CommentCell
@synthesize post;
@synthesize pillLabel;
@synthesize pillButton;
@synthesize placeholderPillButton;
@synthesize delegate;

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
        UIImage *stretchableImage = [buttonImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 18, 0, 21)];
        UIImage *buttonSelectedImage = [UIImage imageNamed:@"pill-button-plus1-comment-selected"];
        UIImage *stretchableSelectedImage = [buttonSelectedImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 18, 0, 21)];
        [button setBackgroundImage:stretchableImage forState:UIControlStateNormal];
        [button setBackgroundImage:stretchableSelectedImage forState:UIControlStateHighlighted];
        button.frame = CGRectMake(self.placeholderPillButton.frame.origin.x, 
                                  self.placeholderPillButton.frame.origin.y,
                                  buttonImage.size.width, 
                                  buttonImage.size.height);
        [self.placeholderPillButton removeFromSuperview];
        button.layer.cornerRadius = 4.0f;
        button.layer.masksToBounds = YES;
        [button addTarget:self action:@selector(pillButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        self.pillButton = button;
        [self.contentView addSubview:button];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectOffset(button.frame, 19.0f, 0.0f)];
        label.font = [UIFont fontWithName:label.font.fontName size:10];
        label.textColor = [UIColor colorWithR:158 G:158 B:158 A:1.0];
        label.textAlignment = UITextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        self.pillLabel = label;
        [self.contentView insertSubview:label belowSubview:button];
    }        
}

- (void) pillButtonPressed:(id)sender 
{
    // forward on to the delegate to present the popover from the pill button
    [self.delegate showPillPopoverFromCell:self];
}

@end
