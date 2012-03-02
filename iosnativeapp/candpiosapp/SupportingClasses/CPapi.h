//
//  CPapi.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/06.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//  
//  This is the (un)official C&P iOS API! These functions are to
//  be used to interact with the C&P web services.

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "CPPlace.h"

@interface CPapi : NSObject

@property (nonatomic, strong) AFHTTPClient *httpClient;


// Helper functions
+ (NSString *)urlEncode:(NSString *)string;
+ (NSString *)urlDecode:(NSString *)string;

// Login functions
+ (void)verifyLoginStatusWithBlock:(void(^)(void))successBlock
                     failureBlock:(void(^)(void))failureBlock;

// Chat functions
+ (void)sendOneOnOneChatMessage:(NSString *)message
                        toUser:(int)userId;

// Face-to-Face functions
+ (void)sendF2FInvite:(int) userId;
+ (void)sendF2FAccept:(int) userId;
+ (void)sendF2FDecline:(int) userId;
+ (void)sendF2FVerify:(int) userId
             password:(NSString *) password;

// Checkin functions
+ (void)getUsersCheckedInAtFoursquareID:(NSString *)foursquareID
                                       :(void(^)(NSDictionary *json, NSError *error))completion; 
+ (void)checkInToLocation:(CPPlace *)place
              checkInTime:(NSInteger)checkInTime
             checkOutTime:(NSInteger)checkOutTime
               statusText:(NSString *)stausText
          completionBlock:(void (^)(NSDictionary *, NSError *))completion;

//Profile functions
+ (void)getUserProfileWithCompletionBlock:(void(^)(NSDictionary *json, NSError *error))completion;
+ (void)getCheckInDataWithUserId:(int)userId
                   andCompletion:(void (^)(NSDictionary *, NSError *))completion;

@end
