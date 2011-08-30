//
//  WebWrapperView.m
//  candpwrapperapp
//
//  Created by David Mojdehi on 8/30/11.
//  Copyright 2011 Coffee and Power LLC. All rights reserved.
//

#import "WebWrapperView.h"

@implementation WebWrapperView

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	NSURL *homepageUrl = [NSURL URLWithString:@"http://coffeeandpower.com/m"];
	NSURLRequest *httpRequest = [NSURLRequest requestWithURL:homepageUrl];
    // Do any additional setup after loading the view from its nib.
	[mWebkitView loadRequest:httpRequest];
	
}

- (void)viewDidUnload
{
    [mWebkitView release];
    mWebkitView = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [mWebkitView release];
    [super dealloc];
}
@end
