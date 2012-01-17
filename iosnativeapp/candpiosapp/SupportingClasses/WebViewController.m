#import "WebViewController.h"

@implementation WebViewController

@synthesize webView, urlAddress, activityIndicator;

- (IBAction)goBack:(id)sender {
	[webView goBack];
}

- (IBAction)buttonPressed:(id)sender
{
	NSLog(@"trying to close modal web view..");

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
        NSLog(@"Error");
	}
    
	//Create a URL object.
	NSURL *url = [NSURL URLWithString:urlAddress];
	
	//URL Requst Object
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];

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


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
}


@end
