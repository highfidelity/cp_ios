#import "BaseLoginController.h"
@class OAToken;

@interface SmartererLoginController : BaseLoginController <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *myWebView;

@property (nonatomic, retain) OAToken *requestToken;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

- (void)smartererLogin;
- (void)loadSmartererConnections:(NSString *)token;
@end
