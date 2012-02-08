#import <UIKit/UIKit.h>


@interface ModalWebViewController : UIViewController <UIWebViewDelegate> {

	IBOutlet UINavigationItem *navItem;
	IBOutlet	UILabel		*modalTitle;
	IBOutlet UIWebView *webView;
	NSString *urlAddress;
	NSString *windowTitle;
	UIActivityIndicatorView *activityIndicator;
}

@property (retain, nonatomic) UINavigationItem *navItem;
@property (retain, nonatomic) UILabel *modalTitle;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSString *urlAddress;
@property (nonatomic, retain) NSString *windowTitle;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

-(IBAction)goBack:(id)sender;

@end
