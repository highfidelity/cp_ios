//
//  LogCreateViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LogCreateViewController.h"

@interface LogCreateViewController () <UITextViewDelegate>

@end

@implementation LogCreateViewController
@synthesize profileImageView = _profileImageView;
@synthesize logTextView = _logTextView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // be the delegate of the CPPlaceHolderTextView
    self.logTextView.delegate = self;
    
    // make sure the keyboard is showing when the view loads
    [self.logTextView becomeFirstResponder];
    
    [self.profileImageView setImageWithURL:[CPAppDelegate currentUser].photoURL placeholderImage:[CPUIHelper defaultProfileImage]];
}

- (void)viewDidUnload
{
    [self setProfileImageView:nil];
    [self setLogTextView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

#pragma mark - Helper Methods

- (void)sendLog
{
    // show a progress HUD
    [SVProgressHUD showWithStatus:@"Sending..."];
    
    // send the log
    [CPapi sendLogUpdate:self.logTextView.text completion:^(NSDictionary *json, NSError *error) {
        if (!error) {
            // make sure we didn't get an error back from the API
            if (![[json objectForKey:@"error"] boolValue]) {
                // no error, hide the progress HUD and then the modal
                [SVProgressHUD dismiss];
                [self dismissViewControllerAnimated:YES completion:^{
                    [SVProgressHUD showSuccessWithStatus:@"Update sent!" duration:kDefaultDimissDelay];
                }];
            
            } else {
                [SVProgressHUD dismissWithError:[json objectForKey:@"payload"] afterDelay:kDefaultDimissDelay];
            }
        } else {
            // show the error returned by AFNetworking
            [SVProgressHUD dismissWithError:[error localizedDescription] afterDelay:kDefaultDimissDelay];
        }
    }];
}

#pragma mark - IBActions

- (IBAction)cancelButtonPressed:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (range.length == 1 && [text isEqualToString:@""]) {
        return YES;
    } else if ([text isEqualToString:@"\n"]) {
        // if there's any review text here then send it
        if (textView.text.length > 0) {
            [self sendLog];
        }
        return NO;
    }
    return YES;
}

@end
