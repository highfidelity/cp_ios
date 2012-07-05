//
//  CPCheckinHandler.h
//  candpiosapp
//
//  Created by Stephen Birarda on 6/26/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    CPCheckinTypeDefault,
    CPCheckinTypeForced,
    CPCheckinTypeAuto
} CPCheckinType;

@interface CPCheckinHandler : NSObject

+ (void)handleSuccessfulCheckinToVenue:(CPVenue *)venue checkoutTime:(NSInteger)checkoutTime checkinType:(CPCheckinType)checkinType;
+ (void)queueLocalNotificationForVenue:(CPVenue *)venue checkoutTime:(NSInteger)checkoutTime;

@end
