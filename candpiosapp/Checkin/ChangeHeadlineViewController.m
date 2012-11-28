//
//  ChangeHeadlineViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 10/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ChangeHeadlineViewController.h"
#import "CPPlaceholderTextView.h"

#define HEADLINE_CHAR_LIMIT 140

@interface ChangeHeadlineViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet CPPlaceholderTextView *headlineTextView;
@property (weak, nonatomic) IBOutlet UILabel *charCounterLabel;

@end

@implementation ChangeHeadlineViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // show the keyboard on load
    [self.headlineTextView becomeFirstResponder];
    
    // be the delegate of the text view
    self.headlineTextView.delegate = self;
    
    // set the placeholder on our CPPlaceHolderTextView
    self.headlineTextView.placeholder = @"Type your new headline here...";
    self.headlineTextView.placeholderColor = [UIColor colorWithR:153 G:153 B:153 A:1];
}

-(IBAction)cancelButtonPressed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)sendHeadlineChange
{
    [SVProgressHUD showWithStatus:@"Changing..."];
    
    [CPapi changeHeadlineToNewHeadline:self.headlineTextView.text completion:^(NSDictionary *json, NSError *error) {
        if (!error && ![[json objectForKey:@"error"] boolValue]) {
            [SVProgressHUD dismiss];
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            NSString *errorString = error ? [error localizedDescription] : [json objectForKey:@"message"];
            [SVProgressHUD dismissWithError:errorString afterDelay:kDefaultDismissDelay];
        }
    }];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (range.length == 1 && [text isEqualToString:@""]) {
        return YES;
    } else if ([text isEqualToString:@"\n"]) {
        // if there's any review text here then send it
        if (textView.text.length > 0) {
            [self sendHeadlineChange];
        }
        return NO;
    } else if (textView.text.length > (HEADLINE_CHAR_LIMIT - 1)) {
        return NO;
    }
    return YES;
}

-(void)textViewDidChange:(UITextView *)textView
{
    self.charCounterLabel.text = [NSString stringWithFormat:@"%d", HEADLINE_CHAR_LIMIT - textView.text.length];
}


@end
