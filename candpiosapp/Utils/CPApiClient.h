//
//  CPApiClient.h
//  candpiosapp
//
//  Created by Stephen Birarda on 7/26/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "AFHTTPClient.h"

@interface CPApiClient : AFHTTPClient

+ (void)checkInToVenue:(CPVenue *)venue
             hoursHere:(int)hoursHere
            statusText:(NSString *)statusText
           isAutomatic:(BOOL)isAutomatic
       completionBlock:(void (^)(NSDictionary *, NSError *))completion;

+ (void)autoCheckInToVenue:(CPVenue *)venue
           completion:(void (^)(NSDictionary *, NSError *))completion;

+ (void)cancelAutoCheckInRequestWithCompletion:(void (^)(NSDictionary *, NSError *))completion;
@end
