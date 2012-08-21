//
//  PillPopoverViewController.m
//  candpiosapp
//
//  Created by Andrew Hammond on 7/25/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "PillPopoverViewController.h"

@interface PillPopoverViewController ()
@property (nonatomic) BOOL currentlyAnimating;

@end

@implementation PillPopoverViewController

- (void)updatePlusWebViewAnimated:(BOOL)animated
{
    // transitions of the label value, animated if desired
    if (animated) {
        CATransition *animation = [CATransition animation];
        animation.duration = 1.0;
        animation.type = kCATransitionFade;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [self.plusWebView.layer addAnimation:animation forKey:@"changeTextTransition"];
    } else {
        [self.plusWebView.layer removeAllAnimations];
    }
    
    // set the +1 recognition label
    NSString *headContent;
    NSString *tailContent;
    if (self.post.likeCount == 0) {
        headContent = @"no one";
        tailContent = @"has +1'd this";
    } else if (self.post.likeCount == 1) {
        headContent = @"one person";
        tailContent = @"has +1'd this";
    } else {
        headContent = [NSString stringWithFormat:@"%i people", self.post.likeCount];
        tailContent = @"have +1'd this";
    }
    NSString *content = [NSString stringWithFormat:@"<font style=\"color: #00645F;\">%@</font> %@", headContent, tailContent];
    NSString *htmlString = [NSString stringWithFormat:@"<html> \n"
                            "<head> \n"
                            "<style type=\"text/css\"> \n"
                            "body {font-family: \"%@\"; font-size: %i; color: #333333; }\n"
                            "</style> \n"
                            "</head> \n"
                            "<body>%@</body> \n"
                            "</html>", @"helvetica", 12, content];
    [self.plusWebView loadHTMLString:htmlString 
                             baseURL:nil];
        
}

- (void)imageFlex:(float)flex commentRect:(CGRect)commentRect
{
    CGFloat commentWidthFlex = commentRect.size.width * flex;
    CGFloat commentHeightFlex = commentRect.size.height * flex;
    
    // set the image sizes
    self.commentImageView.frame = CGRectInset(self.commentImageView.frame,
                                              commentWidthFlex,
                                              commentHeightFlex);
}

- (void)imageFlex:(float)flex plusRect:(CGRect)plusRect
{
    CGFloat plusWidthFlex = plusRect.size.width * flex;
    CGFloat plusHeightFlex = plusRect.size.height * flex;
    
    // set the image sizes
    if (self.plusButton.enabled) {
        self.plusButton.frame = CGRectInset(self.plusButton.frame,
                                            plusWidthFlex,
                                            plusHeightFlex);
    }
}


- (void)dribbleImages
{
    // pulse the images like a ball bouncing to rest on the floor
    if (self.currentlyAnimating) {
        return;
    }
    self.currentlyAnimating = YES;
    
    CGRect plusRect = self.plusButton.frame;
    
    float flex1 = 0.4;
    float flex2 = 0.2;
    float flex3 = 0.1;
    float deltaT = 0.35 / 6;
    
    // first dribble the +1 image if enabled.. chaining to a comment image dribble
    if (self.plusButton.enabled) {
        [UIView animateWithDuration:deltaT
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{[self imageFlex:-flex1 plusRect:plusRect];}
                         completion:
         ^(BOOL finished) {
             [UIView animateWithDuration:deltaT
                                   delay:0
                                 options:UIViewAnimationOptionCurveEaseIn
                              animations:^{[self imageFlex:flex1 plusRect:plusRect];}
                              completion:
              ^(BOOL finished) {
                  [UIView animateWithDuration:deltaT*0.8
                                        delay:0
                                      options:UIViewAnimationOptionCurveEaseIn
                                   animations:^{[self imageFlex:-flex2 plusRect:plusRect];}
                                   completion:
                   ^(BOOL finished) {
                       [UIView animateWithDuration:deltaT*0.8
                                             delay:0
                                           options:UIViewAnimationOptionCurveEaseIn
                                        animations:^{[self imageFlex:flex2 plusRect:plusRect];}
                                        completion:
                        ^(BOOL finished) {
                            [self dribbleCommentImageWithDelay:0];
                            [UIView animateWithDuration:deltaT*0.6
                                                  delay:0
                                                options:UIViewAnimationOptionCurveEaseIn
                                             animations:^{[self imageFlex:-flex3 plusRect:plusRect];}
                                             completion:
                             ^(BOOL finished) {
                                 [UIView animateWithDuration:deltaT*0.6
                                                       delay:0
                                                     options:UIViewAnimationOptionCurveEaseIn
                                                  animations:^{[self imageFlex:flex3 plusRect:plusRect];}
                                                  completion:nil
                                  ];
                             }];
                        }];
                   }];
              }];
         }];
    } else {
        // pause for the disabled +1
        [self dribbleCommentImageWithDelay:4*deltaT];
    }
}
- (void)dribbleCommentImageWithDelay:(NSTimeInterval)delay
{
    // dribble the image, losing some amplitude on each bounce
    CGRect commentRect = self.commentImageView.frame;
    
    float flex1 = 0.4;
    float flex2 = 0.2;
    float flex3 = 0.1;
    float deltaT = 0.35 / 6;
    
    [UIView animateWithDuration:deltaT
                          delay:delay
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{[self imageFlex:-flex1 commentRect:commentRect];}
                     completion:
     ^(BOOL finished) {
         [UIView animateWithDuration:deltaT
                               delay:0
                             options:UIViewAnimationOptionCurveEaseIn
                          animations:^{[self imageFlex:flex1 commentRect:commentRect];}
                          completion:
          ^(BOOL finished) {
              [UIView animateWithDuration:deltaT*0.8
                                    delay:0
                                  options:UIViewAnimationOptionCurveEaseIn
                               animations:^{[self imageFlex:-flex2 commentRect:commentRect];}
                               completion:
               ^(BOOL finished) {
                   [UIView animateWithDuration:deltaT*0.8
                                         delay:0
                                       options:UIViewAnimationOptionCurveEaseIn
                                    animations:^{[self imageFlex:flex2 commentRect:commentRect];}
                                    completion:
                    ^(BOOL finished) {
                        [UIView animateWithDuration:deltaT*0.6
                                              delay:0
                                            options:UIViewAnimationOptionCurveEaseIn
                                         animations:^{[self imageFlex:-flex3 commentRect:commentRect];}
                                         completion:
                         ^(BOOL finished) {
                             [UIView animateWithDuration:deltaT*0.6
                                                   delay:0
                                                 options:UIViewAnimationOptionCurveEaseIn
                                              animations:^{[self imageFlex:flex3 commentRect:commentRect];}
                                              completion:^(BOOL finished) {self.currentlyAnimating = NO;}
                              ];
                         }];
                    }];
               }];
          }];
     }];
}

- (void)viewDidAppear:(BOOL)animated
{
    // set +1 enabled state
    self.plusButton.enabled = !(self.post.userHasLiked || [CPUserDefaultsHandler currentUser].userID == self.post.author.userID);
    
    // update the plus count label
    [self updatePlusWebViewAnimated:NO];
    
    // animate the images
    [self dribbleImages];
    
    // setup the textfield
    self.commentTextView.delegate = self;
}

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField
{
    // push view here to handle comment input
    [self.delegate pillPopover:self commentPressedForIndexPath:self.indexPath];
    
    return NO;
}

- (IBAction)plusButtonPressed:(id)sender {
    // tell the server we like it!
    UIButton *button = (UIButton*)sender;
    button.enabled = NO;
    self.post.likeCount++;
    self.post.userHasLiked = YES;
    [CPapi sendPlusOneForLoveWithID:self.post.postID completion:^(NSDictionary *json, NSError *error) {
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
        } else {
            // success
            [self.delegate pillPopover:self plusOnePressedForIndexPath:self.indexPath];
        }
    }];
    
}
@end
