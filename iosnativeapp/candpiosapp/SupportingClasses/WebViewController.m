//
//  WebViewController.m
//  WebViewTutorial
//
//  Created by iPhone SDK Articles on 8/19/08.
//  Copyright 2008 www.iPhoneSDKArticles.com. All rights reserved.
//

#import "WebViewController.h"


@implementation WebViewController

@synthesize webView, urlAddress, modalTitle, navItem, venueName, activityIndicator;

- (IBAction)goBack:(id)sender {
	[webView goBack];
}

- (IBAction)buttonPressed:(id)sender
{
//	[webView goBack];
	NSLog(@"trying to close modal web view..");

	// Both seem to work to hide the modal view :)
//	[[self parentViewController] dismissModalViewControllerAnimated:YES];
	[self dismissModalViewControllerAnimated:YES]; // or NO depending on what you want
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */

/*
 If you need to do additional setup after loading the view, override viewDidLoad. */
- (void)viewDidLoad {

	if (urlAddress == nil) {
		urlAddress = @"https://sled.com/oauth/authorize?client_id=marker.v1&response_type=token";
//		urlAddress = @"sled://token#access_token=akjsdhkajshd&mac_algorithm=hmac-sha-256&mac_key=asdaksjdkajh";
	}
	
//	self.navigationItem.titleView = [[UIImageView alloc] initWithImage: [UIImage imageNamed:@"title_bar.png"]];

	navItem.title = @"Sled Login";

//	[self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque]; 

	// Spinner..

    [self.navigationController setNavigationBarHidden:YES animated:YES];

    
	 
//		 [indicator stopAnimating];
		
	//	[indicator stopAnimating];
	//	[indicator release];
	
	//Create a URL object.
	NSURL *url = [NSURL URLWithString:urlAddress];
	
	//URL Requst Object
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];

	//Load the request in the UIWebView.

//	CGRect bounds = [ [ UIScreen mainScreen ] applicationFrame ];
	
	activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
//	self.view = activityIndicator;

	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	self.navItem.rightBarButtonItem = button;
	
//	[navItem setBarStyle:UIBarStyleBlackOpaque];
	
//	webView = [ [ UIWebView alloc ] initWithFrame:bounds];

	webView.delegate = self;
	[webView loadRequest:requestObj];

}

-(void)webViewDidFinishLoad:(UIWebView *) webView {
	NSLog(@"stopped loading web view..");
	[activityIndicator stopAnimating];
//	self.view = webView;
}

-(void)webViewDidStartLoad:(UIWebView *) webView {
	NSLog(@"start loading web view..");
	[activityIndicator startAnimating];
	
//	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:indicator];
//	self.navItem.rightBarButtonItem = button;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[webView release];
	[super dealloc];
}


@end

/*
@implementation UINavigationBar (UINavigationBarCategory)

- (void)drawRect:(CGRect)rect {
	UIColor *color = [UIColor blueColor];
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColor(context, CGColorGetComponents( [color CGColor]));
	CGContextFillRect(context, rect);
	self.tintColor = color;
}

@end
*/