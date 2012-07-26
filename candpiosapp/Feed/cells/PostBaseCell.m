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

        label.text = @"23";
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

- (void) addPlusWidget
{
    if (!self.plusButton) { 
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *buttonImage = [UIImage imageNamed:@"plus-love-button"];
        [button setImage:buttonImage forState:UIControlStateNormal];
        button.frame = CGRectMake(self.contentView.frame.size.width - 1.5*buttonImage.size.width, 
                                  0,
                                  buttonImage.size.width, 
                                  buttonImage.size.height);
        button.layer.cornerRadius = 4.0f;
        button.layer.masksToBounds = YES;
        [button addTarget:self action:@selector(plusWidgetPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        self.plusButton = button;
        [self.contentView addSubview:button];
        
        UIImage *bubbleImage = [[UIImage imageNamed:@"love-bubble"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 9, 5, 9)];
        CGRect bubbleRect = button.frame;
        self.likeCountBubble = [[UIImageView alloc] initWithFrame:bubbleRect];
        self.likeCountBubble.image = bubbleImage;
        [self.contentView insertSubview:likeCountBubble belowSubview:button];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(bubbleRect, 2.0f, 0.0f)];
        label.textColor = [UIColor grayColor];
        label.text = @"0";
        label.textAlignment = UITextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        label.adjustsFontSizeToFitWidth = YES;
        self.likeCountLabel = label;
        [self.contentView insertSubview:label belowSubview:button];
        
    }
}

- (void) changeLikeCountToValue:(int)value animated:(BOOL)animated
{
    // transitions of the label value, animated if desired
    if (animated) {
        CATransition *animation = [CATransition animation];
        animation.duration = 1.0;
        animation.type = kCATransitionFade;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [self.likeCountLabel.layer addAnimation:animation forKey:@"changeTextTransition"];
    } else {
        [self.likeCountLabel.layer removeAllAnimations];
    }
    // reveals the bubble and label if necessary
    if (animated) {
        [UIView beginAnimations:@"love-bubble" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    }
    if (value != 0) { 
        // to the left of the button
        CGFloat labelFudgeX = -2.0;
        self.likeCountBubble.frame = CGRectOffset(self.plusButton.frame, -self.plusButton.frame.size.width, 0); 
        self.likeCountLabel.frame = CGRectInset(CGRectOffset(self.plusButton.frame, -self.plusButton.frame.size.width +labelFudgeX, 0),
                                                4.0f, 0.0f);
    } else {
        // under the button
        self.likeCountBubble.frame = self.plusButton.frame;
        self.likeCountLabel.frame = self.plusButton.frame;
    }
    if (animated) {
        [self.likeCountLabel setAlpha:0];
    }
    // change the value
    [self.likeCountLabel setText:[NSString stringWithFormat:@"%i", value]];
    [self.likeCountLabel setAlpha:1];
    if (animated) { 
        [UIView commitAnimations];
    }
}

- (void) plusWidgetPressed:(id)sender
{
    // tell the server we like it!
    UIButton *button = (UIButton*)sender;
    PostBaseCell *cell = (PostBaseCell*)[[button superview] superview];
    button.enabled = NO;
    self.post.likeCount++;
    self.post.userHasLiked = YES;
    [self changeLikeCountToValue:self.post.likeCount animated:YES];
    [CPapi sendPlusOneForLoveWithID:cell.post.postID completion:^(NSDictionary *json, NSError *error) {
        NSString *errorString = nil;
        if ([[json objectForKey:@"error"] boolValue]) {
            errorString = [json objectForKey:@"payload"];
        }
        if (error) {
            errorString = @"Network error while sending +1. Try again later.";
            NSLog(@"Error plussing love: %@", error);
        }
        if (errorString) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"+1"
                                                                message:errorString
                                                               delegate:nil 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles:nil];
            [alertView show];
            button.enabled = YES;
            self.post.likeCount--;
            self.post.userHasLiked = NO;
            [self changeLikeCountToValue:self.post.likeCount animated:YES];
        }
    }];
}
- (void) pillButtonPressed:(id)sender 
{
    // forward on to the delegate to present the popover from the pill button
    if ([self.delegate respondsToSelector:@selector(showPillPopoverFromCell:)]) {
        [self.delegate performSelector:@selector(showPillPopoverFromCell:) withObject:self];
    }    
}

@end