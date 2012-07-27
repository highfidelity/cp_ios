#import "BaseLoginController.h"
@class OAToken;

@interface SmartererLoginController : BaseLoginController <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *myWebView;
@property (strong, nonatomic) OAToken *requestToken;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

- (void)smartererLogin;
- (void)loadSmartererConnections:(NSString *)token;
@end
