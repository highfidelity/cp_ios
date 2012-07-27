//
//  CPApiClient.h
//  candpiosapp
//
//  Created by Stephen Birarda on 7/26/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "AFHTTPClient.h"

@interface CPApiClient : AFHTTPClient


+ (void)checkInToLocation:(CPVenue *)place
                hoursHere:(int)hoursHere
               statusText:(NSString *)statusText
                isVirtual:(BOOL)isVirtual
              isAutomatic:(BOOL)isAutomatic
          completionBlock:(void (^)(NSDictionary *, NSError *))completion;

@end
