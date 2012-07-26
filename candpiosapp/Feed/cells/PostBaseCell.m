//
//  PostBaseCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "PostBaseCell.h"
#import "FeedViewController.h"

@implementation PostBaseCell

@synthesize senderProfileButton = _senderProfileButton;
@synthesize entryLabel = _entryLabel;
@synthesize post;

@synthesize plusButton;
@synthesize pillButton;
@synthesize likeCountLabel;
@synthesize likeCountBubble;
@synthesize pillLabel;

- (void)awakeFromNib
{
    // grab a timeLine view using the class method in FeedViewController    
    // add the timeline to our contentView
    [super awakeFromNib];
    [self.contentView insertSubview:[FeedViewController timelineViewWithHeight:self.frame.size.height] atIndex:0];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.senderProfileButton setBackgroundImage:[CPUIHelper defaultProfileImage] forState:UIControlStateNormal];
}

- (void) addPillButton
{
    if (!self.pillButton) { 
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        UIImage *buttonImage = [UIImage imageNamed:@"pill-button-plus1-comment"];
        UIImage *stretchableImage = [buttonImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 18, 0, 21)];
        [button setBackgroundImage:stretchableImage forState:UIControlStateNormal];
        button.frame = CGRectMake(1.5*buttonImage.size.width, 
                                  10,
                                  buttonImage.size.width, 
                                  buttonImage.size.height);
        button.layer.cornerRadius = 4.0f;
        button.layer.masksToBounds = YES;
        [button addTarget:self action:@selector(pillButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        self.pillButton = button;
        [self.contentView addSubview:button];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectOffset(button.frame, 19.0f, 0.0f)];
        label.font = [UIFont fontWithName:label.font.fontName size:10];

        label.text = @"";
        label.textColor = [UIColor colorWithR:158 G:158 B:158 A:1.0];
        if (self.post.likeCount > 0) {
            label.text = [NSString stringWithFormat:@"%i", self.post.likeCount];
        }
        label.textAlignment = UITextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        CGSize sizeConstraint = CGSizeMake(self.contentView.frame.size.width - label.frame.origin.x, buttonImage.size.height);
        CGSize labelSize = [label.text sizeWithFont:label.font 
                                  constrainedToSize:sizeConstraint
                                      lineBreakMode:label.lineBreakMode];
        label.frame = CGRectMake(label.frame.origin.x, 
                                 label.frame.origin.y + (button.frame.size.height - labelSize.height)/2, 
                                 labelSize.width, 
                                 labelSize.height);
        button.frame = CGRectMake(button.frame.origin.x, 
                                  button.frame.origin.y, 
                                  button.frame.size.width + labelSize.width, 
                                  button.frame.size.height);
        self.pillLabel = label;
        [self.contentView insertSubview:label belowSubview:button];
        
    }    
}

- (void) pillButtonPressed:(id)sender 
{
    // forward on to the delegate to present the popover from the pill button
    if ([self.delegate respondsToSelector:@selector(showPillPopoverFromCell:)]) {
        [self.delegate performSelector:@selector(showPillPopoverFromCell:) withObject:self];
    }    
}

@end