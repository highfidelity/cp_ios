#import <UIKit/UIKit.h>


@interface WebViewController : UIViewController <UIWebViewDelegate> {
	IBOutlet UIWebView *webView;
	NSString *urlAddress;
	UIActivityIndicatorView *activityIndicator;
}

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSString *urlAddress;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

-(IBAction)goBack:(id)sender;
//-(IBAction)buttonPressed:(id)sender;

@end
