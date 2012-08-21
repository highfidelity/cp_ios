//
//  SmartererLoginController.m
//  candpiosapp
//
//  Created by Emmanuel Crouvisier.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "SmartererLoginController.h"
#import "FlurryAnalytics.h"
#import "CPapi.h"

@implementation SmartererLoginController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
	self.navigationItem.rightBarButtonItem = button;
    
    [self initiateLogin];
}

- (void)smartererCredentialsCapture:(NSNotification*)notification {
    NSLog(@"caught smarterer credentials");
    
    NSString *urlString = [[notification userInfo] objectForKey:@"url"];
    
    // Process Smarterer Credentials
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
    
    NSString *code = [pairs objectForKey:@"code"];
    
    NSLog(@"Code: %@", code);
    
    NSString *authURLString = [NSString stringWithFormat:@"https://smarterer.com/oauth/access_token?client_id=%@&client_secret=%@&grant_type=authorization_code&code=%@", kSmartererKey, kSmartererSecret, code];
    NSURLRequest *request =  [NSURLRequest requestWithURL:[NSURL URLWithString:authURLString]];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request 
                                                                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                            NSLog(@"JSON: %@", JSON);
                                                                                            
                                                                                            NSString *token = [JSON objectForKey:@"access_token"];
                                                                                            
                                                                                            [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"smarterer_token"];
                                                                                            [[NSUserDefaults standardUserDefaults] synchronize];
                                                                                            
                                                                                            [self loadSmartererConnections:token];

                                                                                        }
                                                                                        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                            NSLog(@"failed: %@", JSON);
                                                                                        }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];    
}

-(void)initiateLogin
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(smartererCredentialsCapture:)
                                                 name:@"smartererCredentials"
                                               object:nil];
	
    [self smartererLogin];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"smartererCredentials" object:nil];
}

- (void)smartererLogin {
    NSLog(@"Smarterer Login");

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://smarterer.com/oauth/authorize?client_id=%@&callback_url=%@", kSmartererKey, kSmartererCallback]];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    self.myWebView.delegate = self;
    [self.myWebView loadRequest:requestObj];
}

- (void)loadSmartererConnections:(NSString *)token
{
    NSString *authURLString = [NSString stringWithFormat:@"https://smarterer.com/api/badges?access_token=%@", token];
    NSURLRequest *request =  [NSURLRequest requestWithURL:[NSURL URLWithString:authURLString]];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request 
                                                                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//                                                                                            NSLog(@"JSON: %@", JSON);
                                                                                            
                                                                                            NSString *username = [JSON objectForKey:@"username"];
                                                                                            NSLog(@"received username: %@", username);
                                                                                            
                                                                                            // Store the user's Smarterer username in C&P users table as smarterer_name
                                                                                            
                                                                                            [CPapi saveUserSmartererName:username :^(NSDictionary *json, NSError *error) {
                                                                                                NSLog(@"Payload: %@", [json valueForKey:@"payload"]);
//                                                                                                int success = [[json valueForKeyPath:@"payload.count"] intValue];
//                                                                                                int count = [[json valueForKeyPath:@"payload.count"] intValue];
                                                                                                // check if we had an error or nobody else is here
//                                                                                                if (!error && count != 0) {
//                                                                                                    NSLog(@"Success!");
//
//                                                                                                }
//                                                                                                
//                                                                                                else {
//                                                                                                    NSLog(@"Failure!");
//                                                                                                    
//                                                                                                }
                                                                                            }];
                                                                                            

                                                                                        }
                                                                                        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                            NSLog(@"failed: %@", JSON);
                                                                                        }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}

#pragma mark UIWebViewDelegate methods

-(void)webViewDidFinishLoad:(UIWebView *) webView {
	[self.activityIndicator stopAnimating];
}

-(void)webViewDidStartLoad:(UIWebView *) webView {
	[self.activityIndicator startAnimating];
}


@end
