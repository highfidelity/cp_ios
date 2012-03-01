#import "LinkedInLoginSequence.h"
#import "AppDelegate.h"
#import "AFNetworking.h"
#import "FlurryAnalytics.h"
#import "ModalWebViewController.h"
#import "NSString+StringToNSNumber.h"

@implementation LinkedInLoginSequence

@synthesize requestToken;

- (void)linkedInCredentialsCapture:(NSNotification*)notification {
    NSString *urlString = [[notification userInfo] objectForKey:@"url"];

    // Process LinkedIn Credentials
    NSMutableDictionary* pairs = [NSMutableDictionary dictionary] ;
    NSScanner* scanner = [[NSScanner alloc] initWithString:urlString] ;
    NSCharacterSet* delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@"?&;#"];
    
    while (![scanner isAtEnd]) {
        NSString* pairString ;
        [scanner scanUpToCharactersFromSet:delimiterSet
                                intoString:&pairString] ;
        [scanner scanCharactersFromSet:delimiterSet intoString:NULL] ;
        NSArray* kvPair = [pairString componentsSeparatedByString:@"="] ;
        if ([kvPair count] == 2) {
            NSString* key = [kvPair objectAtIndex:0];
            NSString* value = [kvPair objectAtIndex:1];
            [pairs setObject:value forKey:key] ;
        }
    }
    
    NSString *token = [pairs objectForKey:@"oauth_token"];
    NSString *verifier = [pairs objectForKey:@"oauth_verifier"];
    
    NSLog(@"Token: %@, Verifier: %@", token, verifier);
    
    
    // Now get the final auth token
    OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kLinkedInKey secret:kLinkedInSecret];
    
    // TODO: Probably need to remove requestToken here and use the one passed
    //        OAToken *requestToken = [[OAToken alloc] initWithKey:token secret:nil];

    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.linkedin.com/uas/oauth/accessToken"]
                                                                   consumer:consumer
                                                                      token:requestToken
                                                                      realm:@"http://api.linkedin.com/"
                                                                   verifier:verifier
                                                          signatureProvider:nil];
    
    [request setHTTPMethod:@"POST"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(requestTokenTicket:didFinishWithAccessToken:)
                  didFailSelector:@selector(requestTokenTicket:didFailWithError:)];

    NSLog(@"Dismiss window");

    
}

-(void)initiateLogin:(UIViewController*)mapViewControllerArg;
{
	self.mapViewController = mapViewControllerArg;

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(linkedInCredentialsCapture:)
                                                 name:@"linkedInCredentials"
                                               object:nil];
	
	// set a liberal cookie policy
	[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy: NSHTTPCookieAcceptPolicyAlways];
	[[AppDelegate instance] logoutEverything];
    [self linkedInLogin];
}

- (void)linkedInLogin {
    NSLog(@"LinkedIn Login");
    
    OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kLinkedInKey secret:kLinkedInSecret];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.linkedin.com/uas/oauth/requestToken"]
                                                                   consumer:consumer
                                                                      token:nil
                                                                      realm:nil
                                                          signatureProvider:nil];
    
    [request setHTTPMethod:@"POST"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(requestTokenTicket:didFinishWithData:)
                  didFailSelector:@selector(requestTokenTicket:didFailWithError:)];
}

- (void)requestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSData *)data {
    NSLog(@"Data: %@", data);
}

- (void)requestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    if (ticket.didSucceed) {
        NSString *responseBody = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];
        self.requestToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
        // NSLog(@"*** Response: %@", responseBody);
        
        NSString *authorizationURL = [NSString stringWithFormat:@"https://www.linkedin.com/uas/oauth/authorize?oauth_token=%@", requestToken.key];
        
        ModalWebViewController *myWebView = [[ModalWebViewController alloc] init];
        myWebView.urlAddress = authorizationURL;

        [self.mapViewController.navigationController presentModalViewController:myWebView animated:YES];
    }
}

- (void)requestTokenTicket:(OAServiceTicket *)ticket didFinishWithAccessToken:(NSData *)data {    
    if (ticket.didSucceed) {        
        NSString *responseBody = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];

        NSMutableDictionary* pairs = [NSMutableDictionary dictionary] ;
        NSScanner* scanner = [[NSScanner alloc] initWithString:responseBody] ;
        NSCharacterSet* delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@"&"];
        
        while (![scanner isAtEnd]) {
            NSString* pairString ;
            [scanner scanUpToCharactersFromSet:delimiterSet
                                    intoString:&pairString] ;
            [scanner scanCharactersFromSet:delimiterSet intoString:NULL] ;
            NSArray* kvPair = [pairString componentsSeparatedByString:@"="] ;
            if ([kvPair count] == 2) {
                NSString* key = [kvPair objectAtIndex:0];
                NSString* value = [kvPair objectAtIndex:1];
                [pairs setObject:value forKey:key] ;
            }
        }
        
        NSString *token = [pairs objectForKey:@"oauth_token"];
        NSString *secret = [pairs objectForKey:@"oauth_token_secret"];
        
        // Store auth token + secret
        [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"linkedin_token"];
        [[NSUserDefaults standardUserDefaults] setObject:secret forKey:@"linkedin_secret"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self loadLinkedInConnections];
    }
}

- (void)loadLinkedInConnections
{
    OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kLinkedInKey secret:kLinkedInSecret];
    
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"linkedin_token"];
    NSString *secret = [[NSUserDefaults standardUserDefaults] objectForKey:@"linkedin_secret"];
    
    self.requestToken = [[OAToken alloc] initWithKey:token secret:secret];

    NSLog(@"Final token: %@", self.requestToken);
    
    NSURL *url = [NSURL URLWithString:@"https://api.linkedin.com/v1/people/~:(id,first-name,last-name,headline,site-standard-profile-request)"];
    
    OAMutableURLRequest *request = 
    [[OAMutableURLRequest alloc] initWithURL:url
                                    consumer:consumer
                                       token:self.requestToken
                                       realm:nil
                           signatureProvider:nil];
    
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(loadLinkedInConnectionsResult:didFinish:)
                  didFailSelector:@selector(loadLinkedInConnectionsResult:didFail:)];    
}

- (void)loadLinkedInConnectionsResult:(OAServiceTicket *)ticket didFinish:(NSData *)data 
{
    NSString *fullName, *linkedinId, *password, *email, *oauthToken, *oauthSecret;
    
    NSString *responseBody = [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding];
    NSLog(@"Response: %@", responseBody);

    NSError* error;
    NSDictionary* json = [NSJSONSerialization 
                          JSONObjectWithData:data                          
                          options:kNilOptions 
                          error:&error];

    fullName = [NSString stringWithFormat:@"%@ %@", 
                                [json objectForKey:@"firstName"],
                                [json objectForKey:@"lastName"]];

    linkedinId = [json objectForKey:@"id"];

    // Generate truly random password
    password = [NSString stringWithFormat:@"%d-%@", [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]], [[NSProcessInfo processInfo] globallyUniqueString]];

    // Assign an identifying email address (prompt user in the future?)
    email = [NSString stringWithFormat:@"%@@linkedin.com", linkedinId];
    
    oauthToken = self.requestToken.key;
    oauthSecret = self.requestToken.secret;
    
    // Now that we have the user's basic information, log them in with their new/existing account

    [self handleLinkedInLogin:fullName linkedinID:linkedinId password:password email:email oauthToken:oauthToken oauthSecret:oauthSecret];
}

- (void)handleLinkedInLogin:(NSString*)fullName linkedinID:(NSString *)linkedinID password:(NSString*)password email:(NSString *)email oauthToken:(NSString *)oauthToken oauthSecret:(NSString *)oauthSecret {
    // kick off the request to the candp server

    NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];

    [loginParams setObject:fullName forKey:@"signupNickname"];
    [loginParams setObject:linkedinID forKey:@"linkedin_id"];
    [loginParams setObject:@"1" forKey:@"linkedin_connect"];
    [loginParams setObject:email forKey:@"signupUsername"];
    [loginParams setObject:oauthToken forKey:@"oauth_token"];
    [loginParams setObject:oauthSecret forKey:@"oauth_secret"];
    [loginParams setObject:password forKey:@"signupPassword"];
    [loginParams setObject:password forKey:@"signupConfirm"];
    [loginParams setObject:@"signup" forKey:@"action"];
    [loginParams setObject:@"json" forKey:@"type"];

	NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"POST" path:@"signup.php" parameters:loginParams];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {

        NSInteger succeeded = [[JSON objectForKey:@"succeeded"] intValue];
        NSLog(@"success: %d", succeeded);

		if(succeeded == 0)
		{
			NSString *outerErrorMessage = [JSON objectForKey:@"message"];// often just 'error'

			NSString *errorMessage = [NSString stringWithFormat:@"The error was:%@", outerErrorMessage];
			// we get here if we failed to login
			UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Unable to log in" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];

            [self.mapViewController.navigationController dismissModalViewControllerAnimated:YES];
		}
		else
		{
			// remember that we're logged in!
			// (it's really the persistent cookie that tracks our login, but we need a superficial indicator, too)
			NSDictionary *userInfo = [[JSON objectForKey:@"params"] objectForKey:@"params"];
			
			NSString *userId = [userInfo objectForKey:@"id"];
			NSString  *nickname = [userInfo objectForKey:@"nickname"];

			// extract some user info
			[AppDelegate instance].settings.candpUserId = [userId numberFromIntString];
			[AppDelegate instance].settings.userNickname = nickname;
			[[AppDelegate instance] saveSettings];
            
            [FlurryAnalytics logEvent:@"login_linkedin"];
            
            // userId isn't actually an NSNumber it's an NSString!?
            [FlurryAnalytics setUserID:(NSString *)userId];
            
            // Perform common post-login operations
            [self finishLogin];
            
            [self.mapViewController.navigationController dismissModalViewControllerAnimated:YES];
            [self.mapViewController.navigationController popToRootViewControllerAnimated:YES];
		}
        
        // Remove NSNotification as it's no longer needed once logged in
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"linkedInCredentials" object:nil];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
    }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];    
}

- (void)loadLinkedInConnectionsResult:(OAServiceTicket *)ticket didFail:(NSData *)error 
{
    NSLog(@"%@",[error description]);
}

@end
