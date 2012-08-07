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
    CPAfterCheckinActionNewUpdate,
    CPAfterCheckinActionNewQuestion
} CPAfterCheckinAction;

@interface CPCheckinHandler : NSObject

@property (nonatomic, assign) CPAfterCheckinAction afterCheckinAction;
@property (strong, nonatomic) NSTimer *checkOutTimer;

- (void)presentCheckinModalFromViewController:(UIViewController *)presentingViewController;
- (void)handleSuccessfulCheckinToVenue:(CPVenue *)venue checkoutTime:(NSInteger)checkoutTime;
- (void)queueLocalNotificationForVenue:(CPVenue *)venue checkoutTime:(NSInteger)checkoutTime;
- (void)setCheckedOut;
- (void)saveCheckInVenue:(CPVenue *)venue andCheckOutTime:(NSInteger)checkOutTime;
- (void)promptForCheckout;

+ (CPCheckinHandler *)sharedHandler;

@end
