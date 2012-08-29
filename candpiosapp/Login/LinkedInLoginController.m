//
//  LinkedInLoginController.m
//  candpiosapp
//
//  Created by Andrew Hammond on 3/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LinkedInLoginController.h"
#import "FlurryAnalytics.h"
#import "OAConsumer.h"
#import "OAMutableURLRequest.h"
#import "OADataFetcher.h"
#import "SSKeychain.h"
#import "CPLinkedInAPI.h"
#import "CPapi.h"
#import "CPCheckinHandler.h"
#import "CPUserSessionHandler.h"

typedef void (^LoadLinkedInConnectionsCompletionBlockType)();

@interface LinkedInLoginController ()

@property (strong, nonatomic) AFHTTPClient *httpClient;
@property (strong, nonatomic) LoadLinkedInConnectionsCompletionBlockType loadLinkedInConnectionsCompletionBlock;

@end

@implementation LinkedInLoginController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // create client for web based logins
    self.httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kCandPWebServiceSecureUrl]];
    // set a liberal cookie policy
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy: NSHTTPCookieAcceptPolicyAlways];

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
	self.navigationItem.rightBarButtonItem = button;
    
    // check for token in keychain
    NSString *keyToken = [SSKeychain passwordForService:@"linkedin" account:@"token"];
    NSString *keyTokenSecret = [SSKeychain passwordForService:@"linkedin" account:@"token_secret"];
    
    if (keyToken && keyTokenSecret)
    {
        // token and token secret found in keychain
        // update user defaults and attempt login
        
        [[NSUserDefaults standardUserDefaults] setObject:keyToken forKey:@"linkedin_token"];
        [[NSUserDefaults standardUserDefaults] setObject:keyTokenSecret forKey:@"linkedin_secret"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self loadLinkedInUserProfile];
        //[self linkedInLogin];
    }
    else
    {
        // no token/secret in keychain
        [self initiateLogin];
    }
}


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
    
    NSString *verifier = [pairs objectForKey:@"oauth_verifier"];
    
    // Now get the final auth token
    OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kLinkedInKey secret:kLinkedInSecret];
    
    // TODO: Probably need to remove requestToken here and use the one passed
    //        NSString *token = [pairs objectForKey:@"oauth_token"];
    //        OAToken *requestToken = [[OAToken alloc] initWithKey:token secret:nil];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.linkedin.com/uas/oauth/accessToken"]
                                                                   consumer:consumer
                                                                      token:self.requestToken
                                                                      realm:@"http://api.linkedin.com/"
                                                                   verifier:verifier
                                                          signatureProvider:nil];
    
    [request setHTTPMethod:@"POST"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(requestTokenTicket:didFinishWithAccessToken:)
                  didFailSelector:@selector(requestTokenTicket:didFailWithError:)];
}

-(void)initiateLogin
{
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(linkedInCredentialsCapture:)
                                                 name:@"linkedInCredentials"
                                               object:nil];
	
	[CPUserSessionHandler logoutEverything];
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

    OARequestParameter *scopeParameter = [OARequestParameter requestParameter:@"scope" value:@"r_fullprofile r_network r_emailaddress"];
    [request setParameters:[NSArray arrayWithObject:scopeParameter]];
    
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
        
        NSString *authorizationURL = [NSString stringWithFormat:@"https://www.linkedin.com/uas/oauth/authorize?oauth_token=%@", self.requestToken.key];
        
        NSURL *url = [NSURL URLWithString:authorizationURL];        
        NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
        self.myWebView.delegate = self;
        [self.myWebView loadRequest:requestObj];
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
        
        // store in keychain
        [SSKeychain setPassword:token forService:@"linkedin" account:@"token"];
        [SSKeychain setPassword:secret forService:@"linkedin" account:@"token_secret"];
        
        // store in user defaults
        [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"linkedin_token"];
        [[NSUserDefaults standardUserDefaults] setObject:secret forKey:@"linkedin_secret"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self loadLinkedInUserProfile];
    }
}

- (void)loadLinkedInUserProfile
{
    self.requestToken = [CPLinkedInAPI shared].token;
    OAMutableURLRequest *request = [[CPLinkedInAPI shared] linkedInJSONAPIRequestWithRelativeURL:
                                    @"v1/people/~:(id,first-name,last-name,email-address)"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(loadLinkedInUserProfileResult:didFinish:)
                  didFailSelector:@selector(loadLinkedInUserProfileResult:didFail:)];
}

- (void)loadLinkedInUserProfileResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
    NSString *fullName, *linkedinId, *password, *email, *oauthToken, *oauthSecret;
    
    NSString *responseBody = [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding];
    NSLog(@"Response: %@", responseBody);
    
    NSError* error;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:kNilOptions
                                                           error:&error];
    
    fullName = [NSString stringWithFormat:@"%@ %@",
                [json objectForKey:@"firstName"],
                [json objectForKey:@"lastName"]];
    
    linkedinId = [json objectForKey:@"id"];
    
    // Generate truly random password
    password = [NSString stringWithFormat:@"%d-%@", [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] intValue], [[NSProcessInfo processInfo] globallyUniqueString]];
    
    email = [json objectForKey:@"emailAddress"];
    
    oauthToken = self.requestToken.key;
    oauthSecret = self.requestToken.secret;
    
    // Now that we have the user's basic information, log them in with their new/existing account
    
    [self handleLinkedInLogin:fullName linkedinID:linkedinId password:password email:email oauthToken:oauthToken oauthSecret:oauthSecret];
}

- (void)handleLinkedInLogin:(NSString*)fullName linkedinID:(NSString *)linkedinID password:(NSString*)password email:(NSString *)email oauthToken:(NSString *)oauthToken oauthSecret:(NSString *)oauthSecret {
    // kick off the request to the candp server
    
    if (!linkedinID)
    { 
        [self initiateLogin];
    }
    else
    {
        // TODO: Move this functionality to api.php
        
        NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
        
        [loginParams setObject:fullName forKey:@"signupNickname"];
        [loginParams setObject:linkedinID forKey:@"linkedin_id"];
        [loginParams setObject:@"1" forKey:@"linkedin_connect"];
        [loginParams setObject:@"2" forKey:@"linkedin_version"];
        [loginParams setObject:email forKey:@"signupUsername"];
        [loginParams setObject:oauthToken forKey:@"oauth_token"];
        [loginParams setObject:oauthSecret forKey:@"oauth_secret"];
        [loginParams setObject:password forKey:@"signupPassword"];
        [loginParams setObject:password forKey:@"signupConfirm"];
        [loginParams setObject:@"mobileSignup" forKey:@"action"];

        [SVProgressHUD showWithStatus:@"Logging in..."];

        NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"POST" path:@"api.php" parameters:loginParams];
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            NSInteger succeeded = [[JSON objectForKey:@"succeeded"] intValue];

            if(succeeded == 0) {
                NSString *outerErrorMessage = [JSON objectForKey:@"message"];// often just 'error'
                // we get here if we failed to login
                NSString *errorMessage = [NSString stringWithFormat:@"The error was: %@", outerErrorMessage];\
                [SVProgressHUD showErrorWithStatus:errorMessage duration:kDefaultDismissDelay];
            } else {
                // remember that we're logged in!
                // (it's really the persistent cookie that tracks our login, but we need a superficial indicator, too)
                NSDictionary *userInfo = [[JSON objectForKey:@"params"] objectForKey:@"params"];
                
                [CPUserSessionHandler storeUserLoginDataFromDictionary:userInfo];

                NSString *userId = [userInfo objectForKey:@"id"];

                NSDictionary *checkInDict = [userInfo valueForKey:@"checkin_data"];
                if ([[checkInDict objectForKey:@"checked_in"] boolValue]) {
                    CPVenue *venue = [[CPVenue alloc] initFromDictionary:checkInDict];

                    NSInteger checkOutTime =[[checkInDict objectForKey:@"checkout"] integerValue];
                    [[CPCheckinHandler sharedHandler] saveCheckInVenue:venue
                                    andCheckOutTime:checkOutTime];
                } else {
                    [[CPCheckinHandler sharedHandler] setCheckedOut];
                }

                [FlurryAnalytics logEvent:@"login_linkedin"];
                [FlurryAnalytics setUserID:userId];
                
                [SVProgressHUD dismiss];
            }
            
            [[CPAppDelegate tabBarController]
             performSelector:@selector(dismissModalViewControllerAnimated:)
             withObject:[NSNumber numberWithBool:YES]
             afterDelay:kDefaultDismissDelay];

            // Remove NSNotification as it's no longer needed once logged in
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"linkedInCredentials" object:nil];

        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            [SVProgressHUD showErrorWithStatus:[error localizedDescription] duration:kDefaultDismissDelay];

        }];
        
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [queue addOperation:operation];  
    }
}

- (void)loadLinkedInUserProfileResult:(OAServiceTicket *)ticket didFail:(NSData *)error
{
    NSLog(@"%@",[error description]);
}

- (void)loadLinkedInConnectionsWithCompletion:(void(^)(void))completionBlock {
    self.loadLinkedInConnectionsCompletionBlock = completionBlock;
    
    OAMutableURLRequest *request = [[CPLinkedInAPI shared] linkedInJSONAPIRequestWithRelativeURL:
                                                                        @"v1/people/~/connections:(id)"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(loadLinkedInConnectionsResult:didFinish:)
                  didFailSelector:@selector(loadLinkedInConnectionsResult:didFail:)];
}

- (void)loadLinkedInConnectionsResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:kNilOptions
                                                           error:&error];
    
    if ( ! error) {
        [CPapi addContactsByLinkedInIDs:[json objectForKey:@"values"]];
    }
    
    LoadLinkedInConnectionsCompletionBlockType completion = self.loadLinkedInConnectionsCompletionBlock;
    self.loadLinkedInConnectionsCompletionBlock = nil;
    
    completion();
}

- (void)loadLinkedInConnectionsResult:(OAServiceTicket *)ticket didFail:(NSData *)error
{
    LoadLinkedInConnectionsCompletionBlockType completion = self.loadLinkedInConnectionsCompletionBlock;
    self.loadLinkedInConnectionsCompletionBlock = nil;
    
    completion();
}

#pragma mark UIWebViewDelegate methods

-(void)webViewDidFinishLoad:(UIWebView *) webView {
	[self.activityIndicator stopAnimating];
}

-(void)webViewDidStartLoad:(UIWebView *) webView {
	[self.activityIndicator startAnimating];
}


@end
