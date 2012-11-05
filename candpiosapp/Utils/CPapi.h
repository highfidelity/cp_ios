//
//  CPapi.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/06.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//  
//  This is the (un)official C&P iOS API! These functions are to
//  be used to interact with the C&P web services.

// TODO: Finish transition over to CPApiClient

#import <Foundation/Foundation.h>
#import "CPVenue.h"
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

#pragma mark - Map Dataset
+ (void)getVenuesWithCheckinsWithinSWCoordinate:(CLLocationCoordinate2D)swCoord
                      NECoordinate:(CLLocationCoordinate2D)neCoord
                      userLocation:(CLLocationCoordinate2D)userLocation
                    checkedInSince:(CGFloat)daysInterval
                            mapQueue:(NSOperationQueue *)mapQueue
             withCompletion:(void (^)(NSDictionary *, NSError *))completion;

+ (void)getNearestVenuesWithActiveFeeds:(CLLocationCoordinate2D)coordinate
                             completion:(void (^)(NSDictionary *, NSError *))completion;

+ (void)getNearestVenuesWithCheckinsToCoordinate:(CLLocationCoordinate2D)coordinate
                                        mapQueue:(NSOperationQueue *)mapQueue
                                      completion:(void (^)(NSDictionary *, NSError *))completion;

#pragma mark - Contact Request
+ (void)getNumberOfContactRequests:(void (^)(NSDictionary *json, NSError *error))completion;
+ (void)sendContactRequestToUserId:(int)userId;
+ (void)sendAcceptContactRequestFromUserId:(int)userId
                                completion:(void (^)(NSDictionary *, NSError *))completion;
+ (void)sendDeclineContactRequestFromUserId:(int)userId
                                 completion:(void (^)(NSDictionary *, NSError *))completion;

#pragma mark - Checkins
+ (void)getNearestCheckedInWithCompletion:(void (^)(NSDictionary *, NSError *))completion;

+ (void)getUsersCheckedInAtFoursquareID:(NSString *)foursquareID
                                       :(void(^)(NSDictionary *json, NSError *error))completion;

+ (void)changeHeadlineToNewHeadline:(NSString *)newHeadline
                         completion:(void (^)(NSDictionary *, NSError *))completion;

+ (void)checkOutWithCompletion:(void(^)(NSDictionary *json, NSError *error))completion;

+ (void)getCurrentCheckInsCountAtVenue:(CPVenue *)venue 
                        withCompletion:(void (^)(NSDictionary *, NSError *))completion;

+ (void)getDefaultCheckInVenueWithCompletion:(void (^)(NSDictionary *, NSError *))completion;

#pragma mark - User Profile
+ (void)getResumeForUserId:(int)userId
                     queue:(NSOperationQueue *)operationQueue
                completion:(void(^)(NSDictionary *json, NSError *error))completion;
+ (void)getUserProfileWithCompletionBlock:(void(^)(NSDictionary *json, NSError *error))completion;
+ (void)getUserTransactionDataWithCompletitonBlock:(void(^)(NSDictionary *json, NSError *error))completion;
+ (void)getCheckInDataWithUserId:(int)userId
                   andCompletion:(void (^)(NSDictionary *, NSError *))completion;

#pragma mark - Love
+ (void)sendLoveToUserWithID:(int)recieverID
                 loveMessage:(NSString *)loveMessage
                     skillID:(NSUInteger)skillID
                  completion:(void(^)(NSDictionary *json, NSError *error))completion;

+ (void)sendPlusOneForLoveWithID:(int)reviewID 
                    completion:(void(^)(NSDictionary *json, NSError *error))completion;

+ (void)sendPlusOneForLoveWithID:(int)reviewID 
     fromVenueChatForVenueWithID:(int)venueID
                 lastChatEntryID:(int)lastID
                       chatQueue:(NSOperationQueue *)chatQueue
                      completion:(void (^)(NSDictionary *, NSError *))completion;

#pragma mark - Skills
+ (void)getSkillsForUser:(NSNumber *)userID 
              completion:(void (^)(NSDictionary *, NSError *))completion;

+ (void)changeSkillStateForSkillWithId:(int)skillID
                                 visible:(BOOL)visible
                            skillQueue:(NSOperationQueue *)skillQueue
                            completion:(void (^)(NSDictionary *, NSError *))completion;

#pragma mark - Contact List
+ (void)getContactListWithCompletionsBlock:(void(^)(NSDictionary *json, NSError *error))completion;

+ (void)getVenuesInSWCoords:(CLLocationCoordinate2D)SWCoord
                andNECoords:(CLLocationCoordinate2D)NECoord
               userLocation:(CLLocation *)userLocation
              withCompletion:(void (^)(NSDictionary *, NSError *))completion;

#pragma mark - User Settings

+ (void)getNotificationSettingsWithCompletition:(void(^)(NSDictionary *json, NSError *error))completion;

+ (void)setNotificationSettingsForDistance:(NSString *)distance
                              andCheckedId:(BOOL)checkedOnly
                    receiveContactEndorsed:(BOOL)receiveContactEndorsed
                     contactHeadlineChange:(BOOL)contactHeadlineChange
                                 quietTime:(BOOL)quietTime
                             quietTimeFrom:(NSDate *)quietTimeFrom
                               quietTimeTo:(NSDate *)quietTimeTo
                   timezoneOffsetInSeconds:(NSInteger)tzOffsetSeconds
                      chatFromContactsOnly:(BOOL)chatFromContactsOnly;

+ (void)setUserProfileDataWithDictionary:(NSMutableDictionary *)dataDict
                            andCompletion:(void (^)(NSDictionary *, NSError *))completion;
+ (void)uploadUserProfilePhoto:(UIImage *)image 
                withCompletion:(void (^)(NSDictionary *, NSError *))completion;

+ (void)saveUserMajorJobCategory:(NSString *)majorJobCategory
             andMinorJobCategory:(NSString *)minorJobCategory;

+ (void)saveUserSmartererName:(NSString *)name
                                       :(void(^)(NSDictionary *json, NSError *error))completion;

+ (void)deleteAccountWithParameters:(NSMutableDictionary *)parameters
                         completion:(void(^)(NSDictionary *json, NSError *error))completion;


+ (void)saveVenueAutoCheckinStatus:(CPVenue *)venue;

+ (void)getLinkedInPostStatus:(void (^)(NSDictionary *, NSError *))completion;
+ (void)saveLinkedInPostStatus:(BOOL)status;
+ (void)addContactsByLinkedInIDs:(NSArray *)connections;

@end
