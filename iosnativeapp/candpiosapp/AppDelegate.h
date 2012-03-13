//
//  AppDelegate.h
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Settings.h"
#import "User.h"
#import "Facebook.h"
#import "UAirship.h"
#import "UAPush.h"
#import "SettingsMenuController.h"

// Constants have been moved to CPConstants.m

@class FacebookLoginSequence;
@class AFHTTPClient;
@class SignupController;

@interface AppDelegate : UIResponder <UIApplicationDelegate,
                                      FBSessionDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, readonly) Settings *settings;
@property (strong, readonly) Facebook *facebook;
@property (strong, nonatomic) SignupController *facebookLoginController;
@property (strong, nonatomic, readonly) AFHTTPClient *urbanAirshipClient;
@property (strong, nonatomic) SettingsMenuController *settingsMenuController;
@property (strong, nonatomic) UINavigationController *rootNavigationController;
           
-(void)saveSettings;
+(AppDelegate *)instance;
-(void)logoutEverything;
-(void)storeUserDataFromDictionary:(NSDictionary *)userDictionary;
-(User *)currentUser;
-(void)hideCheckInButton;
-(void)showCheckInButton;
-(void)startCheckInClockHandAnimation;
-(void)stopCheckInClockHandAnimation;
void uncaughtExceptionHandler(NSException *exception);
@end
