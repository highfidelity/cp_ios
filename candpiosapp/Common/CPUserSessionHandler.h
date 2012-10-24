//
//  CPUserSessionHandler.h
//  candpiosapp
//
//  Created by Stephen Birarda on 8/9/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CPUserSessionHandler : NSObject

@property (nonatomic, weak) UIViewController *signUpPresentingViewController;

+ (void)performAfterLoginActions;
+ (void)performAppVersionCheck;
+ (void)logoutEverything;
+ (void)storeUserLoginDataFromDictionary:(NSDictionary *)userInfo;
+ (void)dismissSignupModalFromPresentingViewController;
+ (void)showSignupModalFromViewController:(UIViewController *)viewController
                                 animated:(BOOL)animated;
+ (void)syncCurrentUserWithWebAndCheckValidLogin;
+ (void)showLoginBanner;
+ (void)hideLoginBannerWithCompletion:(void (^)(void))completion;

@end
