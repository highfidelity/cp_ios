//
//  PillPopoverViewController.m
//  candpiosapp
//
//  Created by Andrew Hammond on 7/25/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "PillPopoverViewController.h"

@interface PillPopoverViewController ()

@end

@implementation PillPopoverViewController
@synthesize plusButton;
@synthesize plusWebView;
@synthesize commentButton;
@synthesize commentLabel;
@synthesize commentTextView;
@synthesize commentImageView;
@synthesize post;
@synthesize delegate;
@synthesize indexPath;

- (void) updatePlusWebViewAnimated:(BOOL)animated
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
    if (post.likeCount == 0) {
        headContent = @"no one";
        tailContent = @"has +1'd this";
    } else if (post.likeCount == 1) {
        headContent = @"one person";
        tailContent = @"has +1'd this";
    } else {
        headContent = [NSString stringWithFormat:@"%i people", post.likeCount];
        tailContent = @"have +1'd this";
    }
    NSString *content = [NSString stringWithFormat:@"<font style=\"color: #00645F;\">%@</font> %@", headContent, tailContent];
    NSString *htmlString = [NSString stringWithFormat:@"<html> \n"
                            "<head> \n"
                            "<style type=\"text/css\"> \n"
                            "body {font-family: \"%@\"; font-size: %i;}\n"
                            "</style> \n"
                            "</head> \n"
                            "<body>%@</body> \n"
                            "</html>", @"helvetica", 12, content];
    [self.plusWebView loadHTMLString:htmlString 
                             baseURL:nil];
        
}

- (void) pulseImages 
{
    // pulse the images to 120% size and back
    float flex = 0.2;
    CGFloat commentWidthFlex = self.commentImageView.frame.size.width * flex;
    CGFloat commentHeightFlex = self.commentImageView.frame.size.height * flex;
    CGFloat plusWidthFlex = self.plusButton.frame.size.width * flex;
    CGFloat plusHeightFlex = self.plusButton.frame.size.height * flex;
    float deltaT = 0.75 / 2;
    [UIView animateWithDuration:deltaT
                     animations:^{ 
                         self.commentImageView.frame = CGRectInset(self.commentImageView.frame, 
                                                                   -commentWidthFlex, 
                                                                   -commentHeightFlex);
                         if (self.plusButton.enabled) {
                             self.plusButton.frame = CGRectInset(self.plusButton.frame, 
                                                                 -plusWidthFlex,
                                                                 -plusHeightFlex);
                         }
                     } 
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:deltaT
                                          animations:^{ 
                                              self.commentImageView.frame = CGRectInset(self.commentImageView.frame, 
                                                                                        commentWidthFlex, 
                                                                                        commentHeightFlex);
                                              if (self.plusButton.enabled) {
                                                  self.plusButton.frame = CGRectInset(self.plusButton.frame, 
                                                                                      plusWidthFlex,
                                                                                      plusHeightFlex);
                                              }
                                          } 
                                          completion:nil
                          ];
                         
                     }];    
    
}

- (void) viewDidAppear:(BOOL)animated
{
    // set +1 enabled state
    self.plusButton.enabled = !(self.post.userHasLiked || [CPUserDefaultsHandler currentUser].userID == self.post.author.userID);
    
    // update the plus count label
    [self updatePlusWebViewAnimated:animated];
    
    // animate the images
    [self pulseImages];
    
    // setup the textfield
    self.commentTextView.delegate = self;
}

- (void)viewDidUnload
{
    [self setPlusButton:nil];
    [self setCommentButton:nil];
    [self setCommentLabel:nil];
    [self setCommentTextView:nil];
    [self setCommentImageView:nil];
    [self setPlusWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
