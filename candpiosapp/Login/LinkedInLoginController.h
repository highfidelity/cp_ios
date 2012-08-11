//
//  LinkedInLoginController.h
//  candpiosapp
//
//  Created by Andrew Hammond on 3/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

@class OAToken;

@interface LinkedInLoginController : UIViewController <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *myWebView;

@property (nonatomic, retain) OAToken *requestToken;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

- (void)initiateLogin;
- (void)linkedInLogin;
- (void)loadLinkedInUserProfile;
- (void)loadLinkedInConnectionsWithCompletion:(void(^)(void))completionBlock;
- (void)handleLinkedInLogin:(NSString*)fullName linkedinID:(NSString *)linkedinID password:(NSString*)password email:(NSString *)email oauthToken:(NSString *)oauthToken oauthSecret:(NSString *)oauthSecret;

@end
