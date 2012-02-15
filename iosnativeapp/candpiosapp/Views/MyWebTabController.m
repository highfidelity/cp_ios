//
//  MyWebTabController.m
//  candpiosapp
//
//  Created by David Mojdehi on 12/31/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import "MyWebTabController.h"

@implementation MyWebTabController
@synthesize webView;
@synthesize urlToLoad, urlRequestToLoad;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSLog(@"INIT");
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
        NSLog(@"INIT2");	
	//
	NSMutableURLRequest *request;
	if(urlToLoad)
	{
        NSLog(@"init3");
		request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: urlToLoad]];
	}
	else if (urlRequestToLoad)
	{
		request = urlRequestToLoad;
	}
	else
	{
		// load the default page
		NSURL *mobileUrl = [ NSURL URLWithString:@"http://www.coffeeandpower.com/m/"];
		request = [NSMutableURLRequest requestWithURL:mobileUrl];
	}
	[webView loadRequest:request];
}

- (void)viewDidUnload
{
	[self setWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSLog(@"webView shouldStartLoadWithRequest");
	return YES;
}
- (void)webViewDidStartLoad:(UIWebView *)webView
{
	NSLog(@"webViewDidStartLoad");
	
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	NSLog(@"webViewDidFinishLoad");
	
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	NSLog(@"didFailLoadWithError (%@)", [error localizedDescription]);
	
}

@end
