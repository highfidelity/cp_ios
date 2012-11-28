//
//  CPConstants.m
//  candpiosapp
//
//  Created by Stephen Birarda on 3/9/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPConstants.h"

@implementation CPConstants

#ifdef PRODUCTION

#else

    NSString* const kCandPWebServiceUrl = @"http://staging.candp.me/";
    NSString* const kCandPWebServiceSecureUrl = @"https://staging.candp.me/";
    // Devs can test against a their server sandbox by uncommenting and completing the following URL
    //NSString* const kCandPWebServiceUrl = @"http://dev.worklist.net/~<login>/candpweb2_<job#>/web/";

    NSString* const kLinkedInKey = @"hgkjgipubg8b";
    NSString* const kLinkedInSecret = @"1coFul6Ym82NJC2Z";

    NSString* const kFoursquareClientID = @"2AT1GDJZHHJ21R5ZAP0G2JN2RTMSQ012Q0C55YCTM50PGXSO";
    NSString* const kFoursquareClientSecret = @"DJOJS4CMQBQTU4RUKSTRAQESFVYZBD1XKYDUYF5PTG1OW30Z";

    NSString* const flurryAnalyticsKey = @"BI59BJPSZZTIFB5H87HQ";

    NSString* const kTestFlightKey = @"2ed46ba74d908aecc8ead4558ff3c7f5_MTA4NjQyMDEyLTAxLTAzIDIxOjA2OjE3LjcxODkwNA";

    NSString* const kUserVoiceSite = @"coffeeandpower.uservoice.com";
    NSString* const kUserVoiceKey = @"IBW0MSWGNnhVhBLi2Jlug";
    NSString* const kUserVoiceSecret = @"cWb3mvt7zsMxG1c2lldnSbSle3VGbCAVUsGi2YIbU";

#endif

NSString* const kAppPlatform = @"iOS";
NSString* const kCandPAPIErrorDomain = @"com.coffeeandpower.api.error";
NSString* const kLinkedInAPIUrl = @"https://api.linkedin.com";

int const kDefaultDismissDelay = 3;

@end
