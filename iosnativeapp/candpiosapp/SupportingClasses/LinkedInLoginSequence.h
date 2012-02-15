#import "LoginSequenceBase.h"
#import "OAuthConsumer.h"
#import "OAConsumer.h"

@interface LinkedInLoginSequence : LoginSequenceBase {
    OAToken *requestToken;
}

@property (nonatomic, retain) OAToken *requestToken;

-(void)initiateLogin:(UIViewController*)mapViewController;

- (void)linkedInLogin;
- (void)loadLinkedInConnections;
- (void)handleLinkedInLogin:(NSString*)fullName linkedinID:(NSString *)linkedinID password:(NSString*)password email:(NSString *)email oauthToken:(NSString *)oauthToken oauthSecret:(NSString *)oauthSecret;

@end
