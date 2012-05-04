//
//  AddFundsViewController.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 02.3.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "AddFundsViewController.h"

@interface AddFundsViewController ()

@end

@implementation AddFundsViewController
@synthesize webView, urlAddress, activityIndicator;

- (IBAction)goBack:(id)sender {
	[webView goBack];
}

- (IBAction)closeWindow:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

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
	// Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"Add Funds";
    
    urlAddress = kCandPAddFundsUrl;

    NSURL *url = [NSURL URLWithString:urlAddress];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
          
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	self.navigationItem.rightBarButtonItem = button;
	
	webView.delegate = self;
	[webView loadRequest:requestObj];
}

-(void)webViewDidFinishLoad:(UIWebView *) webView {
	[activityIndicator stopAnimating];
}

-(void)webViewDidStartLoad:(UIWebView *) webView {
	[activityIndicator startAnimating];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[self navigationController] popToRootViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
}

@end