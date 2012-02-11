#import "LinkedInLoginSequence.h"
#import "AppDelegate.h"
#import "AFNetworking.h"
#import "Facebook+Blocks.h"
#import "NSMutableURLRequestAdditions.h"
#import "MyWebTabController.h"
#import "EmailLoginSequence.h"
#import "SVProgressHUD.h"
#import "FlurryAnalytics.h"
#import "ModalWebViewController.h"

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
    
    //        request.verifier = verifier;
    
    [request setHTTPMethod:@"POST"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(requestTokenTicket:didFinishWithAccessToken:)
                  didFailSelector:@selector(requestTokenTicket:didFailWithError:)];
    
    //        [self.navController.visibleViewController dismissModalViewControllerAnimated:YES];
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

    /*
	if (![[AppDelegate instance].facebook isSessionValid]) {
		[[AppDelegate instance].facebook authorize:[NSArray arrayWithObjects:@"offline_access", nil]];
	}
	else
	{
		// we have a facebook session, so just get our info & set it with c&p
		[self handleResponseFromLinkedInLogin];
	}
     */
    
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
//        NSLog(@"*** Response: %@", responseBody);
        
        
        NSString *authorizationURL = [NSString stringWithFormat:@"https://www.linkedin.com/uas/oauth/authorize?oauth_token=%@", requestToken.key];
        
        ModalWebViewController *myWebView = [[ModalWebViewController alloc] init];
        myWebView.urlAddress = authorizationURL;

        [self.mapViewController.navigationController presentModalViewController:myWebView animated:YES];
    }
    else {
        NSString *responseBody = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];

//        NSLog(@"data: %@", responseBody);
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
        
//        [singleton addService:@"LinkedIn" id:2 accessToken:token accessSecret:secret expirationDate:nil];
        
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
//    NSURL *url = [NSURL URLWithString:@"https://api.linkedin.com/v1/people/~/connections"];
    
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

    fullName = (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                 (__bridge CFStringRef) fullName,
                                                                 NULL,
                                                                 (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                                                 kCFStringEncodingUTF8);
    
    linkedinId = [json objectForKey:@"id"];

    // Generate truly random password
    password = [NSString stringWithFormat:@"%d-%@", [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]], [[NSProcessInfo processInfo] globallyUniqueString]];

    // Assign an identifying email address (prompt user in the future?)
    email = [NSString stringWithFormat:@"%@@linkedin.com", linkedinId];
    
    email = (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                         (__bridge CFStringRef) email,
                                                                         NULL,
                                                                         (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                                                         kCFStringEncodingUTF8);
    
    oauthToken = self.requestToken.key;
    oauthSecret = self.requestToken.secret;
    
    // Now that we have the user's basic information, log them in with their new/existing account

    [self handleLinkedInLogin:fullName linkedinID:linkedinId password:password email:email oauthToken:oauthToken oauthSecret:oauthSecret];
}

- (void)handleLinkedInLogin:(NSString*)fullName linkedinID:(NSString *)linkedinID password:(NSString*)password email:(NSString *)email oauthToken:(NSString *)oauthToken oauthSecret:(NSString *)oauthSecret {
    // kick off the request to the candp server

    NSString *urlString = [NSString stringWithFormat:@"%@signup.php?action=signup&type=json&signupNickname=%@&linkedin_id=%@&linkedin_connect=1&signupUsername=%@&oauth_token=%@&oauth_secret=%@&signupPassword=%@&signupConfirm=%@", 
//                           @"http://dev.worklist.net/~emcro/candpweb/web/",
                           kCandPWebServiceUrl, 
                           fullName,
                           linkedinID,
                           email,
                           oauthToken,
                           oauthSecret,
                           password,
                           password];
#if DEBUG
//    NSLog(@"Logging in via: %@", urlString);
#endif
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
#if DEBUG
//        NSLog(@"JSON Returned for user resume: %@", JSON);
#endif

        NSInteger succeeded = [[JSON objectForKey:@"succeeded"] intValue];
        NSLog(@"success: %d", succeeded);

		if(succeeded == 0)
		{
            
			NSString *outerErrorMessage = [JSON objectForKey:@"message"];// often just 'error'
//			NSString *serverErrorMessage;
//            
//            if ([JSON objectForKey:@"params"]) {
//                serverErrorMessage = [[JSON objectForKey:@"params"] objectForKey:@"message"];
//            }
            
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
			
			NSNumber *userId = [userInfo objectForKey:@"id"];
			NSString  *nickname = [userInfo objectForKey:@"nickname"];

			// extract some user info
			[AppDelegate instance].settings.candpUserId = userId;
			[AppDelegate instance].settings.userNickname = nickname;
			[[AppDelegate instance] saveSettings];
            
            [FlurryAnalytics logEvent:@"login_linkedin"];
            
            // userId isn't actually an NSNumber it's an NSString!?
            [FlurryAnalytics setUserID:(NSString *)userId];
            
            // Set alias of push token to userId for easy push notifications from the server
            [[UAPush shared] updateAlias:(NSString *)userId];
            
            [self.mapViewController.navigationController dismissModalViewControllerAnimated:YES];
            [self.mapViewController.navigationController popToRootViewControllerAnimated:YES];
		}
        
        // Remove NSNotification as it's no longer needed once logged in
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"linkedInCredentials" object:nil];

        
//        if(completion)
//            completion(self, nil); 
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
//        if(completion)
//            completion(nil, error);
    }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
    

    /*
//    NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"GET" path:@"signup.php" parameters:loginParams];


	NSMutableURLRequest *request = [client requestWithMethod:@"POST" path:@"signup.php" parameters:loginParams];
	AFJSONRequestOperation *postOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
		NSDictionary *jsonDict = json;
#if DEBUG
		NSLog(@"Result code: %d (%@)", [response statusCode], [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]] );
		
		
		NSLog(@"Header fields:" );
		[[response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			NSLog(@"     %@ : '%@'", key, obj );
			
		}];
		
		NSLog(@"Json fields:" );
		[jsonDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			NSLog(@"     %@ : '%@'", key, obj );
			
		}];
#endif
		[SVProgressHUD dismiss];
        
		// currently, we only a success=0 field if it fails
		// (if it succeeds, it's just the user data)
		NSNumber *successNum = [jsonDict objectForKey:@"succeeded"];
		if(successNum && [successNum intValue] == 0)
		{
            
			NSString *outerErrorMessage = [jsonDict objectForKey:@"message"];// often just 'error'
			NSString *serverErrorMessage = [[jsonDict objectForKey:@"params"] objectForKey:@"message"];
			NSString *errorMessage = [NSString stringWithFormat:@"The error was:%@", serverErrorMessage];
			// we get here if we failed to login
			UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Unable to login" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		}
		else
		{
			// remember that we're logged in!
			// (it's really the persistent cookie that tracks our login, but we need a superficial indicator, too)
			NSDictionary *userInfo = [[jsonDict objectForKey:@"params"]objectForKey:@"user"];
			
			NSNumber *userId = [userInfo objectForKey:@"id"];
			NSString  *nickname = [userInfo objectForKey:@"nickname"];
			
			// extract some user info
			[AppDelegate instance].settings.candpUserId = userId;
			[AppDelegate instance].settings.userNickname = nickname;
			[[AppDelegate instance] saveSettings];
            
            [FlurryAnalytics logEvent:@"login_email"];
            
            // userId isn't actually an NSNumber it's an NSString!?
            [FlurryAnalytics setUserID:(NSString *)userId];
            
            // Set alias of push token to userId for easy push notifications from the server
            [[UAPush shared] updateAlias:(NSString *)userId];
            
			// 
			//[mapViewController.navigationController popViewControllerAnimated:YES];
			[self.mapViewController.navigationController popToRootViewControllerAnimated:YES];
		}
		
		//[self handleResponseFromCandP:json];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		// handle error
#if DEBUG
		NSLog(@"AFJSONRequestOperation error: %@", [error localizedDescription] );
#endif
		[SVProgressHUD dismissWithError:[error localizedDescription]];
        
		
	} ];
	
	// 
	NSBlockOperation *dumpContents = [NSBlockOperation blockOperationWithBlock:^{
		// 
#if DEBUG
		NSString *responseString = postOperation.responseString;
		NSLog(@"Response was:");
		NSLog(@"-----------------------------------------------");
		NSLog(@"%@", responseString);
		NSLog(@"-----------------------------------------------");
#endif
	}];
	[dumpContents addDependency:postOperation];
	[[NSOperationQueue mainQueue]  addOperation:postOperation];
	[[NSOperationQueue mainQueue]  addOperation:dumpContents];
*/
//UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hello! Your name is..." message:friendListName delegate:self cancelButtonTitle:@"Yep!" otherButtonTitles:nil];
//[alert show];

// Remove NSNotification as it's no longer needed once logged in
//[[NSNotificationCenter defaultCenter] removeObserver:self name:@"linkedInCredentials" object:nil];
//
//[self.mapViewController.navigationController dismissModalViewControllerAnimated:YES];
//[self.mapViewController.navigationController popToRootViewControllerAnimated:YES];
}

- (void)loadLinkedInConnectionsResult:(OAServiceTicket *)ticket didFail:(NSData *)error 
{
    NSLog(@"%@",[error description]);
}

@end
