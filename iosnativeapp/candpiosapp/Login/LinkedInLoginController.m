//
//  LinkedInLoginController.m
//  candpiosapp
//
//  Created by Andrew Hammond on 3/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LinkedInLoginController.h"
#import "AFNetworking.h"
#import "FlurryAnalytics.h"
//#import "ModalWebViewController.h"
#import "OAConsumer.h"
#import "OAMutableURLRequest.h"
#import "OADataFetcher.h"
#import "SSKeychain.h"

@implementation LinkedInLoginController
@synthesize myWebView;
@synthesize requestToken;
@synthesize activityIndicator;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	self.navigationItem.rightBarButtonItem = button;
    
    // check for token in keychain
    NSString *keyToken = [SSKeychain passwordForService:@"linkedin" account:@"token"];
    NSString *keyTokenSecret = [SSKeychain passwordForService:@"linkedin" account:@"token_secret"];
    
    if (keyToken && keyTokenSecret)
    {
        // token and token secret found in keychain
        // update user defaults and attempt login
        NSLog(@"token:%@ account:%@", keyToken, keyTokenSecret);
        
        [[NSUserDefaults standardUserDefaults] setObject:keyToken forKey:@"linkedin_token"];
        [[NSUserDefaults standardUserDefaults] setObject:keyTokenSecret forKey:@"linkedin_secret"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self loadLinkedInConnections];
        //[self linkedInLogin];
    }
    else
    {
        // no token/secret in keychain
        [self initiateLogin];
    }
}

- (void)viewDidUnload
{
    [self setMyWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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

-(void)initiateLogin
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(linkedInCredentialsCapture:)
                                                 name:@"linkedInCredentials"
                                               object:nil];
	
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
        
        NSURL *url = [NSURL URLWithString:authorizationURL];        
        NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
        self.myWebView.delegate = self;
        [self.myWebView loadRequest:requestObj];
        
        //        ModalWebViewController *myWebView = [[ModalWebViewController alloc] init];
        //        myWebView.urlAddress = authorizationURL;
        //        [self.navigationController presentModalViewController:myWebView animated:YES];
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
    
    NSString *generatedEmail = email;
    
    if (!linkedinID)
    {
        [self initiateLogin];
    }
    else
    {
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
                // we get here if we failed to login
                NSString *errorMessage = [NSString stringWithFormat:@"The error was: %@", outerErrorMessage];\
                [SVProgressHUD showErrorWithStatus:errorMessage duration:kDefaultDimissDelay];
                [[AppDelegate instance].tabBarController
                        performSelector:@selector(dismissModalViewControllerAnimated:)
                             withObject:[NSNumber numberWithBool:YES]
                             afterDelay:kDefaultDimissDelay];

            }
            else
            {
                // remember that we're logged in!
                // (it's really the persistent cookie that tracks our login, but we need a superficial indicator, too)
                NSDictionary *userInfo = [[JSON objectForKey:@"params"] objectForKey:@"params"];

                [CPAppDelegate storeUserLoginDataFromDictionary:userInfo];

                NSString *userId = [userInfo objectForKey:@"id"];
                NSString *userEmail = [userInfo objectForKey:@"email"];
                BOOL hasSentConfirmationEmail = [[userInfo objectForKey:@"has_confirm_string"] boolValue];

                [FlurryAnalytics logEvent:@"login_linkedin"];
                [FlurryAnalytics setUserID:userId];

                // Perform common post-login operations
                [BaseLoginController pushAliasUpdate];

                if ( ! hasSentConfirmationEmail && (
                         ! userEmail ||
                        [@"" isEqualToString:userEmail] ||
                        [generatedEmail isEqualToString:userEmail]
                    )) {
                    [self performSegueWithIdentifier:@"EnterEmailAfterSignUpSegue" sender:nil];
                } else {
                    if ([CPAppDelegate currentUser].enteredInviteCode) {
                        if ([[CPAppDelegate tabBarController] selectedIndex] == 4) {
                            [[CPAppDelegate tabBarController] setSelectedIndex:0];
                        }
                        [self.navigationController dismissModalViewControllerAnimated:YES];
                    } else {
                        [self performSegueWithIdentifier:@"EnterInvitationCodeSegue" sender:nil];
                    }
                }
            }

            // Remove NSNotification as it's no longer needed once logged in
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"linkedInCredentials" object:nil];

        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            [SVProgressHUD showErrorWithStatus:[error localizedDescription] duration:kDefaultDimissDelay];

        }];
        
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [queue addOperation:operation];  
    }
}

- (void)loadLinkedInConnectionsResult:(OAServiceTicket *)ticket didFail:(NSData *)error 
{
    NSLog(@"%@",[error description]);
}

#pragma mark UIWebViewDelegate methods

-(void)webViewDidFinishLoad:(UIWebView *) webView {
	[activityIndicator stopAnimating];
}

-(void)webViewDidStartLoad:(UIWebView *) webView {
	[activityIndicator startAnimating];
}


@end
