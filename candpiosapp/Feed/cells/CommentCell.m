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

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
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

- (void) updatePillButtonAnimated:(BOOL)animated {
    if (animated) {
        CATransition *animation = [CATransition animation];
        animation.duration = 1.0;
        animation.type = kCATransitionFade;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [self.pillLabel.layer addAnimation:animation forKey:@"changeTextTransition"];
        [UIView beginAnimations:@"pill-size-change" context:nil];
    } else {
        [self.pillLabel.layer removeAllAnimations];
    }
    UIImage *buttonImage = [UIImage imageNamed:@"pill-button-plus1-comment"];
    self.pillLabel.text = @"";
    if (self.post.likeCount > 0) {
        self.pillLabel.text = [NSString stringWithFormat:@"%i", self.post.likeCount];
    }
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
    if (animated) {
        [UIView commitAnimations];
    }
}

- (void) updatePillButton
{
    if (!self.pillButton) { 
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        UIImage *buttonImage = [UIImage imageNamed:@"pill-button-plus1-comment"];
        UIImage *stretchableImage = [buttonImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 18, 0, 21)];
        [button setBackgroundImage:stretchableImage forState:UIControlStateNormal];
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


//        label.text = @"";
//        if (self.post.likeCount > 0) {
//            label.text = [NSString stringWithFormat:@"%i", self.post.likeCount];
//        }
//        CGSize sizeConstraint = CGSizeMake(self.contentView.frame.size.width - label.frame.origin.x, buttonImage.size.height);
//        CGSize labelSize = [label.text sizeWithFont:label.font 
//                                  constrainedToSize:sizeConstraint
//                                      lineBreakMode:label.lineBreakMode];
//        label.frame = CGRectMake(label.frame.origin.x, 
//                                 label.frame.origin.y + (button.frame.size.height - labelSize.height)/2, 
//                                 labelSize.width, 
//                                 labelSize.height);
//        button.frame = CGRectMake(button.frame.origin.x, 
//                                  button.frame.origin.y, 
//                                  button.frame.size.width + labelSize.width, 
//                                  button.frame.size.height);
        
    }    
    [self updatePillButtonAnimated:NO];
}

- (void) pillButtonPressed:(id)sender 
{
    // forward on to the delegate to present the popover from the pill button
    if ([self.delegate respondsToSelector:@selector(showPillPopoverFromCell:)]) {
        [self.delegate performSelector:@selector(showPillPopoverFromCell:) withObject:self];
    }    
}

@end
