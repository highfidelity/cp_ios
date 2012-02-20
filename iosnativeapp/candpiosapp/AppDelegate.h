//
//  AppDelegate.h
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Settings.h"
#import "Facebook.h"
#import "UAirship.h"
#import "UAPush.h"


////////////////////////////////////////////////
// Production vs. Staging variables
//#define PRODUCTION 1

#ifdef PRODUCTION

// ** We should probably not put production API keys in this public repo :) **
// -alexi
#define kCandPWebServiceUrl		@"https://coffeeandpower.com/"
// Facebook
#define kFacebookAppId          @"" //bind to the fb[app_id]:// URL scheme in .plist
// LinkedIn
#define kLinkedInKey            @"0"
#define kLinkedInSecret         @"0"
#define flurryAnalytics         @""
#error "You're running in production mode. Are you sure you wanna do this?"

#else

#define kCandPWebServiceUrl		@"https://staging.coffeeandpower.com/"
// Facebook
#define kFacebookAppId          @"278566002200147"
// LinkedIn
#define kLinkedInKey            @"4xkfzpnvuc72"
#define kLinkedInSecret         @"mxgFhH1i1PbPlWjq"
#define flurryAnalytics         @"BI59BJPSZZTIFB5H87HQ"
// Emcro-created LI:
//#define kLinkedInKey          @"dj7n9nz3bj65"
//#define kLinkedInSecret       @"Hnt0m2JuooWM29OW"
// Urban Airship
// Configured in AirshipConfig.plist, not here anymore

#endif


////////////////////////////////////////////////

@class FacebookLoginSequence;
@class AFHTTPClient;

@interface AppDelegate : UIResponder <UIApplicationDelegate, FBSessionDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, readonly) Settings *settings;
@property (strong, readonly) Facebook *facebook;
@property (strong, nonatomic) NSObject *loginSequence;
@property (strong, nonatomic, readonly) AFHTTPClient *urbanAirshipClient;

-(void)saveSettings;
+(AppDelegate*)instance;
-(void)logoutEverything;
-(void)hideCheckInButton;
-(void)showCheckInButton;
void uncaughtExceptionHandler(NSException *exception);
@end
