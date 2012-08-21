//
//  SmartererLoginController.h
//  candpiosapp
//
//  Created by Emmanuel Crouvisier.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

@class OAToken;

@interface SmartererLoginController : UIViewController <UIWebViewDelegate>
@property (strong, nonatomic) OAToken *requestToken;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIWebView *myWebView;

- (void)smartererLogin;
- (void)loadSmartererConnections:(NSString *)token;
@end
