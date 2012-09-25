//
//  TermsOfServiceViewController.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 5/22/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "TermsOfServiceViewController.h"
#import "AFHTTPRequestOperation.h"
#import "GRMustache.h"

@interface TermsOfServiceViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation TermsOfServiceViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    NSURL *termsURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@terms.php", kCandPWebServiceUrl]];
    NSURLRequest *request = [NSURLRequest requestWithURL:termsURL];
    AFHTTPRequestOperation *httpRequestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [httpRequestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *responseData = responseObject;
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        
        GRMustacheTemplate *template = [GRMustacheTemplate templateFromResource:@"TermsOfService"
                                                                         bundle:nil
                                                                          error:NULL];
        
        NSString *fullHTML = [template renderObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     responseString, @"terms",
                                                     nil]];
        
        [self.webView loadHTMLString:fullHTML baseURL:termsURL];
        
        [SVProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD dismissWithError:[error description] afterDelay:kDefaultDismissDelay];
    }];
    
    [[NSOperationQueue mainQueue] addOperation:httpRequestOperation];
}

- (IBAction)dismissTermsOfService:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

@end
