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
@synthesize urlToLoad;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
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
	
	//
	NSURL *mobileUrl = nil;
	if(urlToLoad)
	{
		mobileUrl = [NSURL URLWithString:urlToLoad];
	}
	else
	{
		// load the default page
		[ NSURL URLWithString:@"https://coffeeandpower.com/m"];
	}
	NSURLRequest *mobileLoginRequest = [NSURLRequest requestWithURL:mobileUrl];
	[webView loadRequest:mobileLoginRequest];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
