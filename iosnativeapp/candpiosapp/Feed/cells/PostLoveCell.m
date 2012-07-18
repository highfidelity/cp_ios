//
//  PostLoveCell.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/22/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "PostLoveCell.h"
#import "UIImage+Resize.h"

@implementation PostLoveCell

@synthesize receiverProfileButton = _receiverProfileButton;
@synthesize plusLoveButton;
@synthesize loveCountLabel;
@synthesize loveCountBubble;

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.receiverProfileButton setBackgroundImage:[CPUIHelper defaultProfileImage] forState:UIControlStateNormal];
}

- (void) addPlusWidget
{
    if (!self.plusLoveButton) { 
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *buttonImage = [UIImage imageNamed:@"plus-love-button"];
        [button setImage:buttonImage forState:UIControlStateNormal];
        button.frame = CGRectMake(self.contentView.frame.size.width - 2*buttonImage.size.width, 
                                  0,
                                  buttonImage.size.width, 
                                  buttonImage.size.height);
        button.layer.cornerRadius = 4.0f;
        button.layer.masksToBounds = YES;
        [button addTarget:self action:@selector(plusWidgetPressed:) forControlEvents:UIControlEventTouchUpInside];

        self.plusLoveButton = button;
        [self.contentView addSubview:button];
        
        UIImage *bubbleImage = [[UIImage imageNamed:@"love-bubble"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 9, 5, 9)];
        CGRect bubbleRect = button.frame;
        self.loveCountBubble = [[UIImageView alloc] initWithFrame:bubbleRect];
        self.loveCountBubble.image = bubbleImage;
        [self.contentView insertSubview:loveCountBubble belowSubview:button];

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(bubbleRect, 2.0f, 0.0f)];
        label.textColor = [UIColor grayColor];
        label.text = @"0";
        label.textAlignment = UITextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        label.adjustsFontSizeToFitWidth = YES;
        self.loveCountLabel = label;
        [self.contentView insertSubview:label belowSubview:button];
        
    }
}

- (void) changeLoveCountToValue:(int)value 
{
    // animates transitions of the label value
    // note: moving this up into the label layout code resulted in incorrect animation duration
    CATransition *animation = [CATransition animation];
    animation.duration = 1.0;
    animation.type = kCATransitionFade;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.loveCountLabel.layer addAnimation:animation forKey:@"changeTextTransition"];

    // reveals the bubble and label if necessary
    CGFloat labelFudgeX = -2.0;
    [UIView beginAnimations:@"love-bubble" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    self.loveCountBubble.frame = CGRectOffset(self.plusLoveButton.frame, -self.plusLoveButton.frame.size.width, 0); 
    self.loveCountLabel.frame = CGRectInset(CGRectOffset(self.plusLoveButton.frame, -self.plusLoveButton.frame.size.width +labelFudgeX, 0),
                                            4.0f, 0.0f);
    [self.loveCountLabel setAlpha:0];
    [self.loveCountLabel setText:[NSString stringWithFormat:@"%i", value]];
    [self.loveCountLabel setAlpha:1];
    [UIView commitAnimations];
}

- (void) plusWidgetPressed:(id)sender
{
    UIButton *button = (UIButton*)sender;
    PostBaseCell *cell = (PostBaseCell*)[[button superview] superview];
    button.enabled = NO;
    // TODO: Get value from the post
    [self changeLoveCountToValue:1];
    [CPapi sendPlusOneForLoveWithID:cell.post.postID completion:^(NSDictionary *json, NSError *error) {
        NSLog(@"Plus one JSON: %@", json);
        NSString *errorString = nil;
        if ([[json objectForKey:@"error"] boolValue]) {
            errorString = [json objectForKey:@"payload"];
        }
        if (error) {
            errorString = @"Network error while sending Love +1. Try again later.";
            NSLog(@"Error plussing love: %@", error);
        }
        if (errorString) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Love +1"
                                                                message:errorString
                                                               delegate:nil 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles:nil];
            [alertView show];
            button.enabled = YES;
            [self changeLoveCountToValue:0];
        }
    }];
}

@end
