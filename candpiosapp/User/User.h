//
//  User.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CPVenue.h"

@interface User : NSObject <NSCoding>

@property (strong, nonatomic) NSString *nickname;

@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *jobTitle;
@property (strong, nonatomic) NSString *status;
@property (strong, nonatomic) NSArray *skills;
@property (strong, nonatomic) NSString *linkedInPublicProfileUrl;
@property (strong, nonatomic) NSString *profileURLVisibility;
@property (strong, nonatomic) NSString *bio;
@property (strong, nonatomic) NSString *hourlyRate;
@property (strong, nonatomic) NSString *photoURLString;
@property (strong, nonatomic) CPVenue *placeCheckedIn;
@property (strong, nonatomic) NSDate *checkoutEpoch;
@property (strong, nonatomic) NSString *join_date;
@property (strong, nonatomic) NSArray *workInformation;
@property (strong, nonatomic) NSArray *educationInformation;
@property (strong, nonatomic) NSDictionary *reviews;
@property (strong, nonatomic) NSMutableArray *checkInHistory;
@property (strong, nonatomic) NSString *majorJobCategory;
@property (strong, nonatomic) NSString *minorJobCategory;
@property (strong, nonatomic) NSDate *joinDate;
@property (strong, nonatomic) NSMutableArray *badges;
@property (nonatomic, readonly) BOOL hasAnyTopSkills;
@property (nonatomic, readonly) BOOL hasAnyWorkInformation;
@property (nonatomic, readonly) BOOL hasAnyEducationInformation;
@property (nonatomic, readonly) BOOL hasAnyBadges;
@property (nonatomic, readonly) NSMutableArray *favoritePlaces;
@property (nonatomic, readonly) BOOL hasAnyFavoritePlaces;
@property (nonatomic) CLLocationCoordinate2D location;
@property (nonatomic) BOOL facebookVerified;
@property (nonatomic) BOOL linkedInVerified;
@property (nonatomic) double totalEarned;
@property (nonatomic) int totalHours;
@property (nonatomic) double totalSpent;
@property (nonatomic) double distance;
@property (nonatomic) BOOL checkedIn;
@property (nonatomic) int trusted_by;
@property (nonatomic) BOOL checkInIsVirtual;
@property (nonatomic) BOOL contactsOnlyChat;
@property (nonatomic) BOOL isContact;
@property (nonatomic) BOOL hasChatHistory;
@property (nonatomic) int userID;

- (void)loadUserResumeOnQueue:(NSOperationQueue *)operationQueue
                topSkillsOnly:(BOOL)topSkills
                   completion:(void (^)(NSError *error))completion;

- (void)loadUserResumeOnQueue:(NSOperationQueue *)operationQueue
                   completion:(void (^)(NSError *error))completion;

-(id)initFromDictionary:(NSDictionary *)userDict;
-(NSString *)firstName;

-(NSURL *)photoURL;

- (void)setJoinDateFromJSONString:(NSString *)dateString;
- (NSComparisonResult) compareDistanceToUser:(User *)otherUser;

@end
