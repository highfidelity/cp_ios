//
//  CPConstants.h
//  candpiosapp
//
//  Created by Stephen Birarda on 3/9/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// define a way to quickly grab the app delegate
#define CPAppDelegate (AppDelegate *)[UIApplication sharedApplication].delegate

@interface CPConstants : NSObject

extern NSString* const kCandPWebServiceUrl;
extern NSString* const kCandPWebServiceSecureUrl;
extern NSString* const kCandPAPIVersion;
extern NSString* const kCandPAPIErrorDomain;
extern NSString* const kLinkedInKey;
extern NSString* const kLinkedInSecret;
extern NSString* const kFoursquareClientID;
extern NSString* const kFoursquareClientSecret;
extern NSString* const flurryAnalyticsKey;
extern NSString* const kTestFlightKey;
extern NSString* const kUserVoiceSite;
extern NSString* const kUserVoiceKey;
extern NSString* const kUserVoiceSecret;
extern NSString* const kLinkedInAPIUrl;

extern int const kDefaultDismissDelay;

@end
