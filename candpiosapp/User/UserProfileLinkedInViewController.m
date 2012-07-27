//
//  UserProfileLinkedInViewController.m
//  candpiosapp
//
//  Created by Bryan Galusha on 5/8/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserProfileLinkedInViewController.h"

@implementation UserProfileLinkedInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.socialWebView.delegate = self;
    self.socialWebView.hidden = YES;
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    //Create a URL object.
    NSURL *url = [NSURL URLWithString:self.linkedInProfileUrlAddress];
    
    //URL Requst Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    
    //Load the request in the UIWebView.
    [self.socialWebView loadRequest:requestObj]; 
}

#pragma mark - UIWebViewDelegate


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.socialWebView.hidden = NO;
    [SVProgressHUD dismiss];
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [SVProgressHUD dismissWithError:[error localizedDescription]
                         afterDelay:kDefaultDismissDelay];
}

@end
