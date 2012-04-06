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
#import "ChatHistory.h"
#import <CoreLocation/CoreLocation.h>

@interface CPapi : NSObject


// Helper functions
+ (NSString *)urlEncode:(NSString *)string;
+ (NSString *)urlDecode:(NSString *)string;

// Login functions
+ (void)verifyLoginStatusWithBlock:(void(^)(void))successBlock
                     failureBlock:(void(^)(void))failureBlock;

// Chat functions
+ (void)sendOneOnOneChatMessage:(NSString *)message
                        toUser:(int)userId;
+ (void)oneOnOneChatGetHistoryWith:(User *)User
                        completion:(void (^)(NSDictionary *, NSError *))completion;

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

+ (void)checkOutWithCompletion:(void(^)(NSDictionary *json, NSError *error))completion;

//Profile functions
+ (void)getResumeForUserId:(int)userId andCompletion:(void(^)(NSDictionary *json, NSError *error))completion;
+ (void)getUserProfileWithCompletionBlock:(void(^)(NSDictionary *json, NSError *error))completion;
+ (void)getUserTrasactionDataWithCompletitonBlock:(void(^)(NSDictionary *json, NSError *error))completion;
+ (void)getCheckInDataWithUserId:(int)userId
                   andCompletion:(void (^)(NSDictionary *, NSError *))completion;
+ (void)getInvitationCodeForLocation:(CLLocation *)location
                withCompletionsBlock:(void(^)(NSDictionary *json, NSError *error))completion;

//Contanct list functions
+ (void)getContactListWithCompletionsBlock:(void(^)(NSDictionary *json, NSError *error))completion;

+ (void)getVenuesInSWCoords:(CLLocationCoordinate2D)SWCoord
                andNECoords:(CLLocationCoordinate2D)NECoord
               userLocation:(CLLocation *)userLocation
              withCompletion:(void (^)(NSDictionary *, NSError *))completion;

# pragma mark - User Settings

+ (void)getNotificationSettingsWithCompletition:(void(^)(NSDictionary *json, NSError *error))completion;

+ (void)setNotificationSettingsForDistance:(NSString *)distance
                              andCheckedId:(BOOL)checkedOnly;

+ (void)setUserProfileDataWithDictionary:(NSMutableDictionary *)dataDict
                            andCompletion:(void (^)(NSDictionary *, NSError *))completion;
+ (void)uploadUserProfilePhoto:(UIImage *)image 
                withCompletion:(void (^)(NSDictionary *, NSError *))completion;

@end
