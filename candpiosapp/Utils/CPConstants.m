//
//  CPConstants.m
//  candpiosapp
//
//  Created by Stephen Birarda on 3/9/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPConstants.h"

// Production vs. Staging variables
//#define PRODUCTION 1

@implementation CPConstants

#ifdef PRODUCTION

    NSString* const kCandPWebServiceUrl = @"https://www.coffeeandpower.com/";

    NSString* const kCandPAddFundsUrl = @"http://www.coffeeandpower.com/m/?ios#addFundsiPhone";
    NSString* const kLinkedInKey = @"";
    NSString* const kLinkedInSecret = @"";
    NSString* const flurryAnalyticsKey = @"";
    NSString* const kSmartererKey = @"";
    NSString* const kSmartererSecret = @"";
    NSString* const kTestFlightKey = @"";
    NSString* const kUserVoiceSite = @"coffeeandpower.uservoice.com";
    NSString* const kUserVoiceKey = @"";
    NSString* const kUserVoiceSecret = @"";

    #error "You're running in production mode. Are you sure you wanna do this?"

#else


    NSString* const kCandPWebServiceUrl = @"https://staging.candp.me/";
    // Devs can test against a their server sandbox by uncommenting and completing the following URL
    //NSString* const kCandPWebServiceUrl = @"http://dev.worklist.net/~<login>/candpweb2_<job#>/web/";

    NSString* const kCandPAddFundsUrl = @"http://staging.coffeeandpower.com/m/?ios#addFundsiPhone";
    NSString* const kLinkedInKey = @"4xkfzpnvuc72";
    NSString* const kLinkedInSecret = @"mxgFhH1i1PbPlWjq";
    NSString* const flurryAnalyticsKey = @"BI59BJPSZZTIFB5H87HQ";
    NSString* const kSmartererKey = @"3f883e6fc3d54834ac93c3bfe6f33553";
    NSString* const kSmartererSecret = @"ea670a5ca21c7d54d4e17972059b4f07";
    NSString* const kTestFlightKey = @"2ed46ba74d908aecc8ead4558ff3c7f5_MTA4NjQyMDEyLTAxLTAzIDIxOjA2OjE3LjcxODkwNA";
    NSString* const kUserVoiceSite = @"coffeeandpower.uservoice.com";
    NSString* const kUserVoiceKey = @"IBW0MSWGNnhVhBLi2Jlug";
    NSString* const kUserVoiceSecret = @"cWb3mvt7zsMxG1c2lldnSbSle3VGbCAVUsGi2YIbU";

    // Urban Airship
    // Configured in AirshipConfig.plist, not here anymore

#endif

NSString* const kSmartererCallback = @"candp://smarterer";
NSString* const kCandPAPIVersion = @"0.1";
NSString* const kCandPAPIErrorDomain = @"com.coffeeandpower.api.error";

int const kDefaultDismissDelay = 3;

@end
