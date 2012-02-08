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

    NSURL *url = [NSURL URLWithString:@"https://api.linkedin.com/v1/people/~"];
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
    NSString *responseBody = [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding];
//    SBJSON *parser = [[SBJSON alloc] init];
//    
//    NSDictionary *dict = [parser objectWithString:responseBody error:nil];
//    [parser release];
//    [responseBody release];

//    NSLog(@"Response: %@", responseBody);

    NSError* error;
    NSDictionary* json = [NSJSONSerialization 
                          JSONObjectWithData:data                          
                          options:kNilOptions 
                          error:&error];

    NSString *friendListName = [NSString stringWithFormat:@"%@ %@", 
                                [json objectForKey:@"firstName"],
                                [json objectForKey:@"lastName"]];
    
    
    NSDictionary *dict;
    NSMutableArray *values = [dict objectForKey:@"values"];
    
    //    NSMutableDictionary *theAccount = [self findTheLinkedInAccount];
    
    NSMutableArray *friends = [[NSMutableArray alloc] init];

//    NSString *friendListName;
    
    for (NSDictionary *person in values)
    {
        //        NSLog(@"person id: %@", [person objectForKey:@"id"]);
        NSLog(@"person name: %@ %@", [person objectForKey:@"firstName"], [person objectForKey:@"lastName"]);
        //        NSLog(@"person url: %@", [person objectForKey:@"pictureUrl"]);
        
//        friendListName = [NSString stringWithFormat:@"%@ %@", [person objectForKey:@"firstName"], [person objectForKey:@"lastName"]];
        NSString *friendListIdAsString = [person objectForKey:@"id"];
        NSString *friendListPicture = [person objectForKey:@"pictureUrl"];
        
        //        NSString *currentService = @"linkedin";
        NSInteger currentService = 2;
        //        NSString *currentList = @"linkedin";
        
        if (friendListPicture) {
//            [singleton addFriend:friendListIdAsString withName:friendListName withImageURL:friendListPicture toList:nil toService:currentService isConnected:YES];
            
            [friends addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                friendListIdAsString, @"id",
                                friendListName, @"name",
                                friendListPicture, @"picture",
                                nil]];
        }
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hello! Your name is..." message:friendListName delegate:self cancelButtonTitle:@"Yep!" otherButtonTitles:nil];
    [alert show];

    [self.mapViewController.navigationController dismissModalViewControllerAnimated:YES];
    [self.mapViewController.navigationController popToRootViewControllerAnimated:YES];
    
    //    [theAccount setObject:friends forKey:@"friends"];
}

- (void)loadLinkedInConnectionsResult:(OAServiceTicket *)ticket didFail:(NSData *)error 
{
    NSLog(@"%@",[error description]);
}

@end
