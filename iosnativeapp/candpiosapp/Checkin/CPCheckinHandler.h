//
//  CPCheckinHandler.h
//  candpiosapp
//
//  Created by Stephen Birarda on 6/26/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    CPAfterCheckinActionNone,
    CPAfterCheckinActionShowFeed,
    CPAfterCheckinActionNewPost,
    CPAfterCheckinActionNewQuestion
} CPAfterCheckinAction;

@interface CPCheckinHandler : NSObject

@property (nonatomic, assign) CPAfterCheckinAction afterCheckinAction;

- (void)presentCheckinModalFromViewController:(UIViewController *)presentingViewController;
- (void)handleSuccessfulCheckinToVenue:(CPVenue *)venue checkoutTime:(NSInteger)checkoutTime;
- (void)queueLocalNotificationForVenue:(CPVenue *)venue checkoutTime:(NSInteger)checkoutTime;

+ (CPCheckinHandler *)sharedHandler;

@end
