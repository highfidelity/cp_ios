#import "ModalWebViewController.h"


@implementation ModalWebViewController

@synthesize webView, urlAddress, modalTitle, navItem, windowTitle, activityIndicator;

- (IBAction)goBack:(id)sender {
	[webView goBack];
}

- (IBAction)buttonPressed:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		// Initialization code
	}
	return self;
}

/*
 If you need to do additional setup after loading the view, override viewDidLoad. */
- (void)viewDidLoad {

    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(buttonPressed:)];
    navItem.leftBarButtonItem = closeButton;

    if (windowTitle) {
        navItem.title = windowTitle;
    }
    
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	self.navItem.rightBarButtonItem = button;
		
	NSURL *url = [NSURL URLWithString:urlAddress];
	
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];

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
	[super didReceiveMemoryWarning];
}

@end
